import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/contact_model.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';
import '../models/group_chat_message_model.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService apiService;
  
  List<ContactModel> _contacts = [];
  List<MessageModel> _messages = [];
  List<RoomModel> _rooms = [];
  List<GroupChatMessageModel> _roomMessages = [];
  int _unreadCount = 0;
  bool _isLoadingContacts = false;
  bool _isLoadingMessages = false;
  bool _isLoadingRooms = false;
  String? _contactsError;
  String? _roomsError;
  String? _messagesError;
  
  ContactModel? _activeContact;
  RoomModel? _activeRoom;
  Timer? _pollingTimer;
  Timer? _roomPollingTimer;

  List<ContactModel> get contacts => _contacts;
  List<MessageModel> get messages => _messages;
  List<RoomModel> get rooms => _rooms;
  List<GroupChatMessageModel> get roomMessages => _roomMessages;
  int get unreadCount => _unreadCount;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get contactsError => _contactsError;
  String? get roomsError => _roomsError;
  String? get messagesError => _messagesError;
  ContactModel? get activeContact => _activeContact;
  RoomModel? get activeRoom => _activeRoom;

  ChatProvider(this.apiService);

  // Carica i contatti abilitati
  Future<void> fetchContacts() async {
    _isLoadingContacts = true;
    _contactsError = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/chat/contacts');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['contacts'] as List<dynamic>;
        _contacts = list.map((c) => ContactModel.fromJson(c as Map<String, dynamic>)).toList();
      } else {
        _contactsError = data['message'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _contactsError = 'Privacy non accettata';
      } else {
        _contactsError = 'Errore di rete durante il caricamento dei contatti.';
      }
    } catch (_) {
      _contactsError = 'Impossibile caricare i contatti.';
    }

    _isLoadingContacts = false;
    notifyListeners();
  }

  // Carica le stanze (Punti di Servizio) abilitate
  Future<void> fetchRooms() async {
    _isLoadingRooms = true;
    _roomsError = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/chat/rooms');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['rooms'] as List<dynamic>;
        _rooms = list.map((r) => RoomModel.fromJson(r as Map<String, dynamic>)).toList();
      } else {
        _roomsError = data['message'] as String?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _roomsError = 'Privacy non accettata';
      } else {
        _roomsError = 'Errore di rete durante il caricamento delle stanze.';
      }
    } catch (_) {
      _roomsError = 'Impossibile caricare le stanze.';
    }

    _isLoadingRooms = false;
    notifyListeners();
  }

  // Carica messaggi per un contatto specifico
  Future<void> fetchMessages(int contactId) async {
    _isLoadingMessages = true;
    _messagesError = null;
    // Non cancelliamo i messaggi precedenti se stiamo caricando lo stesso contatto per evitare flickering
    if (_activeContact?.id != contactId) {
      _messages = [];
    }
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/chat/messages/$contactId');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['messages'] as List<dynamic>;
        _messages = list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
      } else {
        _messagesError = data['message'] as String?;
      }
    } catch (_) {
      _messagesError = 'Impossibile recuperare i messaggi.';
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Carica messaggi per una stanza specifica
  Future<void> fetchRoomMessages(String roomId) async {
    _isLoadingMessages = true;
    _messagesError = null;
    if (_activeRoom?.id != roomId) {
      _roomMessages = [];
    }
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/chat/rooms/$roomId/messages');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['messages'] as List<dynamic>;
        _roomMessages = list.map((m) => GroupChatMessageModel.fromJson(m as Map<String, dynamic>)).toList();
      } else {
        _messagesError = data['message'] as String?;
      }
    } catch (_) {
      _messagesError = 'Impossibile recuperare i messaggi del gruppo.';
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Invia un messaggio
  Future<bool> sendMessage(int contactId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final response = await apiService.dio.post(
        'api/chat/messages',
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

  // Invia un messaggio ad una stanza
  Future<bool> sendRoomMessage(int roomId, String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final response = await apiService.dio.post(
        'api/chat/rooms/messages',
        data: {
          'punto_servizio_id': roomId,
          'testo': text,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final newMsg = GroupChatMessageModel.fromJson(data['message'] as Map<String, dynamic>);
        _roomMessages.add(newMsg);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Carica contatore messaggi non letti globali
  Future<void> fetchUnreadCount() async {
    try {
      final response = await apiService.dio.get('api/chat/unread-count');
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
          final response = await apiService.dio.get('api/chat/messages/${_activeContact!.id}');
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

  // Ferma polling chat singola
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _activeContact = null;
  }

  // Inizia polling per aggiornare la stanza attiva in tempo reale
  void startRoomPolling(RoomModel room) {
    stopRoomPolling();
    _activeRoom = room;
    fetchRoomMessages(room.id);
    
    _roomPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeRoom != null) {
        try {
          final response = await apiService.dio.get('api/chat/rooms/${_activeRoom!.id}/messages');
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final list = data['messages'] as List<dynamic>;
            final newMessages = list.map((m) => GroupChatMessageModel.fromJson(m as Map<String, dynamic>)).toList();
            
            if (newMessages.length != _roomMessages.length || 
                (newMessages.isNotEmpty && _roomMessages.isNotEmpty && newMessages.last.id != _roomMessages.last.id)) {
              _roomMessages = newMessages;
              notifyListeners();
            }
          }
        } catch (_) {}
      }
    });
  }

  // Ferma polling stanza
  void stopRoomPolling() {
    _roomPollingTimer?.cancel();
    _roomPollingTimer = null;
    _activeRoom = null;
  }

  @override
  void dispose() {
    stopPolling();
    stopRoomPolling();
    super.dispose();
  }
}
