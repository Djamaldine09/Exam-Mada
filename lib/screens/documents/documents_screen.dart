import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../constants.dart';
import '../../../model/candidat.dart';
import '../../../model/examen.dart';
import '../../../services/api_client.dart';
import '../../../services/storage_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

enum DossierSection {
  identite,
  scolarite,
  coordonnees,
  pieces,
}

class DocumentType {
  final String key;
  final String label;
  final String description;
  final bool isRequired;

  DocumentType({
    required this.key,
    required this.label,
    required this.description,
    this.isRequired = true,
  });
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final _lieuNaissanceController = TextEditingController();
  final _cinController = TextEditingController();
  final _examenController = TextEditingController();
  final _serieFiliereController = TextEditingController();
  final _etablissementController = TextEditingController();
  final _mentionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailParentController = TextEditingController();

  DateTime? _dateNaissance;
  String _genre = 'M';
  String? _region;
  Candidat? _candidat;
  List<Examen> _examens = [];
  DossierSection _activeSection = DossierSection.identite;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _isCheckingStatus = true;
  String? _errorMessage;

  Map<String, File?> _selectedFiles = {
    'photoIdentite': null,
    'acteNaissance': null,
    'photoSupp': null,
  };

  Map<String, dynamic> _documentsStatus = {};

  final List<DocumentType> _documentTypes = [
    DocumentType(
      key: 'photoIdentite',
      label: 'Pièce d\'identité',
      description: 'Carte d\'identité nationale ou passeport (JPEG, PNG)',
      isRequired: true,
    ),
    DocumentType(
      key: 'acteNaissance',
      label: 'Acte de naissance',
      description: 'Extrait d\'acte de naissance (JPEG, PNG, PDF)',
      isRequired: true,
    ),
    DocumentType(
      key: 'photoSupp',
      label: 'Photo d\'identité (4x4)',
      description: 'Photo d\'identité récente au format 4x4 (JPEG, PNG)',
      isRequired: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCandidateProfile();
    _loadExamens();
    _loadDocumentsStatus();
  }

  Future<void> _loadExamens() async {
    try {
      final response = await ApiClient.get(ApiConfig.examens);
      if (!mounted || response is! List) return;

      final examens = response
          .whereType<Map<String, dynamic>>()
          .map(Examen.fromJson)
          .where((examen) => examen.titre.trim().isNotEmpty)
          .toList();
      setState(() => _examens = examens);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur chargement des examens: $e');
      }
    }
  }

  @override
  void dispose() {
    _lieuNaissanceController.dispose();
    _cinController.dispose();
    _examenController.dispose();
    _serieFiliereController.dispose();
    _etablissementController.dispose();
    _mentionController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailParentController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidateProfile() async {
    try {
      final data = await ApiClient.get(ApiConfig.candidatMe);
      if (!mounted || data is! Map<String, dynamic>) return;

      final candidat = Candidat.fromJson(data);
      setState(() {
        _candidat = candidat;
        _dateNaissance = candidat.dateNaissance;
        _lieuNaissanceController.text = candidat.lieuNaissance ?? '';
        _genre = candidat.genre ?? 'M';
        _cinController.text = candidat.cin ?? '';
        _region = candidat.region;
        _examenController.text = candidat.examen;
        _serieFiliereController.text = candidat.serieFiliere;
        _etablissementController.text = candidat.etablissementPrecedent ?? '';
        _mentionController.text = candidat.mentionPrecedente ?? '';
        _adresseController.text = candidat.adresse ?? '';
        _telephoneController.text = candidat.telephone ?? '';
        _emailParentController.text = candidat.emailParent ?? '';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur chargement du dossier: $e';
        });
      }
    }
  }

