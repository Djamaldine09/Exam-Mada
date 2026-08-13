import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'api_exception.dart';
import 'storage_service.dart';

/// Client HTTP central : ajoute automatiquement le token JWT, parse le JSON
/// et transforme les erreurs backend en [ApiException] lisibles.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 25);

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await StorageService.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  static String _extractMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) return decoded['message'] as String;
      if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
        return (decoded['errors'] as List).join(', ');
      }
    }
    return 'Erreur inattendue (code $statusCode)';
  }

  static dynamic _handle(http.Response response) {
    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException(_extractMessage(decoded, response.statusCode),
        statusCode: response.statusCode);
  }

  static Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _headers())
          .timeout(_timeout);
      return _handle(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  static Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(Uri.parse(url),
              headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  static Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(Uri.parse(url),
              headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  static Future<dynamic> uploadProfilePhoto({required File file}) async {
    return uploadFile(ApiConfig.profilePhoto, file: file, fieldName: 'photo');
  }

  static Future<dynamic> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: await _headers())
          .timeout(_timeout);
      return _handle(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  /// Upload multipart (pièces justificatives).
  static Future<dynamic> uploadFile(
    String url, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      final headers = await _headers(json: false);
      request.headers.addAll(headers);
      if (fields != null) request.fields.addAll(fields);
      request.files
          .add(await http.MultipartFile.fromPath(fieldName, file.path));

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  /// Télécharge un fichier binaire (PDF) avec le token d'authentification.
  static Future<List<int>> downloadBytes(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _headers(json: false))
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      final decoded = _decode(response);
      throw ApiException(_extractMessage(decoded, response.statusCode),
          statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  static String _networkErrorMessage(Object e) {
    if (e is SocketException) {
      return 'Impossible de joindre le serveur. Vérifie ta connexion ou l\'URL de l\'API.';
    }
    return 'Erreur réseau : $e';
  }
}
