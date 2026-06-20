class DocumentModel {
  final int id;
  final String titolo;
  final String descrizione;
  final String tipo;
  final String direzione; // 'azienda_a_dipendente' or 'dipendente_a_azienda'
  final String nomeFile;
  final int dimensioneByte;
  final DateTime? presaVisioneAt;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.tipo,
    required this.direzione,
    required this.nomeFile,
    required this.dimensioneByte,
    this.presaVisioneAt,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      titolo: json['titolo'] as String? ?? '',
      descrizione: json['descrizione'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'altro',
      direzione: json['direzione'] as String? ?? 'azienda_a_dipendente',
      nomeFile: json['nome_file'] as String? ?? '',
      dimensioneByte: json['dimensione_byte'] as int? ?? 0,
      presaVisioneAt: json['presa_visione_at'] != null 
          ? DateTime.parse(json['presa_visione_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'tipo': tipo,
      'direzione': direzione,
      'nome_file': nomeFile,
      'dimensione_byte': dimensioneByte,
      'presa_visione_at': presaVisioneAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRead => presaVisioneAt != null;
  bool get isCompanySent => direzione == 'azienda_a_dipendente';

  String get formattedSize {
    if (dimensioneByte <= 0) return '0 B';
    if (dimensioneByte < 1024) return '$dimensioneByte B';
    if (dimensioneByte < 1024 * 1024) {
      return '${(dimensioneByte / 1024).toStringAsFixed(1)} KB';
    }
    return '${(dimensioneByte / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get tipoEtichetta {
    switch (tipo) {
      case 'busta_paga':
        return 'Busta Paga';
      case 'contratto':
        return 'Contratto';
      case 'comunicazione_interna':
        return 'Comunicazione';
      case 'certificato_malattia':
        return 'Certificato di Malattia';
      case 'certificato_infortunio':
        return 'Certificato Infortunio';
      case 'stato_famiglia':
        return 'Stato di Famiglia';
      case 'certificato_residenza':
        return 'Certificato Residenza';
      case 'carta_identita':
        return "Carta d'Identità";
      case 'attestato_alimentarista':
        return 'Attestato Alimentarista';
      case 'richiesta_assegni_familiari':
        return 'Richiesta Assegni Familiari';
      case 'certificato_medico':
        return 'Certificato Medico';
      default:
        return 'Altro';
    }
  }
}
