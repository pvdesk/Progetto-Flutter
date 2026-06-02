import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/contact_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService apiService;
  
  List<ContactModel> _contacts = [];
  List<MessageModel> _messages = [];
  int _unreadCount = 0;
  bool _isLoadingContacts = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;
  
  ContactModel? _activeContact;
  Timer? _pollingTimer;

  List<ContactModel> get contacts => _contacts;
  List<MessageModel> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  ContactModel? get activeContact => _activeContact;

  ChatProvider(this.apiService);

  // Carica i contatti abilitati
  Future<void> fetchContacts() async {
    _isLoadingContacts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('/api/chat/contacts');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['contacts'] as List<dynamic>;
        _contacts = list.map((c) => ContactModel.fromJson(c as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = data['message'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _errorMessage = 'Privacy non accettata';
      } else {
        _errorMessage = 'Errore di rete durante il caricamento dei contatti.';
      }
    } catch (_) {
      _errorMessage = 'Impossibile caricare i contatti.';
    }

    _isLoadingContacts = false;
    notifyListeners();
  }

  // Carica messaggi per un contatto specifico
  Future<void> fetchMessages(int contactId) async {
    _isLoadingMessages = true;
    _errorMessage = null;
    // Non cancelliamo i messaggi precedenti se stiamo caricando lo stesso contatto per evitare flickering
    if (_activeContact?.id != contactId) {
      _messages = [];
    }
    notifyListeners();

    try {
      final response = await apiService.dio.get('/api/chat/messages/$contactId');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['messages'] as List<dynamic>;
        _messages = list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = data['message'] as String?;
      }
    } catch (_) {
      _errorMessage = 'Impossibile recuperare i messaggi.';
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Invia un messaggio
  Future<bool> sendMessage(int contactId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final response = await apiService.dio.post(
        '/api/chat/messages',
        data: {
          'destinatario_user_id': contactId,
          'testo': text,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final newMsg = MessageModel.fromJson(data['message'] as Map<String, dynamic>);
        _messages.add(newMsg);
        
        // Riordina la lista contatti per portare in alto l'ultimo contattato (opzionale)
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Gestisci errore invio
    }
    return false;
  }

  // Carica contatore messaggi non letti globali
  Future<void> fetchUnreadCount() async {
    try {
      final response = await apiService.dio.get('/api/chat/unread-count');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _unreadCount = data['unread_count'] as int? ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Inizia polling per aggiornare la chat attiva in tempo reale
  void startPolling(ContactModel contact) {
    stopPolling();
    _activeContact = contact;
    fetchMessages(contact.id);
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeContact != null) {
        // Aggiorna silenziosamente i messaggi
        try {
          final response = await apiService.dio.get('/api/chat/messages/${_activeContact!.id}');
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final list = data['messages'] as List<dynamic>;
            final newMessages = list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
            
            // Aggiorna solo se la lunghezza o il contenuto cambiano
            if (newMessages.length != _messages.length || 
                (newMessages.isNotEmpty && _messages.isNotEmpty && newMessages.last.id != _messages.last.id)) {
              _messages = newMessages;
              notifyListeners();
            }
          }
        } catch (_) {}
      }
    });
  }

  // Ferma polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _activeContact = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
