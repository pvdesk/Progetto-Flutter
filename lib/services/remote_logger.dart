import 'package:flutter/foundation.dart';
import 'api_service.dart';

class RemoteLogger {
  static final RemoteLogger _instance = RemoteLogger._internal();

  factory RemoteLogger() {
    return _instance;
  }

  RemoteLogger._internal();

  /// Invia un log al backend e lo stampa in locale
  static Future<void> log(String message, {String level = 'info', Map<String, dynamic>? context}) async {
    // 1. Stampa in console locale
    debugPrint('[$level] $message');

    // 2. Invia al backend in modalità "fire-and-forget"
    () async {
      try {
        final dio = ApiService().dio;
        await dio.post(
          'api/mobile/log',
          data: {
            'message': message,
            'level': level,
            'context': context ?? {},
          },
        );
      } catch (e) {
        debugPrint('Errore durante l\'invio del log remoto: $e');
      }
    }();
  }

  static Future<void> debug(String message, [Map<String, dynamic>? context]) => log(message, level: 'debug', context: context);
  static Future<void> info(String message, [Map<String, dynamic>? context]) => log(message, level: 'info', context: context);
  static Future<void> warning(String message, [Map<String, dynamic>? context]) => log(message, level: 'warning', context: context);
  static Future<void> error(String message, [Map<String, dynamic>? context]) => log(message, level: 'error', context: context);
  static Future<void> critical(String message, [Map<String, dynamic>? context]) => log(message, level: 'critical', context: context);
}
