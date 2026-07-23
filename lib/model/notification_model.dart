class AppNotification {
  final String id;
  final String titre;
  final String message;
  final String type; // INFO, SUCCESS, WARNING, ERROR
  final bool lue;
  final String? lien;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.lue,
    this.lien,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? '').toString(),
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INFO',
      lue: json['lue'] as bool? ?? false,
      lien: json['lien']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}