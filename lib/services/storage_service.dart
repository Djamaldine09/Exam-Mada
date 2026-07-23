import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import '../model/user.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    // Initialize if needed (flutter_secure_storage doesn't require explicit init)
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.secureStorageTokenKey, value: token);
  }

  static Future<void> saveUser(AppUser user) async {
    await _storage.write(
      key: AppConstants.secureStorageUserKey,
      value: jsonEncode(user.toJson()),
    );
  }

  static Future<void> saveSession({required String token, required AppUser user}) async {
    await saveToken(token);
    await saveUser(user);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConstants.secureStorageTokenKey);
  }

  static Future<AppUser?> getUser() async {
    final raw = await _storage.read(key: AppConstants.secureStorageUserKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: AppConstants.secureStorageTokenKey);
    await _storage.delete(key: AppConstants.secureStorageUserKey);
  }
}