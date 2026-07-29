/// Configuration centrale de l'application.
///
/// IMPORTANT : adapte [ApiConfig.baseUrl] selon ton environnement :
/// - Émulateur Android -> http://10.0.2.2:5000
/// - Simulateur iOS / navigateur -> http://localhost:5000
/// - Appareil physique -> http://<IP_DE_TON_ORDINATEUR>:5000
/// - Backend déployé -> https://ton-domaine.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.74.204.53:5000',
  );

  static const String apiPrefix = '$baseUrl/api';

  // Endpoints
  static const String register = '$apiPrefix/auth/register';
  static const String login = '$apiPrefix/auth/login';
  static const String loginTwoFactor = '$apiPrefix/auth/login/2fa';
  static const String loginPhone = '$apiPrefix/auth/phone';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';
  static const String googleAuth = '$apiPrefix/auth/google';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String otpLoginSend = '$apiPrefix/auth/sms/login/send';
  static const String otpLoginVerify = '$apiPrefix/auth/sms/login/verify';

  static const String inscriptionCandidat = '$apiPrefix/inscription/candidat';
  static const String inscriptionCreate = '$apiPrefix/inscription/create';
  static const String inscriptionProfile = '$apiPrefix/inscription/profile';
  static const String inscriptionSubmit = '$apiPrefix/inscription/submit';
  static const String inscriptionDocuments = '$apiPrefix/inscription/documents';

  static const String candidatMe = '$apiPrefix/candidats/me';
  static const String candidatConvocation = '$apiPrefix/candidats/me/convocation';
  static const String candidatPlanning = '$apiPrefix/candidats/me/planning';
  static const String candidatDocuments = '$apiPrefix/candidats/me/documents';

  static const String examens = '$apiPrefix/examens';

  static const String paiementInitier = '$apiPrefix/paiement/initier';
  static const String paiementHistory = '$apiPrefix/paiement/history';
  static String paiementStatus(String transactionId) =>
      '$apiPrefix/paiement/$transactionId/status';

  static const String stripeCheckoutSession = '$apiPrefix/stripe/checkout-session';
  static const String stripeHistory = '$apiPrefix/stripe/history';
  static String stripeStatus(String paiementId) => '$apiPrefix/stripe/paiement/$paiementId';

  static const String monResultat = '$apiPrefix/resultats/mon-resultat';

  static const String releveNotesPdf = '$apiPrefix/documents/releve-notes';
  static const String convocationPdf = '$apiPrefix/documents/convocation';
  static const String bulletinVersementPdf = '$apiPrefix/documents/bulletin-versement';
  static const String piecesStatus = '$apiPrefix/documents/pieces/status';
  static String justificatif(String type) => '$apiPrefix/documents/justificatif/$type';

  static const String notifications = '$apiPrefix/notifications';
  static String notificationRead(String id) => '$apiPrefix/notifications/$id/read';
}

class AppConstants {
  static const String appName = 'Exam Mada';
  static const String tagline = 'Votre examen, simplifié.';

  static const List<String> genres = ['M', 'F'];

  static const List<String> modesPaiement = [
    'MVOLA',
    'ORANGE_MONEY',
    'AIRTEL_MONEY',
    'CARTE_BANCAIRE',
  ];

  static const Map<String, String> modePaiementLabels = {
    'MVOLA': 'MVola',
    'ORANGE_MONEY': 'Orange Money',
    'AIRTEL_MONEY': 'Airtel Money',
    'CARTE_BANCAIRE': 'Carte bancaire',
    'STRIPE': 'Carte bancaire',
  };

  static const Map<String, String> typesDocuments = {
    'photoIdentite': 'Photo d\'identité',
    'acteNaissance': 'Acte de naissance',
    'diplomePrecedent': 'Diplôme précédent',
    'photoSupp': 'Photo supplémentaire',
  };

  static const secureStorageTokenKey = 'examgest_token';
  static const secureStorageUserKey = 'examgest_user';

  /// Montant par défaut des frais d'examen (Ariary).
  static const num montantExamenDefaut = 15000;

  /// Régions de Madagascar (liste officielle des 22 régions).
  static const List<String> regionsMadagascar = [
    'Alaotra-Mangoro',
    'Amoron\'i Mania',
    'Analamanga',
    'Analanjirofo',
    'Androy',
    'Anosy',
    'Atsimo-Andrefana',
    'Atsimo-Atsinanana',
    'Atsinanana',
    'Betsiboka',
    'Boeny',
    'Bongolava',
    'Diana',
    'Haute Matsiatra',
    'Ihorombe',
    'Itasy',
    'Melaky',
    'Menabe',
    'Sava',
    'Sofia',
    'Vakinankaratra',
    'Vatovavy-Fitovinany',
  ];
}
