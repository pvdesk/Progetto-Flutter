import 'package:dio/dio.dart';
import '../models/automezzo_model.dart';
import 'api_service.dart';
import 'remote_logger.dart';

class AutomezziService {
  final ApiService _apiService;

  AutomezziService(this._apiService);

  Future<List<Automezzo>> fetchAutomezzi() async {
    try {
      final response = await _apiService.dio.get('${_apiService.baseUrl}/api/automezzi');
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => Automezzo.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      RemoteLogger.error('Errore nel fetchAutomezzi: $e');
      return [];
    }
  }

  Future<bool> registerIntervento(int automezzoId, String data, String descrizione, double? costo) async {
    try {
      final response = await _apiService.dio.post('${_apiService.baseUrl}/api/automezzi/$automezzoId/interventi', data: {
        'data_intervento': data,
        'descrizione': descrizione,
        'costo': costo,
      });
      return response.data['success'] == true;
    } catch (e) {
      RemoteLogger.error('Errore nel registerIntervento: $e');
      return false;
    }
  }

  Future<bool> updateScadenze(int automezzoId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('${_apiService.baseUrl}/api/automezzi/$automezzoId', data: data);
      return response.data['success'] == true;
    } catch (e) {
      RemoteLogger.error('Errore in updateScadenze: $e');
      return false;
    }
  }
}
