import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/download_service.dart';
import '../../model/candidat.dart';
import '../../model/paiement.dart';
import 'choix_mode_paiement_screen.dart';

class PaiementScreen extends StatefulWidget {
  final Candidat? candidat;

  const PaiementScreen({super.key, this.candidat});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> with WidgetsBindingObserver {
  bool _isLoadingHistory = true;
  bool _isSubmitting = false;
  bool _isDownloading = false;
  List<Paiement> _history = [];
  String? _errorMessage;

  final _montantController =
      TextEditingController(text: AppConstants.montantExamenDefaut.toString());

  Timer? _pollingTimer;
  bool _isPolling = false;
  int _pollingAttempts = 0;
  static const int _maxPollingAttemptsMobileMoney = 20; // ~80s à 4s d'intervalle
  static const int _maxPollingAttemptsCarte = 60; // ~5min : le temps de payer sur la page Stripe

  // Paiement carte en attente de confirmation (le candidat est parti sur la page
  // Stripe dans le navigateur externe) : on revérifie dès qu'il revient sur l'appli.
  String? _pendingCardPaiementId;

  // Reflète immédiatement un paiement confirmé pendant cette session, sans
  // attendre un retour à l'écran d'accueil (qui recharge les données du candidat).
  String? _statutOverride;

  PaiementInfo? get _paiementInfo => widget.candidat?.paiement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _montantController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Le candidat revient dans l'appli après être allé payer par carte sur la
    // page Stripe ouverte dans le navigateur externe : on vérifie tout de suite
    // au lieu d'attendre le prochain cycle du polling.
    if (state == AppLifecycleState.resumed && _pendingCardPaiementId != null) {
      _checkStatusOnce(_pendingCardPaiementId!);
      _loadHistory();
    }
  }

  Future<void> _checkStatusOnce(String paiementId) async {
    try {
      final response = await ApiClient.get(ApiConfig.paiementStatus(paiementId));
      final statut = response is Map<String, dynamic> ? response['statut'] as String? : null;
      final terminal = statut != null &&
          {'PAYE', 'SUCCES', 'ECHEC', 'ANNULE', 'REMBOURSEMENT'}.contains(statut);
      if (terminal) {
        _pollingTimer?.cancel();
        if (mounted) setState(() {
          _isPolling = false;
          _statutOverride = statut;
        });
        _pendingCardPaiementId = null;
        _notifyStatutFinal(statut!);
        await _loadHistory();
      }
    } catch (_) {
      // Ignoré : le polling en cours (ou le prochain retour dans l'appli) réessaiera.
    }
  }

