class Epreuve {
  final String matiere;
  final DateTime date;
  final String heureDebut;
  final String heureFin;
  final num duree;
  final num coefficient;
  final String type;

  Epreuve({
    required this.matiere,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.duree,
    required this.coefficient,
    required this.type,
  });

  factory Epreuve.fromJson(Map<String, dynamic> json) {
    return Epreuve(
      matiere: json['matiere']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      heureDebut: json['heureDebut']?.toString() ?? '',
      heureFin: json['heureFin']?.toString() ?? '',
      duree: json['duree'] as num? ?? 0,
      coefficient: json['coefficient'] as num? ?? 1,
      type: json['type']?.toString() ?? 'EPREUVE',
    );
  }
}

class Examen {
  final String id;
  final String titre;
  final String type;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? description;
  final String? lieu;
  final String statut; // PLANIFIE, EN_COURS, TERMINE
  final int nombreCandidats;
  final int nombreCentres;
  final List<Epreuve> epreuves;

  Examen({
    required this.id,
    required this.titre,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    this.description,
    this.lieu,
    required this.statut,
    this.nombreCandidats = 0,
    this.nombreCentres = 0,
    this.epreuves = const [],
  });

  factory Examen.fromJson(Map<String, dynamic> json) {
    return Examen(
      id: (json['_id'] ?? '').toString(),
      titre: json['titre']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      dateDebut: DateTime.tryParse(json['dateDebut']?.toString() ?? '') ?? DateTime.now(),
      dateFin: DateTime.tryParse(json['dateFin']?.toString() ?? '') ?? DateTime.now(),
      description: json['description']?.toString(),
      lieu: json['lieu']?.toString(),
      statut: json['statut']?.toString() ?? 'PLANIFIE',
      nombreCandidats: (json['nombreCandidats'] as num?)?.toInt() ?? 0,
      nombreCentres: (json['nombreCentres'] as num?)?.toInt() ?? 0,
      epreuves: (json['epreuves'] as List<dynamic>? ?? [])
          .map((e) => Epreuve.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}