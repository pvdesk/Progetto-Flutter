class MessageModel {
  final int id;
  final int mittenteUserId;
  final int destinatarioUserId;
  final String testo;
  final DateTime? lettaAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.mittenteUserId,
    required this.destinatarioUserId,
    required this.testo,
    this.lettaAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      mittenteUserId: json['mittente_user_id'] as int,
      destinatarioUserId: json['destinatario_user_id'] as int,
      testo: json['testo'] as String? ?? '',
      lettaAt: json['letta_at'] != null ? DateTime.tryParse(json['letta_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mittente_user_id': mittenteUserId,
      'destinatario_user_id': destinatarioUserId,
      'testo': testo,
      'letta_at': lettaAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isRead => lettaAt != null;
}
