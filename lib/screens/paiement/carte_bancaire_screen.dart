import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../theme/theme.dart';
import 'choix_mode_paiement_screen.dart';

/// Formatte la saisie du numéro de carte en groupes de 4 chiffres
/// (ex : 5534 2834 8857 5370), comme sur la maquette.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').substring(
        0, newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 16));
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Page de saisie « Debit / Credit Card », inspirée de la maquette fournie :
/// onglets Debit / Credit, numéro de carte, expiration, CVV, nom du
/// titulaire et bouton « Pay Now ».
class CarteBancaireScreen extends StatefulWidget {
  final num montant;

  const CarteBancaireScreen({super.key, required this.montant});

  @override
  State<CarteBancaireScreen> createState() => _CarteBancaireScreenState();
}

class _CarteBancaireScreenState extends State<CarteBancaireScreen> {
  int _tabIndex = 0; // 0 = Debit Card, 1 = Credit Card

  final _formKey = GlobalKey<FormState>();
  final _numeroCarteController = TextEditingController();
  final _nomController = TextEditingController();
  final _cvvController = TextEditingController();

  String _moisExpiration = 'Jan';
  int _anneeExpiration = DateTime.now().year;
  bool _sauvegarderCarte = true;
  bool _isSubmitting = false;

  static const List<String> _mois = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  @override
  void dispose() {
    _numeroCarteController.dispose();
    _nomController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _typeCarteDetecte {
    final digits = _numeroCarteController.text.replaceAll(' ', '');
    if (digits.startsWith('4')) return 'VISA';
    if (digits.startsWith('5')) return 'MASTERCARD';
    return '';
  }

  /// Logo du réseau détecté (Visa / Mastercard) affiché dans le champ
  /// « Card Number ». Si le fichier asset n'est pas encore fourni, on
  /// retombe sur le libellé texte. Taille bornée pour ne jamais déborder
  /// du champ, même si le fichier image fourni est très grand.
  Widget _buildTypeCarteBadge() {
    final estVisa = _typeCarteDetecte == 'VISA';
    final assetPath = estVisa
        ? 'asset/images/payment_logos/visa.png'
        : 'asset/images/payment_logos/mastercard.png';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        width: 36,
        height: 22,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Image.asset(
            assetPath,
            errorBuilder: (context, error, stackTrace) => Text(
              _typeCarteDetecte,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _payer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      // On initie le paiement côté backend et on récupère la réponse
      // (dont l'URL de la session Stripe Checkout), sans jamais ouvrir
      // Stripe automatiquement : c'est juste la réponse qui est conservée.
      final response = await ApiClient.post(
        ApiConfig.paiementInitier,
        body: {
          'montant': widget.montant,
          'modePaiement': 'CARTE_BANCAIRE',
        },
      );

      final url = response is Map<String, dynamic> ? response['url'] as String? : null;
      final paiementId = response is Map<String, dynamic> ? response['paiementId'] as String? : null;

      if (!mounted) return;
      if (paiementId != null) {
        Navigator.pop(
          context,
          PaiementInitieResult(paiementId: paiementId, isCarte: true, urlCheckout: url),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debit / Credit\nCard',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 20),
                _buildTabs(),
                const SizedBox(height: 24),
                _buildLabel('Card Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numeroCarteController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CardNumberFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '0000 0000 0000 0000',
                    suffixIcon: _typeCarteDetecte.isEmpty ? null : _buildTypeCarteBadge(),
                    suffixIconConstraints: const BoxConstraints(minWidth: 44, maxWidth: 60, maxHeight: 28),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(' ', '');
                    if (digits.length < 16) return 'Numéro de carte invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Expiry date'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildMoisDropdown()),
                              const SizedBox(width: 8),
                              Expanded(child: _buildAnneeDropdown()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('CVV'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 3,
                            decoration: const InputDecoration(counterText: '', hintText: '•••'),
                            validator: (v) => (v == null || v.length < 3) ? 'CVV invalide' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabel('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'NOM DU TITULAIRE'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: Checkbox(
                        value: _sauvegarderCarte,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _sauvegarderCarte = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Save card for future checkouts', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel payment'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _payer,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600));

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          _buildTab('Debit Card', 0),
          _buildTab('Credit Card', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoisDropdown() {
    return DropdownButtonFormField<String>(
      value: _moisExpiration,
      isExpanded: true,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
      items: _mois.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (v) => setState(() => _moisExpiration = v ?? _moisExpiration),
    );
  }

  Widget _buildAnneeDropdown() {
    final annees = List.generate(12, (i) => DateTime.now().year + i);
    return DropdownButtonFormField<int>(
      value: _anneeExpiration,
      isExpanded: true,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
      items: annees.map((a) => DropdownMenuItem(value: a, child: Text('$a'))).toList(),
      onChanged: (v) => setState(() => _anneeExpiration = v ?? _anneeExpiration),
    );
  }
}