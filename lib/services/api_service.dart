import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'dart:convert';

class ApiService {
  static const String _baseUrlKey   = 'api_base_url';
  static const String _tokenKey     = 'api_bearer_token';

  // URL di default (modificabile dalla schermata di login)
  static String get defaultBaseUrl => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';

  // URL del file JSON centrale con la mappatura CodiceAzienda -> ServerURL
  static const String masterConfigUrl =
      'https://www.inthegra.it/app_gestione/public/app_clients.json';

  late final Dio dio;
  String _baseUrl = defaultBaseUrl;
  String? _bearerToken;

  ApiService() {
    dio = Dio();

    if (!kIsWeb) {
      // FIX SSL CHAIN: ignora errori certificato su device fisici
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    // Timeout e header di default
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers = {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };

    // Interceptor che aggiunge automaticamente il Bearer Token ad ogni richiesta
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_bearerToken != null && _bearerToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_bearerToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> init() async {
    await _initBaseUrl();
    await _loadToken();
  }

  String get baseUrl => _baseUrl;
  String? get bearerToken => _bearerToken;
  bool get hasToken => _bearerToken != null && _bearerToken!.isNotEmpty;

  // ── Token management ──────────────────────────────────────────────────────

  /// Imposta il Bearer Token e lo persiste in SharedPreferences
  Future<void> setToken(String token) async {
    _bearerToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Carica il token salvato (chiamato a init)
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bearerToken = prefs.getString(_tokenKey);
    } catch (_) {}
  }

  /// Cancella il token (logout)
  Future<void> clearToken() async {
    _bearerToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Base URL management ───────────────────────────────────────────────────

  String _normalizeUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('localhost') ||
          trimmed.startsWith('127.0.0.1') ||
          trimmed.startsWith('192.168.')) {
        trimmed = 'http://$trimmed';
      } else {
        trimmed = 'https://$trimmed';
      }
    }

    if (!trimmed.endsWith('/')) {
      trimmed = '$trimmed/';
    }
    return trimmed;
  }

  Future<void> _initBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
      _baseUrl = _normalizeUrl(storedUrl);
      dio.options.baseUrl = _baseUrl;
    } catch (e) {
      _baseUrl = _normalizeUrl(defaultBaseUrl);
      dio.options.baseUrl = _baseUrl;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    final normalized = _normalizeUrl(newUrl);
    _baseUrl = normalized;
    dio.options.baseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> checkAppUpdate() async {
    try {
      final response = await dio.get('api/mobile/version');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Ignora errori di connessione per il controllo versione
    }
    return null;
  }

  /// Risolve un CodiceAzienda nel server URL corrispondente
  Future<String?> resolveCompanyCode(String code) async {
    try {
      final tempDio = Dio();
      final response = await tempDio.get(masterConfigUrl);

      Map<String, dynamic> config = {};

      if (response.data is Map<String, dynamic>) {
        config = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data);
        if (decoded is Map<String, dynamic>) {
          config = decoded;
        }
      } else {
        return null;
      }

      final serverUrl = config[code.trim().toUpperCase()];
      if (serverUrl != null && serverUrl is String) {
        return serverUrl;
      }
    } catch (e) {
      throw Exception(
          'Impossibile contattare il server di configurazione. Controlla la tua connessione.');
    }
    return null; // Codice non trovato
  }

  /// Aggiorna il device token FCM sul server
  Future<void> updateDeviceToken(String fcmToken) async {
    try {
      await dio.post('api/user/device-token', data: {'token': fcmToken});
      
      // TODO: DEBUG NOTIFICHE - Da rimuovere una volta risolto il problema
      debugPrint('===========================================================');
      debugPrint('=== DEBUG NOTIFICHE: TOKEN SALVATO CON SUCCESSO SUL SERVER ===');
      debugPrint('Token: $fcmToken');
      debugPrint('===========================================================');
      
    } catch (e) {
      debugPrint("Errore durante l'aggiornamento del device token: $e");
      
      // TODO: DEBUG NOTIFICHE - Da rimuovere una volta risolto il problema
      debugPrint('===========================================================');
      debugPrint('=== DEBUG NOTIFICHE: ERRORE API SERVER DURANTE SALVATAGGIO TOKEN ===');
      if (e is DioException) {
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Dati Risposta: ${e.response?.data}');
      } else {
        debugPrint('Dettaglio: $e');
      }
      debugPrint('===========================================================');
    }
  }

  /// Pulizia completa (logout): token + cookie
  Future<void> clearSession() async {
    await clearToken();
  }
}
