class DdtModel {
  final int id;
  final String numero;
  final String? data;
  final String stato;
  final String? origine;
  final String? destinatario;
  final String? indirizzo;
  final int? colli;
  final double? pesoKg;
  final List<DdtRiga> righe;
  final List<DdtFirma> firme;

  DdtModel({
    required this.id,
    required this.numero,
    this.data,
    required this.stato,
    this.origine,
    this.destinatario,
    this.indirizzo,
    this.colli,
    this.pesoKg,
    this.righe = const [],
    this.firme = const [],
  });

  factory DdtModel.fromJson(Map<String, dynamic> json) {
    return DdtModel(
      id: json['id'],
      numero: json['numero'],
      data: json['data'],
      stato: json['stato'],
      origine: json['origine'],
      destinatario: json['destinatario'],
      indirizzo: json['indirizzo'],
      colli: json['colli'],
      pesoKg: json['peso_kg'] != null ? (json['peso_kg'] as num).toDouble() : null,
      righe: json['righe'] != null
          ? (json['righe'] as List).map((i) => DdtRiga.fromJson(i)).toList()
          : [],
      firme: json['firme'] != null
          ? (json['firme'] as List).map((i) => DdtFirma.fromJson(i)).toList()
          : [],
    );
  }
}

class DdtRiga {
  final String? descrizione;
  final String? codice;
  final double? quantita;
  final String? um;

  DdtRiga({this.descrizione, this.codice, this.quantita, this.um});

  factory DdtRiga.fromJson(Map<String, dynamic> json) {
    return DdtRiga(
      descrizione: json['descrizione'],
      codice: json['codice'],
      quantita: json['quantita'] != null ? (json['quantita'] as num).toDouble() : null,
      um: json['um'],
    );
  }
}

class DdtFirma {
  final String ruolo;
  final String? nome;
  final String? firmatoAt;

  DdtFirma({required this.ruolo, this.nome, this.firmatoAt});

  factory DdtFirma.fromJson(Map<String, dynamic> json) {
    return DdtFirma(
      ruolo: json['ruolo'],
      nome: json['nome'],
      firmatoAt: json['firmato_at'],
    );
  }
}
