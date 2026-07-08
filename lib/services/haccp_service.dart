import 'package:dio/dio.dart';
import 'dart:convert';
import 'api_service.dart';
import 'remote_logger.dart';

class HaccpService {
  final ApiService _apiService;

  HaccpService(this._apiService);

  /// Recupera la lista dei documenti HACCP da firmare per l'utente corrente
  Future<List<dynamic>> getFirmeDaApporre() async {
    try {
      final response = await _apiService.dio.get('api/mobile/haccp/firme-da-apporre');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } on DioException catch (e) {
      RemoteLogger.error('Errore getFirmeDaApporre: ${e.message}');
    } catch (e) {
      RemoteLogger.error('Errore parsing getFirmeDaApporre: $e');
    }
    return [];
  }

  /// Invia la firma (PNG base64) per uno o più documenti/giorni
  Future<Map<String, dynamic>> salvaFirma(List<Map<String, dynamic>> selezione, String base64Signature, String deviceInfo) async {
    try {
      final response = await _apiService.dio.post(
        'api/mobile/haccp/firma',
        data: {
          'selezione': selezione,
          'firma': base64Signature,
          'device': deviceInfo,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      RemoteLogger.error('Errore salvaFirma: ${e.message}');
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
    } catch (e) {
      RemoteLogger.error('Errore generico salvaFirma: $e');
    }
    return {'success': false, 'message': 'Errore sconosciuto durante il salvataggio della firma.'};
  }
}
