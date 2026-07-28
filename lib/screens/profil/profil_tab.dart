import 'package:flutter/material.dart';

import '../../model/candidat.dart';
import '../../model/user.dart';
import '../documents/documents_screen.dart';
import '../inscription/inscription_screen.dart';
import '../notifications/notifications_screen.dart';

class ProfilTab extends StatelessWidget {
  final AppUser? currentUser;
  final Candidat? candidat;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const ProfilTab({
    super.key,
    required this.currentUser,
    required this.candidat,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = currentUser?.displayName.trim().isNotEmpty == true
        ? currentUser!.displayName
        : 'Candidat ExamGest';
    final email = currentUser?.email.trim().isNotEmpty == true
        ? currentUser!.email
        : 'Adresse email non renseignée';
    final status = candidat?.statutInscription ?? 'Profil en cours';

    return Container(
      color: isDark ? const Color(0xFF111315) : const Color(0xFFF7F8FA),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(fullName: fullName, email: email, status: status, isDark: isDark),
              const SizedBox(height: 24),
              Text(
                'Profil',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF16181D),
                    ),
              ),
              const SizedBox(height: 18),
              _ProfileInfoCard(currentUser: currentUser, candidat: candidat, isDark: isDark),
              const SizedBox(height: 24),
              _SettingsSection(
                isDark: isDark,
                children: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Informations personnelles',
                    subtitle: 'Nom, téléphone et informations candidat',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => InscriptionScreen(candidat: candidat)))
                          .then((_) => onRefresh());
                    },
                  ),
                  _ProfileDivider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.folder_copy_outlined,
                    title: 'Mes documents',
                    subtitle: 'Pièces justificatives et fichiers déposés',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentsScreen())),
                  ),
                  _ProfileDivider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Gérer les alertes et les rappels',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsSection(
                isDark: isDark,
                children: [
                  _ProfileMenuItem(
                    icon: Icons.language_rounded,
                    title: 'Langue',
                    subtitle: 'Français',
                    isDark: isDark,
                    onTap: () => _showInfo(context, 'La sélection de langue sera disponible prochainement.'),
                  ),
                  _ProfileDivider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.palette_outlined,
                    title: 'Apparence',
                    subtitle: isDark ? 'Mode sombre' : 'Mode clair',
                    isDark: isDark,
                    onTap: () => _showInfo(context, 'La sélection du thème sera disponible prochainement.'),
                  ),
                  _ProfileDivider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sécurité du compte',
                    subtitle: 'Protéger votre compte ExamGest',
                    isDark: isDark,
                    onTap: () => _showInfo(context, 'Les options de sécurité seront disponibles prochainement.'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String status;
  final bool isDark;

  const _ProfileHeader({
    required this.fullName,
    required this.email,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                _StatusPill(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final AppUser? currentUser;
  final Candidat? candidat;
  final bool isDark;

  const _ProfileInfoCard({required this.currentUser, required this.candidat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _ProfileField(icon: Icons.person_outline, label: 'Nom', value: currentUser?.nom ?? 'Non renseigné'),
      if (currentUser?.prenom != null)
        _ProfileField(icon: Icons.badge_outlined, label: 'Prénom', value: currentUser!.prenom!),
      _ProfileField(icon: Icons.mail_outline, label: 'Email', value: currentUser?.email ?? 'Non renseigné'),
      if (currentUser?.telephone != null)
        _ProfileField(icon: Icons.phone_android_outlined, label: 'Téléphone', value: currentUser!.telephone!),
      if (candidat?.numeroMatricule != null)
        _ProfileField(icon: Icons.school_outlined, label: 'Matricule', value: candidat!.numeroMatricule!),
      if (candidat != null)
        _ProfileField(icon: Icons.menu_book_outlined, label: 'Examen', value: candidat!.examen),
      if (candidat != null)
        _ProfileField(icon: Icons.track_changes_outlined, label: 'Série/Filière', value: candidat!.serieFiliere),
    ];

    return _SettingsSection(isDark: isDark, children: _withDividers(fields, isDark));
  }
}

class _SettingsSection extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsSection({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2024) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  final bool isDark;

  const _ProfileDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 56, color: isDark ? Colors.white10 : Colors.black12);
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'VALIDE'
        ? Colors.green
        : status == 'REJETE'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

List<Widget> _withDividers(List<Widget> items, bool isDark) {
  final children = <Widget>[];
  for (var i = 0; i < items.length; i += 1) {
    children.add(items[i]);
    if (i < items.length - 1) {
      children.add(_ProfileDivider(isDark: isDark));
    }
  }
  return children;
}
