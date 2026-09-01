import 'user.dart';

class PaiementInfo {
  final String statut; // NON_PAYE, EN_COURS, PAYE, ECHEC, REMBOURSEMENT
  final String? referenceTransaction;
  final String? modePaiement;
  final DateTime? datePaiement;
  final num? montant;

  PaiementInfo({
    required this.statut,
    this.referenceTransaction,
    this.modePaiement,
    this.datePaiement,
    this.montant,
  });

  factory PaiementInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PaiementInfo(statut: 'NON_PAYE');
    return PaiementInfo(
      statut: json['statut']?.toString() ?? 'NON_PAYE',
      referenceTransaction: json['referenceTransaction']?.toString(),
      modePaiement: json['modePaiement']?.toString(),
      datePaiement: json['datePaiement'] != null
          ? DateTime.tryParse(json['datePaiement'].toString())
          : null,
      montant: json['montant'] as num?,
    );
  }
}

class PiecesJustificatives {
  final String? photoIdentite;
  final String? acteNaissance;
  final String? diplomePrecedent;
  final String? photoSupp;

  PiecesJustificatives({
    this.photoIdentite,
    this.acteNaissance,
    this.diplomePrecedent,
    this.photoSupp,
  });

  factory PiecesJustificatives.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PiecesJustificatives();
    String? extract(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map && v['status'] != null && v['status'] != 'manquant') {
        return v['status'].toString();
      }
      return null;
    }

    return PiecesJustificatives(
      photoIdentite: extract(json['photoIdentite']),
      acteNaissance: extract(json['acteNaissance']),
      diplomePrecedent: extract(json['diplomePrecedent']),
      photoSupp: extract(json['photoSupp']),
    );
  }

  int get nombreFournies => [photoIdentite, acteNaissance, photoSupp]
      .where((e) => e != null && e.isNotEmpty)
      .length;
}

class CentreAffecte {
  final String? nom;
  final String? ville;
  final String? region;
  final String? adresse;
  final String? salle;
  final String? numeroPlace;
  final double? lat;
  final double? lng;

  CentreAffecte({
    this.nom,
    this.ville,
    this.region,
    this.adresse,
    this.salle,
    this.numeroPlace,
    this.lat,
    this.lng,
  });

  factory CentreAffecte.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CentreAffecte();
    final coords = json['coords'] as Map<String, dynamic>?;
    return CentreAffecte(
      nom: json['nom']?.toString(),
      ville: json['ville']?.toString(),
      region: json['region']?.toString(),
      adresse: json['adresse']?.toString(),
      salle: json['salle']?.toString(),
      numeroPlace: json['numeroPlace']?.toString(),
      lat: (coords?['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      lng: (coords?['lng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
    );
  }

  bool get isDefini => nom != null && nom!.isNotEmpty;
}

class PlanningItem {
  final String matiere;
  final DateTime date;
  final String heureDebut;
  final String heureFin;
  final num duree;
  final num coefficient;
  final String type;

  PlanningItem({
    required this.matiere,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.duree,
    required this.coefficient,
    required this.type,
  });

  factory PlanningItem.fromJson(Map<String, dynamic> json) {
    return PlanningItem(
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

class Candidat {
  final String id;
  final AppUser? user;
  final String? numeroMatricule;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String? genre;
  final String examen;
  final String serieFiliere;
  final String? centreExamenSouhaite;
  final String? cin;
  final String? etablissementPrecedent;
  final String? mentionPrecedente;
  final String? adresse;
  final String? telephone;
  final String? emailParent;
  final String? region;
  final String statutInscription; // BROUILLON, EN_ATTENTE_VALIDATION, VALIDE, REJETE
  final PaiementInfo paiement;
  final PiecesJustificatives piecesJustificatives;
  final CentreAffecte? centreAffecte;
  final List<PlanningItem> planning;

  Candidat({
    required this.id,
    this.user,
    this.numeroMatricule,
    this.dateNaissance,
    this.lieuNaissance,
    this.genre,
    required this.examen,
    required this.serieFiliere,
    this.centreExamenSouhaite,
    this.cin,
    this.etablissementPrecedent,
    this.mentionPrecedente,
    this.adresse,
    this.telephone,
    this.emailParent,
    this.region,
    required this.statutInscription,
    required this.paiement,
    required this.piecesJustificatives,
    this.centreAffecte,
    this.planning = const [],
  });

  factory Candidat.fromJson(Map<String, dynamic> json) {
    AppUser? parsedUser;
    final rawUser = json['user'];
    if (rawUser is Map<String, dynamic>) {
      parsedUser = AppUser.fromJson(rawUser);
    }

    return Candidat(
      id: (json['_id'] ?? '').toString(),
      user: parsedUser,
      numeroMatricule: json['numeroMatricule']?.toString(),
      dateNaissance: json['dateNaissance'] != null
          ? DateTime.tryParse(json['dateNaissance'].toString())
          : null,
      lieuNaissance: json['lieuNaissance']?.toString(),
      genre: json['genre']?.toString(),
      examen: json['examen']?.toString() ?? '',
      serieFiliere: json['serieFiliere']?.toString() ?? '',
      centreExamenSouhaite: json['centreExamenSouhaite']?.toString(),
      cin: json['cin']?.toString(),
      etablissementPrecedent: json['etablissementPrecedent']?.toString(),
      mentionPrecedente: json['mentionPrecedente']?.toString(),
      adresse: json['adresse']?.toString(),
      telephone: json['telephone']?.toString(),
      emailParent: json['emailParent']?.toString(),
      region: json['region']?.toString(),
      statutInscription: json['statutInscription']?.toString() ?? 'BROUILLON',
      paiement: PaiementInfo.fromJson(json['paiement'] as Map<String, dynamic>?),
      piecesJustificatives:
          PiecesJustificatives.fromJson(json['piecesJustificatives'] as Map<String, dynamic>?),
      centreAffecte: json['centreAffecte'] != null
          ? CentreAffecte.fromJson(json['centreAffecte'] as Map<String, dynamic>?)
          : null,
      planning: (json['planning'] as List<dynamic>? ?? [])
          .map((e) => PlanningItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get estValide => statutInscription == 'VALIDE';
  bool get estPaye => paiement.statut == 'PAYE';
  bool get aUnCentreAffecte => centreAffecte?.isDefini ?? false;
}