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
    
    _initBaseUrl();
  }

  String get baseUrl => _baseUrl;

  Future<void> _initBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
      dio.options.baseUrl = _baseUrl;
    } catch (e) {
      _baseUrl = defaultBaseUrl;
      dio.options.baseUrl = defaultBaseUrl;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl;
    dio.options.baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
  }

  Future<void> clearCookies() async {
    if (!kIsWeb) {
      await cookieJar.deleteAll();
    }
  }
}
