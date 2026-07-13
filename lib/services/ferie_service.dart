import 'package:dio/dio.dart';
import 'api_service.dart';

class FerieService {
  final ApiService apiService;

  FerieService(this.apiService);

  Future<List<dynamic>> fetchStoricoFerie({bool archivio = false}) async {
    try {
      final response = await apiService.dio.get(
        '/api/ferie',
        queryParameters: {'archivio': archivio ? 1 : 0},
      );
      final data = response.data;
      if (data is Map && data['data'] is List) return data['data'];
      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? (body['detail'] ?? body['error']) : body;
      throw Exception('Errore nel recupero dello storico ferie: ${detail ?? e.message}');
    } catch (e) {
      throw Exception('Errore nel recupero dello storico ferie: $e');
    }
  }

  Future<Map<String, dynamic>> richiediFerie(List<Map<String, String>> periodi, String note) async {
    try {
      final response = await apiService.dio.post(
        '/api/ferie',
        data: {
          'periodi': periodi,
          'note': note,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? (body['detail'] ?? body['error']) : null;
      throw Exception('Errore: ${detail ?? e.message}');
    } catch (e) {
      throw Exception('Errore durante la richiesta ferie: $e');
    }
  }

  Future<void> verificaOtp(int richiestaId, {String? otp, String? signatureBase64, String? deviceInfo}) async {
    try {
      final Map<String, dynamic> data = {};
      if (otp != null && otp.isNotEmpty) data['otp'] = otp;
      if (signatureBase64 != null) data['signature_base64'] = signatureBase64;
      if (deviceInfo != null) data['device_info'] = deviceInfo;

      await apiService.dio.post(
        '/api/ferie/$richiestaId/verify-otp',
        data: data,
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        // Riporta il messaggio REALE del backend (es. "Immagine firma non valida",
        // "Codice OTP scaduto…") invece di attribuire sempre l'errore all'OTP.
        final d = e.response?.data;
        final msg = (d is Map && (d['error'] ?? d['message']) != null)
            ? (d['error'] ?? d['message']).toString()
            : 'Firma non riuscita. Riprova.';
        throw Exception(msg);
      }
      throw Exception('Errore durante la firma: $e');
    }
  }

  Future<void> resendOtp(int richiestaId) async {
    try {
      final response = await apiService.dio.post(
        '/api/ferie/$richiestaId/resend-otp',
      );
      if (response.data['success'] != true) {
        throw Exception('Impossibile reinviare OTP');
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? (body['detail'] ?? body['error'] ?? body['message']) : null;
      throw Exception('Errore: ${detail ?? e.message}');
    } catch (e) {
      throw Exception('Errore durante il reinvio OTP: $e');
    }
  }

  Future<void> deleteRichiesta(int richiestaId) async {
    try {
      await apiService.dio.delete('/api/ferie/$richiestaId');
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? (body['detail'] ?? body['error'] ?? body['message']) : null;
      throw Exception('Errore: ${detail ?? e.message}');
    } catch (e) {
      throw Exception('Errore durante l\'eliminazione della richiesta: $e');
    }
  }
}
