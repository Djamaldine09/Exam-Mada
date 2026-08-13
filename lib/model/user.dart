import '../constants.dart';

class AppUser {
  final String id;
  final String nom;
  final String? prenom;
  final String email;
  final String role;
  final String? telephone;
  final String? photo;
  final String? token;

  AppUser({
    required this.id,
    required this.nom,
    this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    this.photo,
    this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString(),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CANDIDAT',
      telephone: json['telephone']?.toString(),
      photo: json['photo']?.toString(),
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      if (prenom != null) 'prenom': prenom,
      'email': email,
      'role': role,
      if (telephone != null) 'telephone': telephone,
      if (photo != null) 'photo': photo,
      if (token != null) 'token': token,
    };
  }

  String get displayName {
    if (prenom != null && prenom!.isNotEmpty) {
      return '$prenom $nom';
    }
    return nom;
  }

  String? get photoUrl {
    if (photo == null || photo!.isEmpty) {
      return null;
    }

    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }

    return '${ApiConfig.baseUrl}$photo';
  }
}
