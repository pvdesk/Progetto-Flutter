import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attrezzatura_model.dart';
import '../models/tipo_attrezzatura_model.dart';
import '../services/attrezzature_service.dart';

class AttrezzatureProvider extends ChangeNotifier {
  final AttrezzatureService _service;

  Attrezzatura? _scannedAttrezzatura;
  bool _isLoading = false;
  String? _errorMessage;

  // Liste di supporto per la mappatura
  List<TipoAttrezzatura> _tipi = [];
  List<dynamic> _commesse = [];
  List<dynamic> _puntiServizio = [];
  List<dynamic> _centriCottura = [];

  AttrezzatureProvider(this._service);

  // Getter
  Attrezzatura? get scannedAttrezzatura => _scannedAttrezzatura;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TipoAttrezzatura> get tipi => _tipi;
  List<dynamic> get commesse => _commesse;
  List<dynamic> get puntiServizio => _puntiServizio;
  List<dynamic> get centriCottura => _centriCottura;

  /// Esegue la scansione e salva l'attrezzatura nello stato
  Future<Attrezzatura?> scanCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    _scannedAttrezzatura = null;
    notifyListeners();

    try {
      final result = await _service.scanAttrezzatura(code);
      if (result != null) {
        _scannedAttrezzatura = result;
      } else {
        _errorMessage = 'Attrezzatura non trovata.';
      }
      return result;
    } catch (e) {
      _errorMessage = 'Errore durante la scansione.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pulisce lo stato della scansione corrente
  void clearScanned() {
    _scannedAttrezzatura = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mappa l'attrezzatura corrente
  Future<bool> mappa(String code, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.mappaAttrezzatura(code, data);
      if (success) {
        // Ricarica l'attrezzatura per aggiornare la visualizzazione
        await scanCode(code);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Errore durante la mappatura.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un intervento interno da mobile
  Future<bool> registraIntervento({
    required String code,
    required String dataIntervento,
    required String descrizione,
    double? costo,
    File? documento,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.registraIntervento(
        code: code,
        dataIntervento: dataIntervento,
        descrizione: descrizione,
        costo: costo,
        documento: documento,
      );
      if (success) {
        // Ricarica per visualizzare il nuovo intervento nello storico
        await scanCode(code);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Errore durante il salvataggio dell\'intervento.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carica le liste per compilare la mappatura
  Future<void> fetchMappaturaLists() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _service.fetchListeMappatura();
      if (res != null) {
        final List tipiList = res['tipi_attrezzatura'] ?? [];
        _tipi = tipiList.map((e) => TipoAttrezzatura.fromJson(e)).toList();
        
        _commesse = res['commesse'] ?? [];
        _puntiServizio = res['punti_servizio'] ?? [];
        _centriCottura = res['centri_cottura'] ?? [];
      }
    } catch (e) {
      _errorMessage = 'Errore caricamento liste di supporto.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
