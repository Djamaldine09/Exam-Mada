import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../theme/theme.dart';
import 'carte_bancaire_screen.dart';

/// Résultat renvoyé après l'initiation d'un paiement, quel que soit le mode
/// choisi, pour que l'écran principal démarre le suivi (polling) du statut.
class PaiementInitieResult {
  final String paiementId;
  final bool isCarte;
  final String? urlCheckout;

  const PaiementInitieResult({
    required this.paiementId,
    required this.isCarte,
    this.urlCheckout,
  });
}

/// Page « Choisir un mode de paiement » : liste des moyens de paiement
/// disponibles (carte bancaire, mobile money...), inspirée d'une maquette
/// de type « Choose Payment option ».
class ChoixModePaiementScreen extends StatefulWidget {
  final num montant;

  const ChoixModePaiementScreen({super.key, required this.montant});

  @override
  State<ChoixModePaiementScreen> createState() => _ChoixModePaiementScreenState();
}

class _ChoixModePaiementScreenState extends State<ChoixModePaiementScreen> {
  bool _isSubmitting = false;

  /// Nom du fichier logo (dans asset/images/payment_logos/) pour chaque mode.
  /// Tant que le fichier n'est pas fourni, une icône de secours est affichée
  /// automatiquement (voir [_buildLogo]).
  static const Map<String, String> _logos = {
    'MVOLA': 'asset/images/payment_logos/mvola.png',
    'ORANGE_MONEY': 'asset/images/payment_logos/orange_money.png',
    'AIRTEL_MONEY': 'asset/images/payment_logos/airtel_money.png',
  };

  static const Map<String, IconData> _icones = {
    'MVOLA': Icons.smartphone_outlined,
    'ORANGE_MONEY': Icons.smartphone_outlined,
    'AIRTEL_MONEY': Icons.smartphone_outlined,
  };

  static const Map<String, Color> _couleurs = {
    'MVOLA': Color(0xFFFFC629),
    'ORANGE_MONEY': Color(0xFFFF7900),
    'AIRTEL_MONEY': Color(0xFFED1C24),
  };

  /// Taille du logo par mode (MVola et Orange Money sont affichés plus
  /// grands car leurs logos ont des marges internes plus importantes).
  static const Map<String, double> _tailles = {
    'MVOLA': 56,
    'ORANGE_MONEY': 56,
    'AIRTEL_MONEY': 40,
  };

  Future<void> _choisirMode(String mode) async {
    if (mode == 'CARTE_BANCAIRE') {
      final result = await Navigator.push<PaiementInitieResult>(
        context,
        MaterialPageRoute(
          builder: (_) => CarteBancaireScreen(montant: widget.montant),
        ),
      );
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
      return;
    }

    final numero = await _demanderNumeroTelephone(mode);
    if (numero == null || numero.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.post(
        ApiConfig.paiementInitier,
        body: {
          'montant': widget.montant,
          'modePaiement': mode,
          'numeroTelephone': numero.trim(),
        },
      );
      final paiementId = response is Map<String, dynamic> ? response['paiementId'] as String? : null;
      if (!mounted) return;
      if (paiementId != null) {
        Navigator.pop(
          context,
          PaiementInitieResult(paiementId: paiementId, isCarte: false),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String?> _demanderNumeroTelephone(String mode) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Payer avec ${AppConstants.modePaiementLabels[mode] ?? mode}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone mobile money',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Choisir un mode\nde paiement',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Montant à payer : ${widget.montant} Ar',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 28),
              _buildOption(
                label: 'Carte bancaire',
                subtitle: 'Visa, Mastercard...',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(
                      'asset/images/payment_logos/visa.webp',
                      fallbackIcon: Icons.credit_card,
                      fallbackColor: const Color(0xFF1A1F71),
                    ),
                    const SizedBox(width: 6),
                    _buildLogo(
                      'asset/images/payment_logos/mastercard.png',
                      fallbackIcon: Icons.credit_card,
                      fallbackColor: const Color(0xFFEB001B),
                    ),
                  ],
                ),
                onTap: () => _choisirMode('CARTE_BANCAIRE'),
              ),
              const SizedBox(height: 14),
              ...AppConstants.modesPaiement.where((m) => m != 'CARTE_BANCAIRE').map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildOption(
                    label: AppConstants.modePaiementLabels[mode] ?? mode,
                    subtitle: 'Mobile money',
                    trailing: _buildLogo(
                      _logos[mode] ?? '',
                      fallbackIcon: _icones[mode] ?? Icons.account_balance_wallet_outlined,
                      fallbackColor: _couleurs[mode] ?? AppColors.primary,
                      size: _tailles[mode] ?? 40,
                    ),
                    onTap: () => _choisirMode(mode),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isSubmitting) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche le vrai logo du moyen de paiement (asset local dans
  /// `asset/images/payment_logos/`), sans cadre autour. Si le fichier n'a
  /// pas encore été ajouté au projet, une icône de secours colorée dans un
  /// petit cadre est affichée à la place, pour ne jamais casser l'écran.
  Widget _buildLogo(
    String assetPath, {
    required IconData fallbackIcon,
    required Color fallbackColor,
    double size = 40,
  }) {
    if (assetPath.isEmpty) {
      return _buildFallbackIcon(fallbackIcon, fallbackColor, size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(fallbackIcon, fallbackColor, size),
      ),
    );
  }

  Widget _buildFallbackIcon(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildOption({
    required String label,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}