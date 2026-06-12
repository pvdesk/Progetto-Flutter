import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService apiService;

  NotificationData? _notificationData;
  bool _isLoading = false;
  String? _errorMessage;

  NotificationData? get notificationData => _notificationData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notificationData?.count ?? 0;
  List<NotificaModel> get notifiche => _notificationData?.notifiche ?? [];
  List<ComunicazioneModel> get comunicazioni => _notificationData?.comunicazioni ?? [];

  NotificationProvider(this.apiService);

  Future<void> fetchUnread() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/mobile/notifiche/unread');
      final data = response.data as Map<String, dynamic>;
      
      _notificationData = NotificationData.fromJson(data);
    } on DioException catch (e) {
      _errorMessage = 'Errore di rete durante il caricamento delle notifiche.';
    } catch (_) {
      _errorMessage = 'Impossibile caricare le notifiche.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markNotificaAsRead(int notificaId) async {
    try {
      final response = await apiService.dio.post('api/mobile/notifiche/$notificaId/read');
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        // Rimuovi o aggiorna localmente
        if (_notificationData != null) {
          _notificationData!.notifiche.removeWhere((n) => n.id == notificaId);
          await fetchUnread(); // Aggiorna i conteggi totali dal server, oppure aggiorna il conteggio localmente
          return true;
        }
      }
    } catch (_) {
      // Gestione errori ignorata o loggata
    }
    return false;
  }

  Future<bool> markComunicazioneAsRead(int comunicazioneId) async {
    try {
      final response = await apiService.dio.post('api/mobile/comunicazioni/$comunicazioneId/read');
      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        // Rimuovi o aggiorna localmente
        if (_notificationData != null) {
          _notificationData!.comunicazioni.removeWhere((c) => c.id == comunicazioneId);
          await fetchUnread(); // Ricarica dal server
          return true;
        }
      }
    } catch (_) {
      // Gestione errori
    }
    return false;
  }
}
