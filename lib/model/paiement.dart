class Paiement {
  final String id;
  final num montant;
  final String modePaiement;
  final String statut;
  final String? referenceTransaction;
  final String? numeroTelephone;
  final DateTime? dateInitiation;
  final DateTime? datePaiement;
  final String? erreur;

  Paiement({
    required this.id,
    required this.montant,
    required this.modePaiement,
    required this.statut,
    this.referenceTransaction,
    this.numeroTelephone,
    this.dateInitiation,
    this.datePaiement,
    this.erreur,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: (json['_id'] ?? '').toString(),
      montant: json['montant'] as num? ?? 0,
      modePaiement: json['modePaiement']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      referenceTransaction: json['referenceTransaction']?.toString(),
      numeroTelephone: json['numeroTelephone']?.toString(),
      dateInitiation: json['dateInitiation'] != null
          ? DateTime.tryParse(json['dateInitiation'].toString())
          : null,
      datePaiement: json['datePaiement'] != null
          ? DateTime.tryParse(json['datePaiement'].toString())
          : null,
      erreur: json['erreur']?.toString(),
    );
  }

  bool get reussi => statut == 'SUCCES' || statut == 'PAYE';
  bool get echoue => statut == 'ECHEC' || statut == 'ANNULE';
  bool get enCours => statut == 'EN_ATTENTE' || statut == 'EN_COURS';
}