import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'dart:convert';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  // Configurazione di default (modificabile dalla schermata di login)
  static String get defaultBaseUrl => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';

  // URL del file JSON centrale con la mappatura CodiceAzienda -> ServerURL
  static const String masterConfigUrl = 'https://www.inthegra.it/app_gestione/public/app_clients.json';

  late final Dio dio;
  late final PersistCookieJar cookieJar;
  String _baseUrl = defaultBaseUrl;

  ApiService() {
    dio = Dio();
    
    // CookieManager non deve essere usato in ambienti Web perché i browser gestiscono i cookie nativamente.
    if (!kIsWeb) {
      // FIX SSL CHAIN ISSUE: ignora gli errori del certificato su device fisici
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    } else {
      // Configurazione Web per abilitare l'invio e la ricezione automatica dei Cookie/Sessioni
      dio.options.extra['withCredentials'] = true;
    }
    
    // Configura timeout e impostazioni di default
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers = {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  Future<void> init() async {
    await _initBaseUrl();
    await _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    if (!kIsWeb) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final String cookiePath = '${appDocDir.path}/.cookies/';
      final dir = Directory(cookiePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      cookieJar = PersistCookieJar(
        storage: FileStorage(cookiePath),
      );
      dio.interceptors.add(CookieManager(cookieJar));
    }
  }

  String get baseUrl => _baseUrl;

  String _normalizeUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Forza lo schema http/https se mancante
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('localhost') || trimmed.startsWith('127.0.0.1') || trimmed.startsWith('192.168.')) {
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

  Future<void> clearCookies() async {
    if (!kIsWeb) {
      await cookieJar.deleteAll();
    }
  }

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
      throw Exception('Impossibile contattare il server di configurazione. Controlla la tua connessione.');
    }
    return null; // Codice non trovato
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      await dio.post('api/user/device-token', data: {'token': token});
    } catch (e) {
      debugPrint('Errore durante l\'aggiornamento del device token: $e');
    }
  }
}
