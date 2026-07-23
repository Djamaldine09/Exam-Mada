class AppUser {
  final String id;
  final String nom;
  final String? prenom;
  final String email;
  final String role;
  final String? telephone;
  final String? token;

  AppUser({
    required this.id,
    required this.nom,
    this.prenom,
    required this.email,
    required this.role,
    this.telephone,
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
      if (token != null) 'token': token,
    };
  }

  String get displayName {
    if (prenom != null && prenom!.isNotEmpty) {
      return '$prenom $nom';
    }
    return nom;
  }
}
