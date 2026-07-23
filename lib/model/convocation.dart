class ConvocationCentre {
  final String nom;
  final String adresse;
  final String ville;

  ConvocationCentre({required this.nom, required this.adresse, required this.ville});

  factory ConvocationCentre.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ConvocationCentre(nom: '', adresse: '', ville: '');
    return ConvocationCentre(
      nom: json['nom']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
    );
  }
}

class Convocation {
  final String qrPayload;
  final String candidatId;
  final String examenId;
  final String examenTitre;
  final String dateEpreuve;
  final String heureDebut;
  final String heureFin;
  final ConvocationCentre centre;
  final String salle;
  final String numeroPlace;
  final String matricule;
  final String prenom;
  final String nom;

  Convocation({
    required this.qrPayload,
    required this.candidatId,
    required this.examenId,
    required this.examenTitre,
    required this.dateEpreuve,
    required this.heureDebut,
    required this.heureFin,
    required this.centre,
    required this.salle,
    required this.numeroPlace,
    required this.matricule,
    required this.prenom,
    required this.nom,
  });

  factory Convocation.fromJson(Map<String, dynamic> json) {
    return Convocation(
      qrPayload: json['qrPayload']?.toString() ?? '',
      candidatId: json['candidatId']?.toString() ?? '',
      examenId: json['examenId']?.toString() ?? '',
      examenTitre: json['examenTitre']?.toString() ?? '',
      dateEpreuve: json['dateEpreuve']?.toString() ?? '',
      heureDebut: json['heureDebut']?.toString() ?? '',
      heureFin: json['heureFin']?.toString() ?? '',
      centre: ConvocationCentre.fromJson(json['centre'] as Map<String, dynamic>?),
      salle: json['salle']?.toString() ?? '',
      numeroPlace: json['numeroPlace']?.toString() ?? '',
      matricule: json['matricule']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
    );
  }
}