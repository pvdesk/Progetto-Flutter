import 'package:dio/dio.dart';
import 'api_service.dart';
import 'remote_logger.dart';

class HaccpService {
  final ApiService _apiService;

  HaccpService(this._apiService);

  /// Recupera la lista dei documenti HACCP da firmare per l'utente corrente.
  /// Ogni blocco può contenere `per_frequenza`: [{periodicita, righe, giorni}].
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

  /// Richiede un OTP di firma HACCP: viene inviato all'utente (chat/notifica), valido 5'.
  Future<Map<String, dynamic>> richiediOtp() async {
    try {
      final response = await _apiService.dio.post('api/mobile/haccp/richiedi-otp');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      RemoteLogger.error('Errore richiediOtp: ${e.message}');
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
    } catch (e) {
      RemoteLogger.error('Errore generico richiediOtp: $e');
    }
    return {'success': false, 'message': 'Impossibile richiedere l\'OTP.'};
  }

  /// Invia la firma per uno o più documenti/giorni.
  /// [modalita] = 'olografa' (usa [base64Signature]) oppure 'otp' (usa [otp]).
  Future<Map<String, dynamic>> salvaFirma(
    List<Map<String, dynamic>> selezione, {
    String modalita = 'olografa',
    String? base64Signature,
    String? otp,
    String deviceInfo = 'Sconosciuto',
  }) async {
    try {
      final Map<String, dynamic> body = {
        'selezione': selezione,
        'modalita': modalita,
        'device': deviceInfo,
      };
      if (modalita == 'otp') {
        body['otp'] = otp;
      } else {
        body['firma'] = base64Signature;
      }

      final response = await _apiService.dio.post('api/mobile/haccp/firma', data: body);
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
