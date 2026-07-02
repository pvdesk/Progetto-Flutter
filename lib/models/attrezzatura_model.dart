import 'tipo_attrezzatura_model.dart';

class Attrezzatura {
  final int id;
  final String codiceIdentificativo;
  final int? tipoAttrezzaturaId;
  final TipoAttrezzatura? tipoAttrezzatura;
  final String? marca;
  final String? modello;
  final String? matricola;
  final String? descrizione;
  final String stato;
  final int? commessaId;
  final int? puntoServizioId;
  final int? centroProduttivoId;
  final String? commessaNome;
  final String? puntoServizioNome;
  final String? centroProduttivoNome;
  final List<InterventoAttrezzatura> interventi;

  Attrezzatura({
    required this.id,
    required this.codiceIdentificativo,
    this.tipoAttrezzaturaId,
    this.tipoAttrezzatura,
    this.marca,
    this.modello,
    this.matricola,
    this.descrizione,
    required this.stato,
    this.commessaId,
    this.puntoServizioId,
    this.centroProduttivoId,
    this.commessaNome,
    this.puntoServizioNome,
    this.centroProduttivoNome,
    required this.interventi,
  });

  factory Attrezzatura.fromJson(Map<String, dynamic> json) {
    var list = json['interventi'] as List? ?? [];
    List<InterventoAttrezzatura> intList = list.map((i) => InterventoAttrezzatura.fromJson(i)).toList();

    return Attrezzatura(
      id: json['id'],
      codiceIdentificativo: json['codice_identificativo'] ?? '',
      tipoAttrezzaturaId: json['tipo_attrezzatura_id'],
      tipoAttrezzatura: json['tipo_attrezzatura'] != null
          ? TipoAttrezzatura.fromJson(json['tipo_attrezzatura'])
          : null,
      marca: json['marca'],
      modello: json['modello'],
      matricola: json['matricola'],
      descrizione: json['descrizione'],
      stato: json['stato'] ?? 'non_mappato',
      commessaId: json['commessa_id'],
      puntoServizioId: json['punto_servizio_id'],
      centroProduttivoId: json['centro_produttivo_id'],
      commessaNome: json['commessa'] != null ? json['commessa']['codice']?.toString() : null,
      puntoServizioNome: json['punto_servizio'] != null ? json['punto_servizio']['nome']?.toString() : null,
      centroProduttivoNome: json['centro_produttivo'] != null ? json['centro_produttivo']['nome']?.toString() : null,
      interventi: intList,
    );
  }
}

class InterventoAttrezzatura {
  final int id;
  final int? userId;
  final String? userName;
  final int? dittaManutenzioneId;
  final String? dittaNome;
  final String tipoManutenzione;
  final String dataIntervento;
  final String descrizione;
  final double? costo;
  final String? documentoPath;
  final String? fatturaPath;

  InterventoAttrezzatura({
    required this.id,
    this.userId,
    this.userName,
    this.dittaManutenzioneId,
    this.dittaNome,
    required this.tipoManutenzione,
    required this.dataIntervento,
    required this.descrizione,
    this.costo,
    this.documentoPath,
    this.fatturaPath,
  });

  factory InterventoAttrezzatura.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['user'] != null) {
      name = "${json['user']['name']} ${json['user']['cognome'] ?? ''}".trim();
    }
    
    double? costDouble;
    if (json['costo'] != null) {
      costDouble = double.tryParse(json['costo'].toString());
    }

    return InterventoAttrezzatura(
      id: json['id'],
      userId: json['user_id'],
      userName: name,
      dittaManutenzioneId: json['ditta_manutenzione_id'],
      dittaNome: json['ditta_manutenzione'] != null ? json['ditta_manutenzione']['ragione_sociale']?.toString() : null,
      tipoManutenzione: json['tipo_manutenzione'] ?? 'interna',
      dataIntervento: json['data_intervento'] ?? '',
      descrizione: json['descrizione'] ?? '',
      costo: costDouble,
      documentoPath: json['documento_path'],
      fatturaPath: json['fattura_path'],
    );
  }
}
