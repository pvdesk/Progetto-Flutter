class NotificationData {
  final int count;
  final List<NotificaModel> notifiche;
  final List<ComunicazioneModel> comunicazioni;

  NotificationData({
    required this.count,
    required this.notifiche,
    required this.comunicazioni,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      count: json['count'] as int? ?? 0,
      notifiche: (json['notifiche'] as List<dynamic>?)
              ?.map((e) => NotificaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comunicazioni: (json['comunicazioni'] as List<dynamic>?)
              ?.map((e) => ComunicazioneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class NotificaModel {
  final int id;
  final String testo;
  final String? scadeIl;
  final String? createdAt;
  bool isRead; // Gestito localmente o rimossa dalla lista se letta

  NotificaModel({
    required this.id,
    required this.testo,
    this.scadeIl,
    this.createdAt,
    this.isRead = false,
  });

  factory NotificaModel.fromJson(Map<String, dynamic> json) {
    return NotificaModel(
      id: json['id'] as int,
      testo: json['testo'] as String? ?? '',
      scadeIl: json['scade_il'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ComunicazioneModel {
  final int id;
  final String titolo;
  final String testo;
  final String? creatoDa;
  final String? pubblicataAt;
  bool isRead; // Gestito localmente o rimossa dalla lista se letta

  ComunicazioneModel({
    required this.id,
    required this.titolo,
    required this.testo,
    this.creatoDa,
    this.pubblicataAt,
    this.isRead = false,
  });

  factory ComunicazioneModel.fromJson(Map<String, dynamic> json) {
    return ComunicazioneModel(
      id: json['id'] as int,
      titolo: json['titolo'] as String? ?? '',
      testo: json['testo'] as String? ?? '',
      creatoDa: json['creato_da'] as String?,
      pubblicataAt: json['pubblicata_at'] as String?,
    );
  }
}
