import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../model/user.dart';
import '../home/home_screen.dart';

/// Écran d'inscription complète d'un candidat : crée le compte utilisateur
/// ET le dossier candidat en un seul appel (`POST /api/inscription/candidat`).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _step = 0;

  // Étape 1 : compte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  // Étape 2 : état civil
  DateTime? _dateNaissance;
  final _lieuNaissanceController = TextEditingController();
  String _genre = 'M';
  final _cinController = TextEditingController();
  String? _region;

  // Étape 3 : scolarité
  final _examenController = TextEditingController();
  final _serieFiliereController = TextEditingController();
  final _etablissementController = TextEditingController();
  final _adresseController = TextEditingController();
  final _emailParentController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lieuNaissanceController.dispose();
    _cinController.dispose();
    _examenController.dispose();
    _serieFiliereController.dispose();
    _etablissementController.dispose();
    _adresseController.dispose();
    _emailParentController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    setState(() => _errorMessage = null);
    if (step == 0) {
      if (_nomController.text.trim().isEmpty || _prenomController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Nom et prénom sont obligatoires');
        return false;
      }
      if (!_emailController.text.contains('@')) {
        setState(() => _errorMessage = 'Email invalide');
        return false;
      }
      final pwd = _passwordController.text;
      final strongPwd = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');
      if (!strongPwd.hasMatch(pwd)) {
        setState(() => _errorMessage =
            'Mot de passe : 8 caractères min. avec majuscule, minuscule, chiffre et caractère spécial');
        return false;
      }
      if (pwd != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (_dateNaissance == null) {
        setState(() => _errorMessage = 'Sélectionnez votre date de naissance');
        return false;
      }
      if (_lieuNaissanceController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Lieu de naissance obligatoire');
        return false;
      }
      if (_region == null) {
        setState(() => _errorMessage = 'Sélectionnez votre région');
        return false;
      }
      return true;
    }
    if (step == 2) {
      if (_examenController.text.trim().isEmpty || _serieFiliereController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Examen et série/filière obligatoires');
        return false;
      }
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _submit() async {
    if (!_validateStep(2)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.post(
        ApiConfig.inscriptionCandidat,
        body: {
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'email': _emailController.text.trim(),
          'motDePasse': _passwordController.text,
          'telephone': _telephoneController.text.trim(),
          'dateNaissance': _dateNaissance!.toIso8601String().split('T').first,
          'lieuNaissance': _lieuNaissanceController.text.trim(),
          'genre': _genre,
          'cin': _cinController.text.trim().isEmpty ? null : _cinController.text.trim(),
          'examen': _examenController.text.trim(),
          'serieFiliere': _serieFiliereController.text.trim(),
          'etablissementPrecedent': _etablissementController.text.trim().isEmpty
              ? null
              : _etablissementController.text.trim(),
          'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          'emailParent':
              _emailParentController.text.trim().isEmpty ? null : _emailParentController.text.trim(),
          'region': _region,
        },
      );

      final data = response is Map<String, dynamic> ? response['data'] as Map<String, dynamic>? : null;
      final token = data?['token'] as String?;
      final userJson = data?['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw Exception('Réponse serveur invalide');
      }

      final user = AppUser.fromJson(userJson).let((u) => AppUser(
            id: u.id,
            nom: u.nom,
            prenom: u.prenom,
            email: u.email,
            role: u.role,
            telephone: u.telephone,
            token: token,
          ));

      await StorageService.saveSession(token: token, user: user);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAccountStep(),
                    _buildEtatCivilStep(),
                    _buildScolariteStep(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Retour'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_step == 2 ? "S'inscrire" : 'Suivant'),
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

  Widget _buildStepIndicator() {
    const labels = ['Compte', 'État civil', 'Scolarité'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                    )),
                if (index < 2) Expanded(child: Container(height: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 6))),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAccountStep() {
    return FadeIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '8 caractères min., 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration:
                  const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outlined)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtatCivilStep() {
    return FadeIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              decoration: const InputDecoration(labelText: 'CIN (optionnel)', prefixIcon: Icon(Icons.badge_outlined)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildScolariteStep() {
    return FadeIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _examenController,
              decoration: const InputDecoration(
                labelText: 'Examen (ex: Baccalauréat, BEPC)',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serieFiliereController,
              decoration: const InputDecoration(
                labelText: 'Série / Filière',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _etablissementController,
              decoration: const InputDecoration(
                labelText: 'Établissement précédent (optionnel)',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse (optionnel)', prefixIcon: Icon(Icons.home_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailParentController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email du parent (optionnel)',
                prefixIcon: Icon(Icons.family_restroom_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}