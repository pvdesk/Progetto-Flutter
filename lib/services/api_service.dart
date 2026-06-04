import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  // Configurazione di default (10.0.2.2 è l'alias per localhost dell'host da emulatore Android)
  static const String defaultBaseUrl = 'http://localhost:8000';

  late final Dio dio;
  late final CookieJar cookieJar;
  String _baseUrl = defaultBaseUrl;

  ApiService() {
    dio = Dio();
    
    // CookieManager non deve essere usato in ambienti Web perché i browser gestiscono i cookie nativamente.
    if (!kIsWeb) {
      cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));
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
  }

  static const String appVersion = '1.0.0';

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

    // Se l'indirizzo contiene la sottocartella /app_gestione ma non contiene /public, lo aggiungiamo noi
    if (trimmed.contains('/app_gestione') && !trimmed.contains('/public')) {
      if (trimmed.endsWith('/')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
      trimmed = '$trimmed/public';
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
}
