import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ConfigProvider extends ChangeNotifier {
  final ApiService _apiService;

  String? internalLogoUrl;
  String? squareIconUrl;

  ConfigProvider(this._apiService) {
    _loadFromPrefs();
    fetchConfigFromApi();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    internalLogoUrl = prefs.getString('mobile_internal_logo_url');
    squareIconUrl = prefs.getString('mobile_square_icon_url');
    notifyListeners();
  }

  Future<void> fetchConfigFromApi() async {
    try {
      final response = await _apiService.dio.get('/api/mobile/config');
      final data = response.data;
      if (data != null) {
        internalLogoUrl = data['internal_logo_url'];
        squareIconUrl = data['square_icon_url'];

        final prefs = await SharedPreferences.getInstance();
        if (internalLogoUrl != null) {
          await prefs.setString('mobile_internal_logo_url', internalLogoUrl!);
        } else {
          await prefs.remove('mobile_internal_logo_url');
        }

        if (squareIconUrl != null) {
          await prefs.setString('mobile_square_icon_url', squareIconUrl!);
        } else {
          await prefs.remove('mobile_square_icon_url');
        }

        notifyListeners();
      }
    } catch (e) {
      // API fail: fail silently and keep cached/fallback values
    }
  }
}
