import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ThemeProvider extends ChangeNotifier {
  final ApiService _apiService;

  String appName = 'INTHEGRA';
  Color primaryColor = const Color(0xFFFF6B35);
  Color secondaryColor = const Color(0xFFFF8C61);
  Color headerBgColor = const Color(0xFF1E293B);
  Color headerTextColor = const Color(0xFFFFFFFF);
  String? logoUrl;

  ThemeProvider(this._apiService) {
    _loadFromPrefs();
    _fetchThemeFromApi();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    appName = prefs.getString('theme_app_name') ?? appName;
    
    final primaryHex = prefs.getString('theme_primary_color');
    if (primaryHex != null) primaryColor = _hexToColor(primaryHex) ?? primaryColor;

    final secondaryHex = prefs.getString('theme_secondary_color');
    if (secondaryHex != null) secondaryColor = _hexToColor(secondaryHex) ?? secondaryColor;

    final headerBgHex = prefs.getString('theme_header_bg');
    if (headerBgHex != null) headerBgColor = _hexToColor(headerBgHex) ?? headerBgColor;

    final headerTextHex = prefs.getString('theme_header_text');
    if (headerTextHex != null) headerTextColor = _hexToColor(headerTextHex) ?? headerTextColor;

    logoUrl = prefs.getString('theme_logo_url');
    notifyListeners();
  }

  Future<void> _fetchThemeFromApi() async {
    try {
      final response = await _apiService.dio.get('/api/theme');
      final data = response.data;
      if (data != null && data['success'] == true) {
        final theme = data['theme'];
        appName = theme['app_name'] ?? appName;
        primaryColor = _hexToColor(theme['primary_color']) ?? primaryColor;
        secondaryColor = _hexToColor(theme['secondary_color']) ?? secondaryColor;
        headerBgColor = _hexToColor(theme['header_bg']) ?? headerBgColor;
        headerTextColor = _hexToColor(theme['header_text']) ?? headerTextColor;
        logoUrl = theme['logo_url'];

        // Save to prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme_app_name', appName);
        await prefs.setString('theme_primary_color', theme['primary_color']);
        await prefs.setString('theme_secondary_color', theme['secondary_color']);
        await prefs.setString('theme_header_bg', theme['header_bg']);
        await prefs.setString('theme_header_text', theme['header_text']);
        if (logoUrl != null) {
          await prefs.setString('theme_logo_url', logoUrl!);
        } else {
          await prefs.remove('theme_logo_url');
        }

        notifyListeners();
      }
    } catch (e) {
      // API fail: do nothing, fallback to prefs
    }
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
