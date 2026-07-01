import 'package:flutter/material.dart';
import '../models/automezzo_model.dart';
import '../services/automezzi_service.dart';

class AutomezziProvider extends ChangeNotifier {
  final AutomezziService _service;

  List<Automezzo> _automezzi = [];
  bool _isLoading = false;
  String? _errorMessage;

  AutomezziProvider(this._service);

  List<Automezzo> get automezzi => _automezzi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAutomezzi() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _automezzi = await _service.fetchAutomezzi();
    } catch (e) {
      _errorMessage = "Errore durante il caricamento degli automezzi.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerIntervento(int id, String data, String descrizione, double? costo) async {
    final success = await _service.registerIntervento(id, data, descrizione, costo);
    if (success) {
      await fetchAutomezzi();
    }
    return success;
  }

  Future<bool> updateScadenze(int id, Map<String, dynamic> data) async {
    final success = await _service.updateScadenze(id, data);
    if (success) {
      await fetchAutomezzi();
    }
    return success;
  }
}
