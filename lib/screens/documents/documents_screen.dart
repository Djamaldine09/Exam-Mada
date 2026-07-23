import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import '../../../services/api_client.dart';
import '../../../services/storage_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
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
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  String? _errorMessage;
  
  // File paths for uploaded documents
  Map<String, File?> _selectedFiles = {
    'photoIdentite': null,
    'acteNaissance': null,
    'diplomePrecedent': null,
    'photoSupp': null,
  };

  // Upload status from backend
  Map<String, dynamic> _documentsStatus = {};

  // Document types definition
  final List<DocumentType> _documentTypes = [
    DocumentType(
      key: 'photoIdentite',
      label: 'Photo d\'identité',
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
      key: 'diplomePrecedent',
      label: 'Diplôme précédent',
      description: 'Diplôme ou relevé de notes (JPEG, PNG, PDF)',
      isRequired: false,  // CHANGÉ: Optionnel pour examen national
    ),
    DocumentType(
      key: 'photoSupp',
      label: 'Photo supplémentaire',
      description: 'Photo d\'identité récente (JPEG, PNG)',
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDocumentsStatus();
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
    // Vérifier que tous les documents obligatoires sont sélectionnés
    List<String> missingRequired = [];
    for (var docType in _documentTypes) {
      if (docType.isRequired && _selectedFiles[docType.key] == null) {
        missingRequired.add(docType.label);
      }
    }

    if (missingRequired.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documents manquants: ${missingRequired.join(", ")}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Préparer la requête multipart avec tous les fichiers
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.inscriptionDocuments));
      
      // Ajouter le token d'authentification
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Ajouter tous les fichiers sélectionnés
      for (var entry in _selectedFiles.entries) {
        if (entry.value != null) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value!.path),
          );
        }
      }

      // Envoyer la requête
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      // Vérifier la réponse
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents téléchargés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Réinitialiser les fichiers sélectionnés
        setState(() {
          _selectedFiles = {
            'photoIdentite': null,
            'acteNaissance': null,
            'diplomePrecedent': null,
            'photoSupp': null,
          };
        });

        // Recharger le statut
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

  Widget _buildDocumentStatus(String key, String label, bool isRequired) {
    final isValid = _isDocumentValid(key);
    final selectedFile = _selectedFiles[key];

    if (isValid && selectedFile == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Téléchargé ✓',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container();
  }

  Widget _buildDocumentPicker(DocumentType docType) {
    final selectedFile = _selectedFiles[docType.key];
    final isValid = _isDocumentValid(docType.key);

    // Si le document est déjà valide et aucun nouveau n'est sélectionné, ne pas afficher
    if (isValid && selectedFile == null) {
      return _buildDocumentStatus(docType.key, docType.label, docType.isRequired);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                  color: selectedFile != null ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            docType.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (!docType.isRequired)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '(Optionnel)',
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        docType.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, 
                      size: 20,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFile.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeFile(docType.key),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(docType.key),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Caméra'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickFile(docType.key),
                      icon: const Icon(Icons.folder, size: 18),
                      label: const Text('Fichier'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pièces justificatives'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Compter les documents validés et manquants
    int validDocuments = 0;
    int requiredDocuments = 0;

    for (var docType in _documentTypes) {
      if (docType.isRequired) {
        requiredDocuments++;
        if (_isDocumentValid(docType.key)) {
          validDocuments++;
        }
      }
    }

    double completionPercentage = requiredDocuments > 0 
      ? (validDocuments / requiredDocuments) * 100 
      : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pièces justificatives'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complétez votre dossier pour confirmer votre inscription',
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completionPercentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.blue[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionPercentage == 100 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${validDocuments}/$requiredDocuments documents obligatoires',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Already uploaded documents
            if (validDocuments > 0) ...[
              Text(
                'Documents téléchargés',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._documentTypes
                .where((dt) => _isDocumentValid(dt.key))
                .map((dt) => _buildDocumentStatus(dt.key, dt.label, dt.isRequired))
                .toList(),
              const SizedBox(height: 24),
            ],

            // Documents to upload
            if (validDocuments < requiredDocuments || 
                _selectedFiles.values.any((f) => f != null)) ...[
              Text(
                validDocuments < requiredDocuments ? 'Documents manquants' : 'Sélectionnés',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._documentTypes.map((docType) {
                final isValid = _isDocumentValid(docType.key);
                final selectedFile = _selectedFiles[docType.key];
                
                // Afficher les documents à compléter
                if (!isValid || selectedFile != null) {
                  return _buildDocumentPicker(docType);
                }
                return const SizedBox.shrink();
              }).toList(),
            ],

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload button
            ElevatedButton(
              onPressed: (_isLoading || completionPercentage == 100 && _selectedFiles.values.every((f) => f == null))
                ? null
                : _uploadAllDocuments,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _selectedFiles.values.any((f) => f != null)
                      ? 'Télécharger ${_selectedFiles.values.where((f) => f != null).length} fichier(s)'
                      : 'Tous les documents sont complétés ✓',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
