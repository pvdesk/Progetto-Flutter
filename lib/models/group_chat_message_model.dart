class GroupChatMessageModel {
  final int id;
  final int mittenteUserId;
  final int puntoServizioId;
  final String testo;
  final DateTime createdAt;
  final String mittenteNomeCompleto;

  GroupChatMessageModel({
    required this.id,
    required this.mittenteUserId,
    required this.puntoServizioId,
    required this.testo,
    required this.createdAt,
    required this.mittenteNomeCompleto,
  });

  factory GroupChatMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupChatMessageModel(
      id: json['id'] as int,
      mittenteUserId: json['mittente_user_id'] as int,
      puntoServizioId: json['punto_servizio_id'] as int,
      testo: json['testo'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      mittenteNomeCompleto: json['mittente_nome_completo'] as String? ?? 'Utente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mittente_user_id': mittenteUserId,
      'punto_servizio_id': puntoServizioId,
      'testo': testo,
      'created_at': createdAt.toUtc().toIso8601String(),
      'mittente_nome_completo': mittenteNomeCompleto,
    };
  }
}
