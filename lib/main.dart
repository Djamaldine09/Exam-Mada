import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamGest MG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  static const String _onboardingKey = 'has_seen_onboarding';

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final token = await StorageService.getToken();
      final preferences = await SharedPreferences.getInstance();

      final hasSeenOnboarding =
          preferences.getBool(_onboardingKey) ?? false;

      if (!mounted) return;

      setState(() {
        _isAuthenticated = token != null && token.trim().isNotEmpty;
        _hasSeenOnboarding = hasSeenOnboarding;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur pendant l’initialisation : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isAuthenticated = false;
        _hasSeenOnboarding = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        _onboardingKey,
        true,
      );

      if (!mounted) return;

      setState(() {
        _hasSeenOnboarding = true;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Erreur lors de l’enregistrement de l’onboarding : $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      /*
       * Même si l’enregistrement échoue, on permet à l’utilisateur
       * d’accéder à la connexion pour ne pas bloquer l’application.
       */
      if (!mounted) return;

      setState(() {
        _hasSeenOnboarding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingScreen();
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        onFinished: _finishOnboarding,
      );
    }

    return const LoginScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E4478),
        ),
      ),
    );
  }
}