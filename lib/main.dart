import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [AJOUT FIREBASE] : Imports nécessaires pour Firebase et FCM
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Fichier généré par la commande flutterfire configure

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme/theme.dart';

// [AJOUT FIREBASE] : Handler pour écouter les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notification reçue en arrière-plan : ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [AJOUT FIREBASE] : Initialisation de Firebase avant le reste de l'application
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // [AJOUT FIREBASE] : Enregistrement du handler d'arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    _setupFCM(); // [AJOUT FIREBASE] : Appel de la configuration des notifications
  }

  // [AJOUT FIREBASE] : Méthode pour configurer les permissions et écouter les messages
  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Demande de permissions (requis pour iOS et Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permissions de notification accordées');
      
      // 2. Récupération du token pour cet appareil
      try {
        String? token = await messaging.getToken();
        debugPrint("FCM Device Token: $token");
        // TODO: Envoyer ce token à votre backend si nécessaire pour cibler cet utilisateur
      } catch (e) {
        debugPrint("Erreur lors de la récupération du token FCM: $e");
      }

      // 3. Écoute des notifications quand l'app est ouverte (premier plan)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Message reçu au premier plan : ${message.notification?.title}");
        // Note: Sur Android, les notifications au premier plan n'affichent pas de popup par défaut.
        // Il faut utiliser flutter_local_notifications si vous voulez forcer l'affichage.
      });

      // 4. Action au clic sur la notification (quand l'app est en arrière-plan)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("L'utilisateur a cliqué sur la notification !");
        // Vous pouvez naviguer vers un écran spécifique ici selon les données du message
      });
    }
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