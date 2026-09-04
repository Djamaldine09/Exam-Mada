import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../model/user.dart';
import 'register_screen.dart';
import 'otp_login_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _twoFactorToken;
  String? _twoFactorPhone;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        ApiConfig.login,
        body: {
          'email': _emailController.text.trim(),
          'motDePasse': _passwordController.text,
        },
      );

      if (response != null) {
        if (response['requiresTwoFactor'] == true) {
          setState(() {
            _twoFactorToken = response['twoFactorToken'] as String?;
            _twoFactorPhone = response['maskedTelephone'] as String?;
            _twoFactorCodeController.clear();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code 2FA envoyé par SMS')),
            );
          }
          return;
        }

        final token = response['token'] as String?;
        final user = response as Map<String, dynamic>?;

        if (token != null) {
          await StorageService.saveToken(token);
          if (user != null) {
            await StorageService.saveUser(AppUser.fromJson(user));
          }

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'),
              duration: const Duration(seconds: 5)),
        );
        print('Login error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyTwoFactor() async {
    final token2fa = _twoFactorToken;
    final code = _twoFactorCodeController.text.trim();

    if (token2fa == null || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez le code 2FA à 6 chiffres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        ApiConfig.loginTwoFactor,
        body: {
          'twoFactorToken': token2fa,
          'code': code,
        },
      );

      final token = response['token'] as String?;
      if (token == null) {
        throw Exception('Réponse 2FA invalide');
      }

      await StorageService.saveToken(token);
      await StorageService.saveUser(AppUser.fromJson(response));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur 2FA: $e'),
              duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Entrez votre email ci-dessus puis réessayez')),
      );
      return;
    }
    try {
      await ApiClient.post(ApiConfig.forgotPassword, body: {'email': email});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Si cet email existe, un lien de réinitialisation a été envoyé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleWebClientId = ApiConfig.googleWebClientId.trim();
      if (kIsWeb && googleWebClientId.isEmpty) {
        throw Exception(
          'GOOGLE_WEB_CLIENT_ID manquant. Lance Flutter avec '
          '--dart-define=GOOGLE_WEB_CLIENT_ID=198209309688-ulk5udgji1kt2kv4utrf4pq36mvdfrc2.apps.googleusercontent.com',
        );
      }

      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? googleWebClientId : null,
        scopes: const ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        // L'utilisateur a annulé la sélection de compte.
        return;
      }

      final googleAuth = await account.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) {
        throw Exception('Impossible de récupérer le jeton Google');
      }

      final response = await ApiClient.post(
        ApiConfig.googleAuth,
        body: {'token': accessToken},
      );

      final token = response['token'] as String? ?? response['jwt'] as String?;
      final userJson = response['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw Exception('Réponse de connexion Google invalide');
      }

      await StorageService.saveSession(
          token: token, user: AppUser.fromJson(userJson));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion Google : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final appId = ApiConfig.facebookAppId.trim();
      if (appId.isEmpty) {
        throw Exception(
          'FACEBOOK_APP_ID manquant. Lance Flutter avec '
          '--dart-define=FACEBOOK_APP_ID=VOTRE_APP_ID',
        );
      }

      final loginResult = await FacebookAuth.instance.login(
        permissions: const ['public_profile', 'email'],
      );

      if (loginResult.status == LoginStatus.cancelled) {
        return;
      }

      if (loginResult.status == LoginStatus.failed || loginResult.accessToken == null) {
        throw Exception('Connexion Facebook refusée ou impossible');
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: 'id,name,email,first_name,last_name',
      );

      final accessTokenValue = loginResult.accessToken?.tokenString ??
          loginResult.accessToken?.toJson()['tokenString'] ??
          loginResult.accessToken?.toJson()['token'] ??
          loginResult.accessToken?.toString() ??
          '';

      if (accessTokenValue.isEmpty) {
        throw Exception('Jeton Facebook introuvable');
      }

      final response = await ApiClient.post(
        ApiConfig.facebookAuth,
        body: {'token': accessTokenValue},
      );

      final token = response['token'] as String? ?? response['jwt'] as String?;
      final userJson = response['user'] as Map<String, dynamic>? ?? userData;

      if (token == null || userJson == null) {
        throw Exception('Réponse de connexion Facebook invalide');
      }

      await StorageService.saveSession(
          token: token, user: AppUser.fromJson(userJson));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion Facebook : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToOtpLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Image.asset(
                              'asset/images/logo-icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.tagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 300),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                ),
                if (_twoFactorToken != null) ...[
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 350),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        _twoFactorPhone == null
                            ? 'Code 2FA envoyé à votre numéro enregistré.'
                            : 'Code 2FA envoyé au numéro $_twoFactorPhone.',
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: _twoFactorCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Code 2FA',
                        counterText: '',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _twoFactorToken = null;
                              _twoFactorPhone = null;
                              _twoFactorCodeController.clear();
                            });
                          },
                    child: const Text('Modifier email ou mot de passe'),
                  ),
                ],
                const SizedBox(height: 24),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_twoFactorToken == null ? _login : _verifyTwoFactor),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_twoFactorToken == null
                            ? 'Se connecter'
                            : 'Valider le code 2FA'),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ou continuer avec',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 600),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'asset/images/google_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 620),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithFacebook,
                    icon: SizedBox(
                      width: 22,
                      height: 22,
                      child: Image.asset(
                        'asset/images/facebook-logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    label: const Text('Facebook'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1877F2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 650),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _goToOtpLogin,
                    label: const Text('Se connecter par téléphone'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 500),
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous n'avez pas de compte ? "),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorCodeController.dispose();
    super.dispose();
  }
}
