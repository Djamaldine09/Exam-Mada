import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../model/user.dart';

/// Écran de connexion par numéro de téléphone : envoi d'un code OTP par SMS
/// puis vérification du code pour obtenir une session (comme /auth/login).
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entrez votre numéro de téléphone')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.post(ApiConfig.otpLoginSend, body: {'telephone': phone});
      if (mounted) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un code de connexion vous a été envoyé par SMS')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entrez le code à 6 chiffres reçu par SMS')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post(
        ApiConfig.otpLoginVerify,
        body: {'telephone': phone, 'code': code},
      );

      final token = response['token'] as String?;
      if (token == null) {
        throw Exception('Réponse de connexion invalide');
      }

      await StorageService.saveSession(
        token: token,
        user: AppUser.fromJson(response as Map<String, dynamic>),
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion par téléphone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.sms_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _codeSent
                    ? 'Entrez le code reçu par SMS'
                    : 'Entrez votre numéro de téléphone pour recevoir un code de connexion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                enabled: !_codeSent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Code à 6 chiffres',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_codeSent ? 'Vérifier et se connecter' : 'Recevoir le code'),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _codeController.clear();
                          }),
                  child: const Text('Changer de numéro'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
