import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'api_client.dart';

/// Utilitaire pour télécharger un PDF depuis le backend, le sauvegarder
/// localement puis l'ouvrir ou le partager.
class DownloadService {
  /// Télécharge le PDF à [url], le sauvegarde sous [fileName] dans le
  /// répertoire documents de l'application et retourne le fichier local.
  static Future<File> downloadAndSave(String url, String fileName) async {
    final bytes = await ApiClient.downloadBytes(url);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Télécharge puis ouvre directement le PDF avec l'application par défaut.
  static Future<void> downloadAndOpen(String url, String fileName) async {
    final file = await downloadAndSave(url, fileName);
    await OpenFilex.open(file.path);
  }

  /// Télécharge puis propose le partage du PDF (email, WhatsApp, etc.).
  static Future<void> downloadAndShare(String url, String fileName, {String? text}) async {
    final file = await downloadAndSave(url, fileName);
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}