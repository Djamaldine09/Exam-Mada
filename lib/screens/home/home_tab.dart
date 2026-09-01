import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/candidat.dart';
import '../../model/user.dart';
import '../convocation/convocation_screen.dart';
import '../inscription/inscription_screen.dart';
import '../itineraire_screen.dart';
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
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WeeklyCalendar(),
            const SizedBox(height: 20),
            if (candidat == null ||
                candidat!.statutInscription == 'BROUILLON') ...[
              _IncompleteProfileBanner(
                  candidat: candidat, onRefresh: onRefresh),
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
              Row(
                children: [
                  Text(
                    'Vérification requise',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'À vérifier',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
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
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(
        7,
        (index) => DateFormat('E', 'fr_FR')
            .format(startOfWeek.add(Duration(days: index))));
    final dates =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)).day);
    final selectedIndex = now.weekday - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(days.length, (index) {
          final isSelected = index == selectedIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            transform: Matrix4.identity(),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [const Color(0xFFE7F76D), const Color(0xFFB9D941)]
                          : [const Color(0xFFF3FFB6), const Color(0xFFCDF564)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? const Color(0xFF13171A)
                      : const Color(0xFFF8FAFD)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.04)),
                width: 1,
              ),
              boxShadow: isSelected
                  ? []
                  : [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFFB9C7D8))
                            .withOpacity(
                          isDark ? 0.3 : 0.12,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? (isDark ? Colors.black87 : Colors.black87)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dates[index].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.w800,
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

class _IncompleteProfileBanner extends StatelessWidget {
  final Candidat? candidat;
  final Future<void> Function() onRefresh;

  const _IncompleteProfileBanner(
      {required this.candidat, required this.onRefresh});

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
              style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => InscriptionScreen(candidat: candidat)))
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
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ConvocationScreen())),
      ),
      _QuickAction(
        icon: Icons.payment_outlined,
        label: 'Paiement',
        color: Colors.teal,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => PaiementScreen(candidat: candidat)))
            .then((_) => onRefresh()),
      ),
      _QuickAction(
        icon: Icons.workspace_premium_outlined,
        label: 'Résultats',
        color: Colors.amber,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ResultatsScreen())),
      ),
      _QuickAction(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        color: Colors.pink,
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions.map((action) {
        return Expanded(
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          action.color.withOpacity(isDark ? 0.28 : 0.16),
                          action.color.withOpacity(isDark ? 0.18 : 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withOpacity(0.2),
                          blurRadius: 14,
                          spreadRadius: 0.3,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(action.icon, color: action.color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B1D22), const Color(0xFF14161A)]
              : [Colors.white, const Color(0xFFF5F8FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : const Color(0xFF96A8C3)).withOpacity(
              isDark ? 0.55 : 0.18,
            ),
            blurRadius: 22,
            spreadRadius: isDark ? 0.6 : 0.2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: progressColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Progression globale',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completedSteps de $totalSteps étapes complétées',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                progress >= 0.75
                    ? Icons.check_circle_rounded
                    : progress >= 0.4
                        ? Icons.pending_actions_rounded
                        : Icons.warning_amber_rounded,
                color: progressColor,
                size: 18,
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatusCard(
          icon: Icons.assignment_turned_in_outlined,
          label: 'Inscription',
          value: candidat.estValide ? 'Validée' : 'En attente',
          isComplete: candidat.estValide,
          color: candidat.estValide ? Colors.green : Colors.orange,
          isDark: isDark,
        ),
        _StatusCard(
          icon: Icons.payment_outlined,
          label: 'Paiement',
          value: candidat.estPaye ? 'Payé' : 'Non payé',
          isComplete: candidat.estPaye,
          color: candidat.estPaye ? Colors.green : Colors.red,
          isDark: isDark,
        ),
        _StatusCard(
          icon: Icons.folder_copy_outlined,
          label: 'Documents',
          value: '${candidat.piecesJustificatives.nombreFournies}/3',
          isComplete: candidat.piecesJustificatives.nombreFournies >= 3,
          color: candidat.piecesJustificatives.nombreFournies >= 3
              ? Colors.green
              : Colors.orange,
          isDark: isDark,
        ),
        _StatusCard(
          icon: Icons.location_on_outlined,
          label: 'Centre',
          value: (candidat.centreAffecte?.isDefini ?? false)
              ? 'Affecté'
              : 'En attente',
          isComplete: candidat.centreAffecte?.isDefini ?? false,
          color: (candidat.centreAffecte?.isDefini ?? false)
              ? Colors.green
              : Colors.grey,
          isDark: isDark,
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
  final bool isDark;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isComplete,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF191B1F) : Colors.white;
    final border = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1D2229), const Color(0xFF161A20)]
              : [Colors.white, const Color(0xFFF7F9FC)],
        ),
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : const Color(0xFF9DAFC9)).withOpacity(
              isDark ? 0.56 : 0.18,
            ),
            blurRadius: 20,
            spreadRadius: isDark ? 0.5 : 0.25,
            offset: const Offset(0, 11),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete
                      ? (isDark
                          ? Colors.green.withOpacity(0.14)
                          : Colors.green.withOpacity(0.12))
                      : (isDark
                          ? Colors.orange.withOpacity(0.14)
                          : Colors.orange.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isComplete ? 'OK' : 'À faire',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExamCentreSection extends StatelessWidget {
  final Candidat candidat;

  _ExamCentreSection({required this.candidat}); // Note: "const" retiré ici

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B1E23), const Color(0xFF14161A)]
              : [Colors.white, const Color(0xFFFAFCFE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF96A8C3))
                .withOpacity(isDark ? 0.4 : 0.14),
            blurRadius: 20,
            spreadRadius: 0.2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.withOpacity(0.22),
                      Colors.green.withOpacity(0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.green, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Centre d\'examen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                )),
                    const SizedBox(height: 2),
                    Text(centre.nom ?? 'Non défini',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (centre.ville != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PremiumDetailRow(
                  icon: Icons.map_outlined,
                  label: 'Ville',
                  value: centre.ville!,
                  isDark: isDark),
            ),
          if (centre.adresse != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PremiumDetailRow(
                  icon: Icons.apartment_outlined,
                  label: 'Adresse',
                  value: centre.adresse!,
                  isDark: isDark),
            ),
          if (centre.salle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PremiumDetailRow(
                  icon: Icons.meeting_room_outlined, // Icône modifiée ici
                  label: 'Salle',
                  value: centre.salle!,
                  isDark: isDark),
            ),
          if (centre.numeroPlace != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PremiumDetailRow(
                  icon: Icons.event_seat_outlined,
                  label: 'Place',
                  value: centre.numeroPlace!,
                  isDark: isDark),
            ),
          const SizedBox(height: 16),
          if (_hasValidCentreLocation(centre))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  elevation: 6,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ItineraireScreen(
                      centreName: centre.nom ?? 'Centre d\'examen',
                      adresse: centre.adresse,
                      ville: centre.ville,
                      latitude: centre.lat,
                      longitude: centre.lng,
                    ),
                  ));
                },
                icon: const Icon(Icons.map_outlined, size: 20),
                label: const Text('Voir la localisation',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasValidCentreLocation(CentreAffecte centre) {
    return (centre.lat != null && centre.lng != null) ||
        ((centre.adresse?.isNotEmpty ?? false) &&
            (centre.ville?.isNotEmpty ?? false));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prochain examen',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                )),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1B1E23), const Color(0xFF14161A)]
                  : [Colors.white, const Color(0xFFFAFCFE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF96A8C3))
                    .withOpacity(isDark ? 0.4 : 0.14),
                blurRadius: 20,
                spreadRadius: 0.2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.22),
                          Colors.blue.withOpacity(0.12),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_rounded,
                        color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.matiere,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Coeff. ${item.coefficient} • ${item.duree}h',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date d\'examen',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  )),
                          const SizedBox(height: 2),
                          Text(item.date.toString().split(' ')[0],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 18, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heure de l\'examen',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  )),
                          const SizedBox(height: 2),
                          Text('${item.heureDebut} - ${item.heureFin}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _PremiumDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: Icon(icon, size: 16, color: Colors.green.shade400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      )),
              const SizedBox(height: 2),
              Text(value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
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

  const _IconDetailRow(
      {required this.icon, required this.label, required this.value});

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
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey[600])),
            ],
          ),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey[600])),
          ),
          Expanded(
              child: Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
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

  const _InfoBox(
      {required this.icon,
      required this.color,
      required this.title,
      required this.message});

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
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(message,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey[600])),
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
