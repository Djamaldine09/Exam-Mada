import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../services/download_service.dart';
import '../../model/resultat.dart';

class ResultatsScreen extends StatefulWidget {
  const ResultatsScreen({super.key});

  @override
  State<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends State<ResultatsScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  Resultat? _resultat;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiClient.get(ApiConfig.monResultat);
      setState(() => _resultat = Resultat.fromJson(response as Map<String, dynamic>));
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReleve() async {
    setState(() => _isDownloading = true);
    try {
      await DownloadService.downloadAndOpen(
        ApiConfig.releveNotesPdf,
        'releve_notes_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Color get _statutColor {
    if (_resultat == null) return Colors.grey;
    if (_resultat!.admis) return Colors.green;
    if (_resultat!.repechage) return Colors.orange;
    return Colors.red;
  }

  String get _statutLabel {
    if (_resultat == null) return '';
    if (_resultat!.admis) return 'ADMIS(E)';
    if (_resultat!.repechage) return 'REPÊCHAGE';
    return 'REFUSÉ(E)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes résultats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(onRefresh: _load, child: _buildContent()),
      floatingActionButton: _resultat != null
          ? FloatingActionButton.extended(
              onPressed: _isDownloading ? null : _downloadReleve,
              icon: _isDownloading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: const Text('Relevé PDF'),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _resultat!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_statutColor, _statutColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(r.examen, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_statutLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Moyenne générale : ${r.moyenneGenerale} / 20',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Détail des notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...r.notes.map((n) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(n.matiere, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('Coef. ${n.coefficient}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ),
                          Text('${n.valeur}/20',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: n.valeur >= 10 ? Colors.green : Colors.red,
                              )),
                        ],
                      ),
                    )),
                if (r.notes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucune note saisie pour le moment', style: TextStyle(color: Colors.grey[600])),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}