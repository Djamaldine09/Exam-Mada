import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants.dart';
import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../services/download_service.dart';
import '../../model/convocation.dart';

class ConvocationScreen extends StatefulWidget {
  const ConvocationScreen({super.key});

  @override
  State<ConvocationScreen> createState() => _ConvocationScreenState();
}

class _ConvocationScreenState extends State<ConvocationScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  Convocation? _convocation;
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
      final response = await ApiClient.get(ApiConfig.candidatConvocation);
      final data = response is Map<String, dynamic> ? response['data'] as Map<String, dynamic>? : null;
      if (data == null) throw Exception('Réponse invalide');
      setState(() => _convocation = Convocation.fromJson(data));
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf({bool share = false}) async {
    setState(() => _isDownloading = true);
    try {
      final fileName = 'convocation_${_convocation?.matricule ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      if (share) {
        await DownloadService.downloadAndShare(ApiConfig.convocationPdf, fileName,
            text: 'Ma convocation ${AppConstants.appName}');
      } else {
        await DownloadService.downloadAndOpen(ApiConfig.convocationPdf, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur téléchargement : $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma convocation'),
        actions: [
          if (_convocation != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _isDownloading ? null : () => _downloadPdf(share: true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildContent(),
                ),
      floatingActionButton: _convocation != null
          ? FloatingActionButton.extended(
              onPressed: _isDownloading ? null : () => _downloadPdf(),
              icon: _isDownloading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: const Text('Télécharger le PDF'),
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
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = _convocation!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text('${c.prenom} ${c.nom}'.trim(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Matricule : ${c.matricule}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 20),
                if (c.qrPayload.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: QrImageView(
                      data: c.qrPayload,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: true,
                    ),
                  ),
                const SizedBox(height: 8),
                Text('À présenter à l\'entrée du centre d\'examen',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(c),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Convocation c) {
    return Container(
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
          Text("Détails de l'épreuve",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row(Icons.school_outlined, 'Examen', c.examenTitre),
          _row(Icons.event_outlined, 'Date', c.dateEpreuve),
          _row(Icons.schedule_outlined, 'Horaire', '${c.heureDebut} - ${c.heureFin}'),
          _row(Icons.apartment_outlined, 'Centre', c.centre.nom),
          _row(Icons.place_outlined, 'Adresse', '${c.centre.adresse}, ${c.centre.ville}'),
          _row(Icons.meeting_room_outlined, 'Salle', c.salle),
          _row(Icons.event_seat_outlined, 'Place N°', c.numeroPlace),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    if (value.trim().isEmpty || value == ', ') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}