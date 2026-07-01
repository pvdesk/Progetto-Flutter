class Automezzo {
  final int id;
  final String? targa;
  final String? marca;
  final String? modello;
  final String? scadenzaAssicurazione;
  final String? scadenzaRevisione;
  final String? dataTagliando;
  final String? compagniaAssicurazione;
  final String? assegnazioneText;

  Automezzo({
    required this.id,
    this.targa,
    this.marca,
    this.modello,
    this.scadenzaAssicurazione,
    this.scadenzaRevisione,
    this.dataTagliando,
    this.compagniaAssicurazione,
    this.assegnazioneText,
  });

  factory Automezzo.fromJson(Map<String, dynamic> json) {
    String? assegnazione;
    if (json['assegnabile'] != null) {
      final type = json['assegnabile_type']?.toString().split('\\').last ?? 'Entità';
      final name = json['assegnabile']['nome'] ?? json['assegnabile']['id']?.toString() ?? '';
      assegnazione = '$type: $name';
      if (json['dipendente'] != null) {
        assegnazione += '\n(Dipendente: ${json['dipendente']['nome']} ${json['dipendente']['cognome']})';
      }
    }

    return Automezzo(
      id: json['id'],
      targa: json['targa'],
      marca: json['marca'],
      modello: json['modello'],
      scadenzaAssicurazione: json['scadenza_assicurazione'],
      scadenzaRevisione: json['scadenza_revisione'],
      dataTagliando: json['data_tagliando'],
      compagniaAssicurazione: json['compagnia_assicurazione'],
      assegnazioneText: assegnazione,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targa': targa,
      'marca': marca,
      'modello': modello,
      'scadenza_assicurazione': scadenzaAssicurazione,
      'scadenza_revisione': scadenzaRevisione,
      'data_tagliando': dataTagliando,
      'compagnia_assicurazione': compagniaAssicurazione,
    };
  }
}