  Future<void> _loadDocumentsStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final status = await ApiClient.get(ApiConfig.piecesStatus);
      setState(() {
        _documentsStatus = status ?? {};
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du statut: $e';
        _isCheckingStatus = false;
      });
    }
  }

  Map<String, dynamic> _buildBody() {
    return {
      if (_dateNaissance != null)
        'dateNaissance': _dateNaissance!.toIso8601String().split('T').first,
      if (_lieuNaissanceController.text.trim().isNotEmpty)
        'lieuNaissance': _lieuNaissanceController.text.trim(),
      'genre': _genre,
      if (_cinController.text.trim().isNotEmpty)
        'cin': _cinController.text.trim(),
      if (_region != null && _region!.isNotEmpty) 'region': _region,
      if (_examenController.text.trim().isNotEmpty)
        'examen': _examenController.text.trim(),
      if (_serieFiliereController.text.trim().isNotEmpty)
        'serieFiliere': _serieFiliereController.text.trim(),
      if (_etablissementController.text.trim().isNotEmpty)
        'etablissementPrecedent': _etablissementController.text.trim(),
      if (_mentionController.text.trim().isNotEmpty)
        'mentionPrecedente': _mentionController.text.trim(),
      if (_adresseController.text.trim().isNotEmpty)
        'adresse': _adresseController.text.trim(),
      if (_telephoneController.text.trim().isNotEmpty)
        'telephone': _telephoneController.text.trim(),
      if (_emailParentController.text.trim().isNotEmpty)
        'emailParent': _emailParentController.text.trim(),
    };
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.put(ApiConfig.inscriptionProfile, body: _buildBody());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dossier enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadCandidateProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitInscription() async {
    if (_dateNaissance == null ||
        _lieuNaissanceController.text.trim().isEmpty ||
        _cinController.text.trim().isEmpty ||
        _region == null ||
        _region!.isEmpty ||
        _examenController.text.trim().isEmpty ||
        _serieFiliereController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Complétez les champs obligatoires avant de soumettre.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiClient.put(ApiConfig.inscriptionProfile, body: _buildBody());
      await ApiClient.post(ApiConfig.inscriptionSubmit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription soumise pour validation'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadCandidateProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dateNaissance ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  double _completionPercentage() {
    final values = <bool>[
      _dateNaissance != null,
      _lieuNaissanceController.text.trim().isNotEmpty,
      _genre.isNotEmpty,
      _cinController.text.trim().isNotEmpty,
      (_region != null && _region!.isNotEmpty),
      _examenController.text.trim().isNotEmpty,
      _serieFiliereController.text.trim().isNotEmpty,
      _etablissementController.text.trim().isNotEmpty,
      _adresseController.text.trim().isNotEmpty,
      _telephoneController.text.trim().isNotEmpty,
      _isDocumentValid('photoIdentite'),
      _isDocumentValid('acteNaissance'),
      _isDocumentValid('photoSupp'),
    ];

    final completed = values.where((v) => v).length;
    return (completed / values.length) * 100;
  }

  Future<void> _pickImage(String documentKey) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFiles[documentKey] = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickFile(String documentKey) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles[documentKey] = File(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _uploadAllDocuments() async {
    List<String> missingRequired = [];
    for (final docType in _documentTypes) {
      if (docType.isRequired && _selectedFiles[docType.key] == null) {
        missingRequired.add(docType.label);
      }
    }

    if (missingRequired.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documents manquants: ${missingRequired.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(ApiConfig.inscriptionDocuments));
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (final entry in _selectedFiles.entries) {
        if (entry.value != null) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value!.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents téléchargés avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedFiles = {
            'photoIdentite': null,
            'acteNaissance': null,
            'photoSupp': null,
          };
        });

        await _loadDocumentsStatus();
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Erreur lors du téléchargement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeFile(String documentKey) {
    setState(() {
      _selectedFiles[documentKey] = null;
    });
  }

  bool _isDocumentValid(String key) {
    return _documentsStatus[key] == 'valide';
  }

  Widget _buildDocumentStatus(String key, String label) {
    final selectedFile = _selectedFiles[key];
    if (_isDocumentValid(key) && selectedFile == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label : Téléchargé',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDocumentPicker(DocumentType docType) {
    final selectedFile = _selectedFiles[docType.key];
    final isValid = _isDocumentValid(docType.key);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isValid && selectedFile == null) {
      return _buildDocumentStatus(docType.key, docType.label);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedFile != null ? Icons.check_circle : Icons.upload_file,
                color: selectedFile != null
                    ? Colors.green
                    : const Color(0xFFCDF564),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          docType.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (!docType.isRequired)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '(Optionnel)',
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      docType.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedFile != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedFile.path.split('/').last,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFile(docType.key),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(docType.key),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Caméra'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      foregroundColor: const Color(0xFF1F2A1F),
                      side: const BorderSide(color: Color(0xFFCDF564)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFile(docType.key),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Fichier'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      foregroundColor: const Color(0xFF1F2A1F),
                      side: const BorderSide(color: Color(0xFFCDF564)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCDF564), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        floatingLabelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _pickDateNaissance,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Date de naissance',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateNaissance != null
                        ? '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'
                        : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateNaissance != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCDF564), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        floatingLabelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
          fontWeight: FontWeight.w600,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
      hint: Text(
        'Sélectionner',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGenreSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genre',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF1F2A1F),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['M', 'F'].map((g) {
            final selected = _genre == g;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(g == 'M' ? 'Masculin' : 'Féminin'),
                  selected: selected,
                  onSelected: (_) => setState(() => _genre = g),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.black87
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: const Color(0xFFCDF564),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case DossierSection.identite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Identité', 'Informations personnelles'),
            _buildTextField(
              label: 'Nom',
              controller:
                  TextEditingController(text: _candidat?.user?.nom ?? ''),
              readOnly: true,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Prénom',
              controller:
                  TextEditingController(text: _candidat?.user?.prenom ?? ''),
              readOnly: true,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Lieu de naissance',
              controller: _lieuNaissanceController,
              hint: 'Antananarivo',
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 16),
            _buildGenreSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'CIN',
              controller: _cinController,
              hint: '101 000 000 000',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Région',
              value: _region,
              items: AppConstants.regionsMadagascar,
              onChanged: (v) => setState(() => _region = v),
              icon: Icons.map_outlined,
            ),
          ],
        );
      case DossierSection.scolarite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Scolarité', 'Parcours académique'),
            _buildDropdownField(
              label: 'Examen visé',
              value: _examens.any((examen) =>
                      examen.titre == _examenController.text.trim())
                  ? _examenController.text.trim()
                  : null,
              items: _examens.map((examen) => examen.titre).toList(),
              onChanged: (value) {
                _examenController.text = value ?? '';
                setState(() {});
              },
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Série / Filière',
              controller: _serieFiliereController,
              hint: 'Série C',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Établissement précédent',
              controller: _etablissementController,
              hint: 'Lycée ...',
              icon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Mention obtenue',
              controller: _mentionController,
              hint: 'Bien',
              icon: Icons.grade_outlined,
            ),
          ],
        );
      case DossierSection.coordonnees:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Coordonnées', 'Comment vous joindre'),
            _buildTextField(
              label: 'Adresse complète',
              controller: _adresseController,
              hint: 'Lot II A 32, Antananarivo',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Téléphone candidat',
              controller: _telephoneController,
              hint: '+261 34 ...',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email parent / tuteur',
              controller: _emailParentController,
              hint: 'parent@example.mg',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        );
      case DossierSection.pieces:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              'Pièces justificatives',
              'Téléversez les documents requis (PDF ou image, max 5 Mo)',
            ),
            ..._documentTypes.map((docType) => _buildDocumentPicker(docType)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadAllDocuments,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFFCDF564),
                foregroundColor: const Color(0xFF1F2A1F),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedFiles.values.any((f) => f != null)
                          ? 'Télécharger ${_selectedFiles.values.where((f) => f != null).length} fichier(s)'
                          : 'Téléverser les documents',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon dossier d\'inscription',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSectionChip('Identité', DossierSection.identite),
                      _buildSectionChip('Scolarité', DossierSection.scolarite),
                      _buildSectionChip(
                          'Coordonnées', DossierSection.coordonnees),
                      _buildSectionChip('Pièces', DossierSection.pieces),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionContent(),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              TextStyle(color: Colors.red[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1F2A1F),
                          side: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1F2A1F)),
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _isSubmitting || _completionPercentage() < 100
                          ? null
                          : _submitInscription,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFFCDF564),
                        foregroundColor: const Color(0xFF1F2A1F),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1F2A1F)),
                              ),
                            )
                          : const Text(
                              'Soumettre l\'inscription',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChip(String label, DossierSection section) {
    final selected = _activeSection == section;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _activeSection = section),
        labelStyle: TextStyle(
          color: selected
              ? const Color(0xFF1F2A1F)
                : (isDark ? Colors.white : Colors.black87),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        selectedColor: const Color(0xFFCDF564),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
