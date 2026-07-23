import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../model/candidat.dart';
import '../../model/user.dart';
import '../documents/documents_screen.dart';
import '../inscription/inscription_screen.dart';
import '../convocation/convocation_screen.dart';
import '../paiement/paiement_screen.dart';
import '../resultats/resultats_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  Candidat? _candidatData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getUser();
      setState(() => _currentUser = user);
      
      try {
        final response = await ApiClient.get(ApiConfig.candidatMe);
        final data = response is Map<String, dynamic>
            ? (response['data'] as Map<String, dynamic>? ?? response)
            : null;
        if (data != null) {
          setState(() => _candidatData = Candidat.fromJson(data));
        }
      } catch (e) {
        print('No candidate profile found: $e');
        setState(() => _candidatData = null);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clear();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_currentUser != null)
              Text(
                'Candidat',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildPlanningTab();
      case 2:
        return _buildDocumentsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec salutation personnalisée
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // Bannière si le dossier n'est pas encore soumis
            if (_candidatData == null || _candidatData!.statutInscription == 'BROUILLON')
              _buildIncompleteProfileBanner(),
            if (_candidatData == null || _candidatData!.statutInscription == 'BROUILLON')
              const SizedBox(height: 20),

            // Accès rapides
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),

            // Statut d'inscription principal
            if (_candidatData != null) ...[
              Text(
                'État d\'avancement',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildProgressOverview(),
              const SizedBox(height: 24),
            ],
            
            // Grille de statuts
            if (_candidatData != null) ...[
              Text(
                'Vérification requise',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusGrid(),
              const SizedBox(height: 24),
            ],
            
            // Centre d'examen
            if (_candidatData != null)
              _buildExamCentreSection(),
            
            // Sections dynamiques
            if (_candidatData != null) ...[
              const SizedBox(height: 24),
              _buildNextExamsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColor = isDark ? Colors.blue[700] : Colors.blue[600];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor ?? Colors.blue,
            (isDark ? Colors.blue[900] : Colors.blue[400]) ?? Colors.lightBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (gradientColor ?? Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, ${_currentUser?.displayName?.split(' ').first ?? 'Candidat'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Statut: ${_candidatData?.statutInscription ?? 'En cours'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_late_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complétez votre dossier de candidature pour continuer.',
              style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => InscriptionScreen(candidat: _candidatData)))
                  .then((_) => _loadData());
            },
            child: const Text('Compléter'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.qr_code_2_outlined,
        label: 'Convocation',
        color: Colors.indigo,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConvocationScreen())),
      ),
      _QuickAction(
        icon: Icons.payment_outlined,
        label: 'Paiement',
        color: Colors.teal,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => PaiementScreen(candidat: _candidatData)))
            .then((_) => _loadData()),
      ),
      _QuickAction(
        icon: Icons.emoji_events_outlined,
        label: 'Résultats',
        color: Colors.amber,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultatsScreen())),
      ),
      _QuickAction(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        color: Colors.pink,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: actions.map((a) {
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: a.color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(a.icon, color: a.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                a.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressOverview() {
    final candidat = _candidatData!;
    final totalSteps = 4;
    int completedSteps = 0;
    
    if (candidat.estValide) completedSteps++;
    if (candidat.estPaye) completedSteps++;
    if (candidat.piecesJustificatives.nombreFournies >= 4) completedSteps++;
    if (candidat.centreAffecte?.isDefini ?? false) completedSteps++;
    
    final progress = completedSteps / totalSteps;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression globale',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedSteps de $totalSteps étapes complétées',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.75) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusGrid() {
    final candidat = _candidatData!;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatusCard(
          icon: Icons.verified_user,
          label: 'Validation',
          value: candidat.estValide ? 'Validé' : 'Attente',
          isComplete: candidat.estValide,
          color: candidat.estValide ? Colors.green : Colors.orange,
        ),
        _buildStatusCard(
          icon: Icons.payment,
          label: 'Paiement',
          value: candidat.estPaye ? 'Payé' : 'Non payé',
          isComplete: candidat.estPaye,
          color: candidat.estPaye ? Colors.green : Colors.red,
        ),
        _buildStatusCard(
          icon: Icons.description,
          label: 'Pièces justificatives',
          value: '${candidat.piecesJustificatives.nombreFournies}/4',
          isComplete: candidat.piecesJustificatives.nombreFournies >= 4,
          color: candidat.piecesJustificatives.nombreFournies >= 4 ? Colors.green : Colors.orange,
        ),
        _buildStatusCard(
          icon: Icons.location_on,
          label: 'Centre d\'examen',
          value: (candidat.centreAffecte?.isDefini ?? false) ? 'Affecté' : 'En attente',
          isComplete: candidat.centreAffecte?.isDefini ?? false,
          color: (candidat.centreAffecte?.isDefini ?? false) ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isComplete,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCentreSection() {
    final centre = _candidatData?.centreAffecte;
    
    if (centre == null || !centre.isDefini) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun centre affecté pour le moment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Complétez votre dossier pour obtenir votre affectation',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Centre d\'examen',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Établissement', centre.nom ?? 'Non défini'),
          const SizedBox(height: 12),
          if (centre.ville != null)
            _buildDetailRow('Ville', centre.ville!),
          if (centre.adresse != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Adresse', centre.adresse!),
          ],
          if (centre.salle != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Salle', centre.salle!),
          ],
          if (centre.numeroPlace != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Numéro de place', centre.numeroPlace!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextExamsSection() {
    final planning = _candidatData?.planning ?? [];
    if (planning.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochain examen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (planning.isNotEmpty)
          _buildExamCard(planning.first)
        else
          const Text('Aucun examen programmé'),
      ],
    );
  }

  Widget _buildExamCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.matiere,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExamDetailRow('📅 Date', item.date.toString().split(' ')[0]),
          const SizedBox(height: 8),
          _buildExamDetailRow('🕐 Heure', '${item.heureDebut} - ${item.heureFin}'),
          const SizedBox(height: 8),
          _buildExamDetailRow('⏱️ Durée', '${item.duree}h'),
          const SizedBox(height: 8),
          _buildExamDetailRow('📊 Coefficient', '${item.coefficient}'),
        ],
      ),
    );
  }

  Widget _buildExamDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildPlanningTab() {
    final planning = _candidatData?.planning ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (planning.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun planning disponible',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre planning apparaîtra ici une fois défini',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planning.length,
      itemBuilder: (context, index) {
        final item = planning[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.book,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.matiere,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Épreuve',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPlanningChip('📅', item.date.toString().split(' ')[0]),
                    _buildPlanningChip('🕐', '${item.heureDebut} - ${item.heureFin}'),
                    _buildPlanningChip('⏱️', '${item.duree}h'),
                    _buildPlanningChip('📊', 'Coef. ${item.coefficient}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanningChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return const DocumentsScreen();
  }

  Widget _buildProfileTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations utilisateur
          if (_currentUser != null) ...[
            Text(
              'Informations personnelles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileCardSection([
              _buildProfileField('👤', 'Nom', _currentUser!.nom),
              if (_currentUser!.prenom != null)
                _buildProfileField('👤', 'Prénom', _currentUser!.prenom!),
              _buildProfileField('📧', 'Email', _currentUser!.email),
              if (_currentUser!.telephone != null)
                _buildProfileField('📱', 'Téléphone', _currentUser!.telephone!),
            ]),
            const SizedBox(height: 24),
          ],
          
          // Informations candidat
          if (_candidatData != null) ...[
            Text(
              'Informations d\'inscription',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileCardSection([
              if (_candidatData!.numeroMatricule != null)
                _buildProfileField('🎓', 'Matricule', _candidatData!.numeroMatricule!),
              if (_candidatData!.cin != null)
                _buildProfileField('🆔', 'CIN', _candidatData!.cin!),
              _buildProfileField('📚', 'Examen', _candidatData!.examen),
              _buildProfileField('🎯', 'Série/Filière', _candidatData!.serieFiliere),
              _buildProfileField('📋', 'Statut', _candidatData!.statutInscription),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => InscriptionScreen(candidat: _candidatData)))
                    .then((_) => _loadData());
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier mon dossier'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCardSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: Colors.grey.withOpacity(0.2),
                    height: 1,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}