  void _notifyStatutFinal(String statut) {
    if (!mounted) return;
    final reussi = statut == 'PAYE' || statut == 'SUCCES';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reussi ? 'Paiement confirmé !' : 'Paiement ${_statutLabel(statut).toLowerCase()}.'),
        backgroundColor: reussi ? Colors.green : Colors.red,
      ),
    );
  }

  void _startPollingStatus(String paiementId, {required bool isCarte}) {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;
    if (isCarte) _pendingCardPaiementId = paiementId;
    setState(() => _isPolling = true);
    final maxAttempts = isCarte ? _maxPollingAttemptsCarte : _maxPollingAttemptsMobileMoney;

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollingAttempts++;
      try {
        final response = await ApiClient.get(ApiConfig.paiementStatus(paiementId));
        final statut = response is Map<String, dynamic> ? response['statut'] as String? : null;
        final terminal = statut != null &&
            {'PAYE', 'SUCCES', 'ECHEC', 'ANNULE', 'REMBOURSEMENT'}.contains(statut);

        if (terminal || _pollingAttempts >= maxAttempts) {
          timer.cancel();
          _pendingCardPaiementId = null;
          if (!mounted) return;
          setState(() {
            _isPolling = false;
            if (terminal) _statutOverride = statut;
          });
          if (statut != null) {
            final reussi = statut == 'PAYE' || statut == 'SUCCES';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(reussi
                    ? 'Paiement confirmé !'
                    : terminal
                        ? 'Paiement ${_statutLabel(statut).toLowerCase()}.'
                        : 'Statut du paiement en attente, vérifiez l\'historique plus tard.'),
                backgroundColor: reussi ? Colors.green : (terminal ? Colors.red : null),
              ),
            );
          }
          await _loadHistory();
        }
      } catch (_) {
        // Erreur réseau ponctuelle : on retente au prochain cycle, sans bloquer l'utilisateur.
        if (_pollingAttempts >= maxAttempts) {
          timer.cancel();
          _pendingCardPaiementId = null;
          if (mounted) setState(() => _isPolling = false);
        }
      }
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final response = await ApiClient.get(ApiConfig.paiementHistory);
      final list = (response as List<dynamic>? ?? [])
          .map((e) => Paiement.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _history = list);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur historique : $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _ouvrirChoixModePaiement() async {
    final montant = num.tryParse(_montantController.text.trim());
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    final result = await Navigator.push<PaiementInitieResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ChoixModePaiementScreen(montant: montant),
      ),
    );

    if (result == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isCarte
            ? 'Paiement carte initié. En attente de confirmation.'
            : 'Paiement initié. Validez la transaction depuis votre téléphone.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    await _loadHistory();
    _startPollingStatus(result.paiementId, isCarte: result.isCarte);
  }

  Future<void> _downloadBulletin() async {
    setState(() => _isDownloading = true);
    try {
      await DownloadService.downloadAndOpen(
        ApiConfig.bulletinVersementPdf,
        'bulletin_versement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'PAYE':
        return Colors.green;
      case 'EN_COURS':
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'ECHEC':
      case 'ANNULE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estPaye = _statutOverride == 'PAYE' || (_statutOverride == null && _paiementInfo?.statut == 'PAYE');

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement des frais')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              if (_isPolling) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 5, 5, 5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Vérification du paiement en cours...'),
                      ),
                      if (_pendingCardPaiementId != null)
                        TextButton(
                          onPressed: () => _checkStatusOnce(_pendingCardPaiementId!),
                          child: const Text('Vérifier maintenant'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!estPaye) ...[
                Text('Nouveau paiement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildPaymentForm(),
                const SizedBox(height: 24),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _downloadBulletin,
                  icon: _isDownloading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.receipt_long_outlined),
                  label: const Text('Télécharger le bulletin de versement'),
                ),
                const SizedBox(height: 24),
              ],
              Text('Historique', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _isLoadingHistory
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : _history.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: Text('Aucun paiement pour le moment',
                                  style: TextStyle(color: Colors.grey[600]))),
                        )
                      : Column(children: _history.map(_buildHistoryTile).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statut = _statutOverride ?? _paiementInfo?.statut ?? 'NON_PAYE';
    final color = _statutColor(statut);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(
              statut == 'PAYE' ? Icons.check_circle_outline : Icons.payment_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut : ${_statutLabel(statut)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                if (_paiementInfo?.montant != null)
                  Text('${_paiementInfo!.montant} Ar', style: TextStyle(color: Colors.grey[700])),
                if (_paiementInfo?.modePaiement != null)
                  Text(AppConstants.modePaiementLabels[_paiementInfo!.modePaiement] ?? _paiementInfo!.modePaiement!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'PAYE':
        return 'Payé';
      case 'EN_COURS':
        return 'En cours';
      case 'ECHEC':
        return 'Échec';
      case 'REMBOURSEMENT':
        return 'Remboursé';
      default:
        return 'Non payé';
    }
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _montantController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(labelText: 'Montant (Ar)')
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _ouvrirChoixModePaiement,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Choisir un mode de paiement'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Paiement p) {
    final color = _statutColor(p.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.montant} Ar', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(AppConstants.modePaiementLabels[p.modePaiement] ?? p.modePaiement,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (p.dateInitiation != null)
                  Text(p.dateInitiation.toString().split('.').first, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(p.statut, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}