class GroupChatMessageModel {
  final int id;
  final int mittenteUserId;
  // Nullable: nelle stanze "costi generali" (cg/cg_all) e "area" il messaggio NON ha
  // un punto servizio. Va quindi gestito come opzionale, altrimenti il parsing esplode
  // (null as int) e i messaggi spariscono in quelle stanze.
  final int? puntoServizioId;
  final int? costoGeneraleId;
  final String? area;
  final String? roomId;
  final String testo;
  final DateTime createdAt;
  final String mittenteNomeCompleto;

  GroupChatMessageModel({
    required this.id,
    required this.mittenteUserId,
    this.puntoServizioId,
    this.costoGeneraleId,
    this.area,
    this.roomId,
    required this.testo,
    required this.createdAt,
    required this.mittenteNomeCompleto,
  });

  factory GroupChatMessageModel.fromJson(Map<String, dynamic> json) {
    int? toIntOrNull(dynamic v) => v == null ? null : (v as num).toInt();
    return GroupChatMessageModel(
      id: (json['id'] as num).toInt(),
      mittenteUserId: (json['mittente_user_id'] as num).toInt(),
      puntoServizioId: toIntOrNull(json['punto_servizio_id']),
      costoGeneraleId: toIntOrNull(json['costo_generale_id']),
      area: json['area'] as String?,
      roomId: json['room_id'] as String?,
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
      'costo_generale_id': costoGeneraleId,
      'area': area,
      'room_id': roomId,
      'testo': testo,
      'created_at': createdAt.toUtc().toIso8601String(),
      'mittente_nome_completo': mittenteNomeCompleto,
    };
  }
}
