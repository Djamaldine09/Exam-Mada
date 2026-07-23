class Note {
  final String matiere;
  final num valeur;
  final num coefficient;

  Note({required this.matiere, required this.valeur, required this.coefficient});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      matiere: json['matiere']?.toString() ?? '',
      valeur: json['valeur'] as num? ?? 0,
      coefficient: json['coefficient'] as num? ?? 1,
    );
  }
}

class Resultat {
  final String id;
  final String examen;
  final List<Note> notes;
  final num moyenneGenerale;
  final String statutFinal; // EN_ATTENTE, ADMIS, REFUSE, REPECHAGE
  final bool estPublie;

  Resultat({
    required this.id,
    required this.examen,
    required this.notes,
    required this.moyenneGenerale,
    required this.statutFinal,
    required this.estPublie,
  });

  factory Resultat.fromJson(Map<String, dynamic> json) {
    return Resultat(
      id: (json['_id'] ?? '').toString(),
      examen: json['examen']?.toString() ?? '',
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList(),
      moyenneGenerale: json['moyenneGenerale'] as num? ?? 0,
      statutFinal: json['statutFinal']?.toString() ?? 'EN_ATTENTE',
      estPublie: json['estPublie'] as bool? ?? false,
    );
  }

  bool get admis => statutFinal == 'ADMIS';
  bool get repechage => statutFinal == 'REPECHAGE';
  bool get refuse => statutFinal == 'REFUSE';
}