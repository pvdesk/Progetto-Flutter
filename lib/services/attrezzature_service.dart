import 'dart:io';
import 'package:dio/dio.dart';
import '../models/attrezzatura_model.dart';
import '../models/tipo_attrezzatura_model.dart';
import 'api_service.dart';
import 'remote_logger.dart';

class AttrezzatureService {
  final ApiService _apiService;

  AttrezzatureService(this._apiService);

  /// Esegue la scansione di un codice a barre o QR
  Future<Attrezzatura?> scanAttrezzatura(String code) async {
    try {
      final response = await _apiService.dio.get('${_apiService.baseUrl}/api/attrezzature/scan/$code');
      if (response.data['success'] == true) {
        return Attrezzatura.fromJson(response.data['attrezzatura']);
      }
      return null;
    } catch (e) {
      RemoteLogger.error('Errore in scanAttrezzatura: $e');
      return null;
    }
  }

  /// Salva la mappatura dell'attrezzatura su commessa o centro cottura
  Future<bool> mappaAttrezzatura(String code, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        '${_apiService.baseUrl}/api/attrezzature/scan/$code/mappa',
        data: data,
      );
      return response.data['success'] == true;
    } catch (e) {
      RemoteLogger.error('Errore in mappaAttrezzatura: $e');
      return false;
    }
  }

  /// Registra un intervento di manutenzione interna (con allegato opzionale)
  Future<bool> registraIntervento({
    required String code,
    required String dataIntervento,
    required String descrizione,
    double? costo,
    File? documento,
  }) async {
    try {
      MultipartFile? fileData;
      if (documento != null) {
        final fileName = documento.path.split('/').last;
        fileData = await MultipartFile.fromFile(
          documento.path,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'data_interv_format': dataIntervento,
        'data_intervento': dataIntervento,
        'descrizione': descrizione,
        'costo': costo,
        if (fileData != null) 'documento': fileData,
      });

      final response = await _apiService.dio.post(
        '${_apiService.baseUrl}/api/attrezzature/scan/$code/intervento',
        data: formData,
      );
      return response.data['success'] == true;
    } catch (e) {
      RemoteLogger.error('Errore in registraIntervento: $e');
      return false;
    }
  }

  /// Recupera le liste necessarie per la mappatura (tipologie, commesse, centri)
  Future<Map<String, dynamic>?> fetchListeMappatura() async {
    try {
      final response = await _apiService.dio.get('${_apiService.baseUrl}/api/attrezzature/liste-mappatura');
      if (response.data['success'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      RemoteLogger.error('Errore in fetchListeMappatura: $e');
      return null;
    }
  }
}
