import 'package:dio/dio.dart';
import 'api_service.dart';

class FerieService {
  final ApiService apiService;

  FerieService(this.apiService);

  Future<List<dynamic>> fetchStoricoFerie() async {
    try {
      final response = await apiService.dio.get('/api/ferie');
      return response.data;
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
    } catch (e) {
      throw Exception('Errore durante la richiesta ferie: $e');
    }
  }

  Future<void> verificaOtp(int richiestaId, String otp) async {
    try {
      await apiService.dio.post(
        '/api/ferie/$richiestaId/verify-otp',
        data: {'otp': otp},
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Codice OTP errato o scaduto.');
      }
      throw Exception('Errore durante la verifica OTP: $e');
    }
  }
}
