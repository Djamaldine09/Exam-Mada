import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../model/candidat.dart';

/// Permet à un candidat déjà authentifié de compléter son dossier
/// (état civil + scolarité) puis de le soumettre pour validation.
class InscriptionScreen extends StatefulWidget {
  final Candidat? candidat;

  const InscriptionScreen({super.key, this.candidat});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  DateTime? _dateNaissance;
  final _lieuNaissanceController = TextEditingController();
  String _genre = 'M';
  final _cinController = TextEditingController();
  String? _region;
  final _examenController = TextEditingController();
  final _serieFiliereController = TextEditingController();
  final _etablissementController = TextEditingController();
  final _mentionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _emailParentController = TextEditingController();

  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    final c = widget.candidat;
    if (c != null) {
      _dateNaissance = c.dateNaissance;
      _lieuNaissanceController.text = c.lieuNaissance ?? '';
      _genre = c.genre ?? 'M';
      _cinController.text = c.cin ?? '';
      _region = c.region;
      _examenController.text = c.examen;
      _serieFiliereController.text = c.serieFiliere;
      _etablissementController.text = c.etablissementPrecedent ?? '';
      _mentionController.text = c.mentionPrecedente ?? '';
      _adresseController.text = c.adresse ?? '';
      _emailParentController.text = c.emailParent ?? '';
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
    _emailParentController.dispose();
    super.dispose();
  }

  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Map<String, dynamic> _buildBody() {
    return {
      if (_dateNaissance != null) 'dateNaissance': _dateNaissance!.toIso8601String().split('T').first,
      if (_lieuNaissanceController.text.trim().isNotEmpty) 'lieuNaissance': _lieuNaissanceController.text.trim(),
      'genre': _genre,
      if (_cinController.text.trim().isNotEmpty) 'cin': _cinController.text.trim(),
      if (_region != null) 'region': _region,
      if (_examenController.text.trim().isNotEmpty) 'examen': _examenController.text.trim(),
      if (_serieFiliereController.text.trim().isNotEmpty) 'serieFiliere': _serieFiliereController.text.trim(),
      if (_etablissementController.text.trim().isNotEmpty)
        'etablissementPrecedent': _etablissementController.text.trim(),
      if (_mentionController.text.trim().isNotEmpty) 'mentionPrecedente': _mentionController.text.trim(),
      if (_adresseController.text.trim().isNotEmpty) 'adresse': _adresseController.text.trim(),
      if (_emailParentController.text.trim().isNotEmpty) 'emailParent': _emailParentController.text.trim(),
    };
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      await ApiClient.put(ApiConfig.inscriptionProfile, body: _buildBody());
      setState(() {
        _message = 'Dossier enregistré avec succès';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur : $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit() async {
    if (_dateNaissance == null ||
        _lieuNaissanceController.text.trim().isEmpty ||
        _cinController.text.trim().isEmpty ||
        _region == null) {
      setState(() {
        _message = 'Complétez date de naissance, lieu de naissance, CIN et région avant de soumettre';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      // On s'assure que le profil est bien sauvegardé avant soumission.
      await ApiClient.put(ApiConfig.inscriptionProfile, body: _buildBody());
      await ApiClient.post(ApiConfig.inscriptionSubmit);
      setState(() {
        _message = 'Inscription soumise pour validation ! Vous serez notifié(e) de la décision.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur : $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compléter mon dossier')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isError ? Colors.red : Colors.green).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? Colors.red : Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_message!,
                          style: TextStyle(color: _isError ? Colors.red : Colors.green[800], fontSize: 13)),
                    ),
                  ],
                ),
              ),
            Text('État civil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateNaissance,
              child: InputDecorator(
                decoration:
                    const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Icons.cake_outlined)),
                child: Text(
                  _dateNaissance != null
                      ? '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'
                      : 'Sélectionner',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lieuNaissanceController,
              decoration:
                  const InputDecoration(labelText: 'Lieu de naissance', prefixIcon: Icon(Icons.location_city_outlined)),
            ),
            const SizedBox(height: 16),
            Row(
              children: AppConstants.genres.map((g) {
                final selected = _genre == g;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g == 'M' ? 'Masculin' : 'Féminin'),
                      selected: selected,
                      onSelected: (_) => setState(() => _genre = g),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cinController,
              decoration: const InputDecoration(labelText: 'CIN', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _region,
              decoration: const InputDecoration(labelText: 'Région', prefixIcon: Icon(Icons.map_outlined)),
              items: AppConstants.regionsMadagascar
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _region = v),
            ),
            const SizedBox(height: 24),
            Text('Scolarité', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _examenController,
              decoration: const InputDecoration(labelText: 'Examen', prefixIcon: Icon(Icons.school_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serieFiliereController,
              decoration:
                  const InputDecoration(labelText: 'Série / Filière', prefixIcon: Icon(Icons.category_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _etablissementController,
              decoration: const InputDecoration(
                  labelText: 'Établissement précédent', prefixIcon: Icon(Icons.apartment_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mentionController,
              decoration:
                  const InputDecoration(labelText: 'Mention précédente', prefixIcon: Icon(Icons.grade_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.home_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailParentController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email du parent', prefixIcon: Icon(Icons.family_restroom_outlined)),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer le brouillon'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Soumettre pour validation'),
            ),
          ],
        ),
      ),
    );
  }
}