import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import '../models/ddt_model.dart';

class DdtService {
  final ApiService apiService;

  DdtService(this.apiService);

  Future<List<DdtModel>> fetchAssignedDdt() async {
    try {
      final response = await apiService.dio.get('/api/mobile/ddt');
      final data = response.data;
      if (data['success'] == true) {
        return (data['ddt'] as List).map((json) => DdtModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Errore nel recupero della lista DDT: $e');
    }
  }

  Future<DdtModel> fetchDdtDetail(int id) async {
    try {
      final response = await apiService.dio.get('/api/mobile/ddt/$id');
      final data = response.data;
      if (data['success'] == true) {
        return DdtModel.fromJson(data['ddt']);
      }
      throw Exception('Dettaglio DDT non trovato.');
    } catch (e) {
      throw Exception('Errore nel recupero del dettaglio DDT: $e');
    }
  }

  Future<void> updateStato(int id, String stato) async {
    try {
      final response = await apiService.dio.post(
        '/api/mobile/ddt/$id/stato',
        data: {'stato': stato},
      );
      if (response.data['success'] != true) {
        throw Exception('Errore aggiornamento stato');
      }
    } catch (e) {
      throw Exception('Errore durante l\'aggiornamento dello stato: $e');
    }
  }

  Future<void> inviaFirma(int id, String ruolo, String base64Firma, String? firmatarioNome) async {
    try {
      final response = await apiService.dio.post(
        '/api/mobile/ddt/$id/firma',
        data: {
          'ruolo': ruolo,
          'firma': base64Firma,
          'firmatario_nome': firmatarioNome,
        },
      );
      if (response.data['success'] != true) {
        throw Exception('Impossibile salvare la firma.');
      }
    } catch (e) {
      throw Exception('Errore durante l\'invio della firma: $e');
    }
  }

  Future<File> downloadDdtPdf(int id, String numero) async {
    try {
      final dir = await getTemporaryDirectory();
      final sanitizedNumero = numero.replaceAll(RegExp(r'[\/ ]'), '-');
      final savePath = '${dir.path}/ddt_$sanitizedNumero.pdf';
      
      await apiService.dio.download(
        '/api/mobile/ddt/$id/pdf',
        savePath,
      );
      return File(savePath);
    } catch (e) {
      throw Exception('Errore nel download del PDF: $e');
    }
  }
}
