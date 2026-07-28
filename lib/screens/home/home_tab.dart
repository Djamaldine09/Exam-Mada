import 'package:flutter/material.dart';

import '../../model/candidat.dart';
import '../../model/user.dart';
import '../convocation/convocation_screen.dart';
import '../inscription/inscription_screen.dart';
import '../notifications/notifications_screen.dart';
import '../paiement/paiement_screen.dart';
import '../resultats/resultats_screen.dart';

class HomeTab extends StatelessWidget {
  final AppUser? currentUser;
  final Candidat? candidat;
  final Future<void> Function() onRefresh;

  const HomeTab({
    super.key,
    required this.currentUser,
    required this.candidat,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WeeklyCalendar(),
            const SizedBox(height: 20),
            _WelcomeCard(currentUser: currentUser, candidat: candidat),
            const SizedBox(height: 20),
            if (candidat == null || candidat!.statutInscription == 'BROUILLON') ...[
              _IncompleteProfileBanner(candidat: candidat, onRefresh: onRefresh),
              const SizedBox(height: 20),
            ],
            _QuickActionsGrid(candidat: candidat, onRefresh: onRefresh),
            const SizedBox(height: 24),
            if (candidat != null) ...[
              Text(
                'État d\'avancement',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
              ),
              const SizedBox(height: 12),
              _ProgressOverview(candidat: candidat!),
              const SizedBox(height: 24),
              Text(
                'Vérification requise',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _StatusGrid(candidat: candidat!),
              const SizedBox(height: 24),
              _ExamCentreSection(candidat: candidat!),
              const SizedBox(height: 24),
              _NextExamsSection(candidat: candidat!),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar();

  @override
  Widget build(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dates = [22, 23, 24, 25, 26, 27, 28];
    const selectedIndex = 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(days.length, (index) {
          final isSelected = index == selectedIndex;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[800] : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dates[index].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final AppUser? currentUser;
  final Candidat? candidat;

  const _WelcomeCard({required this.currentUser, required this.candidat});

  @override
  Widget build(BuildContext context) {
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
            'Bonjour, ${currentUser?.displayName.split(' ').first ?? 'Candidat'}!',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Statut: ${candidat?.statutInscription ?? 'En cours'}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncompleteProfileBanner extends StatelessWidget {
  final Candidat? candidat;
  final Future<void> Function() onRefresh;

  const _IncompleteProfileBanner({required this.candidat, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
                  .push(MaterialPageRoute(builder: (_) => InscriptionScreen(candidat: candidat)))
                  .then((_) => onRefresh());
            },
            child: const Text('Compléter'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final Candidat? candidat;
  final Future<void> Function() onRefresh;

  const _QuickActionsGrid({required this.candidat, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
            .push(MaterialPageRoute(builder: (_) => PaiementScreen(candidat: candidat)))
            .then((_) => onRefresh()),
      ),
      _QuickAction(
        icon: Icons.workspace_premium_outlined,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions.map((action) {
        return Expanded(
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: action.color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(action.icon, color: action.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final Candidat candidat;

  const _ProgressOverview({required this.candidat});

  Color _getProgressColor(double progress) {
    if (progress >= 0.75) return Colors.green;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 4;
    var completedSteps = 0;
    if (candidat.estValide) completedSteps++;
    if (candidat.estPaye) completedSteps++;
    if (candidat.piecesJustificatives.nombreFournies >= 3) completedSteps++;
    if (candidat.centreAffecte?.isDefini ?? false) completedSteps++;
    final progress = completedSteps / totalSteps;
    final progressColor = _getProgressColor(progress);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression globale', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: progressColor),
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
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedSteps de $totalSteps étapes complétées',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final Candidat candidat;

  const _StatusGrid({required this.candidat});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _StatusCard(
          icon: Icons.assignment_turned_in_outlined,
          label: 'Inscription',
          value: candidat.estValide ? 'Validée' : 'En attente',
          isComplete: candidat.estValide,
          color: candidat.estValide ? Colors.green : Colors.orange,
        ),
        _StatusCard(
          icon: Icons.payment_outlined,
          label: 'Paiement',
          value: candidat.estPaye ? 'Payé' : 'Non payé',
          isComplete: candidat.estPaye,
          color: candidat.estPaye ? Colors.green : Colors.red,
        ),
        _StatusCard(
          icon: Icons.folder_copy_outlined,
          label: 'Documents',
          value: '${candidat.piecesJustificatives.nombreFournies}/3',
          isComplete: candidat.piecesJustificatives.nombreFournies >= 3,
          color: candidat.piecesJustificatives.nombreFournies >= 3 ? Colors.green : Colors.orange,
        ),
        _StatusCard(
          icon: Icons.location_on_outlined,
          label: 'Centre',
          value: (candidat.centreAffecte?.isDefini ?? false) ? 'Affecté' : 'En attente',
          isComplete: candidat.centreAffecte?.isDefini ?? false,
          color: (candidat.centreAffecte?.isDefini ?? false) ? Colors.green : Colors.grey,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isComplete;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isComplete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ExamCentreSection extends StatelessWidget {
  final Candidat candidat;

  const _ExamCentreSection({required this.candidat});

  @override
  Widget build(BuildContext context) {
    final centre = candidat.centreAffecte;

    if (centre == null || !centre.isDefini) {
      return _InfoBox(
        icon: Icons.info_outline,
        color: Colors.orange,
        title: 'Aucun centre affecté pour le moment',
        message: 'Complétez votre dossier pour obtenir votre affectation',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green),
              const SizedBox(width: 12),
              Text('Centre d\'examen', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Établissement', value: centre.nom ?? 'Non défini'),
          if (centre.ville != null) _DetailRow(label: 'Ville', value: centre.ville!),
          if (centre.adresse != null) _DetailRow(label: 'Adresse', value: centre.adresse!),
          if (centre.salle != null) _DetailRow(label: 'Salle', value: centre.salle!),
          if (centre.numeroPlace != null) _DetailRow(label: 'Place', value: centre.numeroPlace!),
        ],
      ),
    );
  }
}

class _NextExamsSection extends StatelessWidget {
  final Candidat candidat;

  const _NextExamsSection({required this.candidat});

  @override
  Widget build(BuildContext context) {
    final planning = candidat.planning;
    if (planning.isEmpty) return const SizedBox.shrink();
    final item = planning.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prochain examen', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.matiere, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              _IconDetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: item.date.toString().split(' ')[0]),
              _IconDetailRow(icon: Icons.schedule_outlined, label: 'Heure', value: '${item.heureDebut} - ${item.heureFin}'),
              _IconDetailRow(icon: Icons.timer_outlined, label: 'Durée', value: '${item.duree}h'),
              _IconDetailRow(icon: Icons.bar_chart_outlined, label: 'Coefficient', value: '${item.coefficient}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IconDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
            ],
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _InfoBox({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(message, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
