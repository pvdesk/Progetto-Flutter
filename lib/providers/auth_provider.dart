import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get hasAcceptedPrivacy => _currentUser?.privacyAccettata ?? false;

  AuthProvider(this.apiService) {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      // Ignora errori di caricamento cache
    }
  }

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  Future<void> _clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.post(
        'api/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final userMap = data['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        await _persistUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] as String? ?? 'Credenziali non valide.';
      }
    } on DioException catch (e) {
      String? serverMessage;
      try {
        if (e.response != null && e.response?.data != null) {
          final rawData = e.response!.data;
          Map<String, dynamic>? data;
          if (rawData is Map) {
            data = rawData as Map<String, dynamic>;
          } else if (rawData is String) {
            final decoded = jsonDecode(rawData);
            if (decoded is Map) {
              data = decoded as Map<String, dynamic>;
            }
          }
          if (data != null) {
            serverMessage = data['message'] as String?;
          }
        }
      } catch (_) {}

      _errorMessage = serverMessage ?? 'Errore di connessione. Verifica il server.';
    } catch (e) {
      _errorMessage = 'Si è verificato un errore imprevisto.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> acceptPrivacy() async {
    if (!isAuthenticated) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.post('api/chat/accept-privacy');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(privacyAccettata: true);
          await _persistUser(_currentUser!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] as String? ?? 'Impossibile accettare i termini.';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Errore durante l\'accettazione.';
    } catch (_) {
      _errorMessage = 'Errore di connessione.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Rimuovi cookie e utente locale
      await apiService.clearCookies();
      await _clearPersistedUser();
      _currentUser = null;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
