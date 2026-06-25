import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/remote_logger.dart';

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
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        // Ripristina il Bearer Token nell'ApiService
        final savedToken = userMap['api_token'] as String?;
        if (savedToken != null && savedToken.isNotEmpty) {
          await apiService.setToken(savedToken);
        }
        notifyListeners();
        _syncDeviceToken();
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

  Future<void> _syncDeviceToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          RemoteLogger.info('=== DEBUG NOTIFICHE: TOKEN OTTENUTO DA FIREBASE ===');
          await apiService.updateDeviceToken(token);
        } else {
          RemoteLogger.error('=== DEBUG NOTIFICHE: FIREBASE HA RESTITUITO UN TOKEN NULL! ===');
        }

        // Ascolta futuri refresh del token FCM (es. reinstall, update, clear data)
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          apiService.updateDeviceToken(newToken);
        });
      } else {
        RemoteLogger.warning('Permessi notifiche negati o non concessi.');
      }
    } catch (e) {
      RemoteLogger.error('Errore nel recupero del token FCM: $e');
    }
  }

  Future<bool> login(String companyCode, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Risolvi il codice azienda
      final serverUrl = await apiService.resolveCompanyCode(companyCode);
      if (serverUrl == null) {
        _errorMessage = 'Codice azienda non valido o non trovato.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // 2. Imposta l'indirizzo base
      await apiService.setBaseUrl(serverUrl);

      // 3. Esegui il login
      final response = await apiService.dio.post(
        'api/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        // Leggi il Bearer Token dalla risposta e salvalo in ApiService
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await apiService.setToken(token);
        }

        // Costruisci il modello utente (includi il token per la cache locale)
        final userMap = Map<String, dynamic>.from(
          data['user'] as Map<String, dynamic>,
        );
        if (token != null) userMap['api_token'] = token;
        _currentUser = UserModel.fromJson(userMap);
        await _persistUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        _syncDeviceToken();
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

  Future<bool> register(
    String companyCode,
    String nome,
    String cognome,
    String email,
    String password,
    String codiceFiscale,
    String dataNascita,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final serverUrl = await apiService.resolveCompanyCode(companyCode);
      if (serverUrl == null) {
        _errorMessage = 'Codice azienda non valido o non trovato.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await apiService.setBaseUrl(serverUrl);

      final response = await apiService.dio.post(
        'api/mobile/register',
        data: {
          'nome': nome,
          'cognome': cognome,
          'email': email,
          'password': password,
          'codice_fiscale': codiceFiscale,
          if (dataNascita.isNotEmpty) 'data_nascita': dataNascita,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] as String? ?? 'Errore durante la registrazione.';
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

      _errorMessage = serverMessage ?? 'Errore di connessione. Verifica i dati inseriti.';
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

  String? _privacyText;
  int? _privacyDocId;
  bool _isPrivacyLoaded = false;

  String? get privacyText => _privacyText;
  int? get privacyDocId => _privacyDocId;
  bool get isPrivacyLoaded => _isPrivacyLoaded;

  Future<void> fetchPrivacyInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/mobile/privacy');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _privacyText = data['testo'] as String?;
        _privacyDocId = data['documento_id'] as int?;
        _isPrivacyLoaded = true;
      } else {
        _errorMessage = data['message'] as String?;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Errore durante il caricamento della privacy.';
    } catch (_) {
      _errorMessage = 'Errore di connessione.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (!isAuthenticated) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.delete('api/user/account');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        await apiService.clearSession();
        await _clearPersistedUser();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] as String? ?? 'Impossibile eliminare l\'account.';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Errore durante l\'eliminazione.';
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
      // Cancella token Bearer e dati utente locali
      await apiService.clearSession();
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
