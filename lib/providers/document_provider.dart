import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/document_model.dart';
import '../services/api_service.dart';

class DocumentProvider extends ChangeNotifier {
  final ApiService apiService;

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get documents => _documents;
  List<DocumentModel> get receivedDocuments => _documents.where((d) => d.isCompanySent).toList();
  List<DocumentModel> get sentDocuments => _documents.where((d) => !d.isCompanySent).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadDocumentsCount => receivedDocuments.where((d) => !d.isRead).length;

  DocumentProvider(this.apiService);

  // Carica la lista di tutti i documenti
  Future<void> fetchDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.dio.get('api/mobile/documenti');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['documenti'] as List<dynamic>;
        _documents = list.map((d) => DocumentModel.fromJson(d as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = data['message'] as String? ?? 'Impossibile caricare i documenti.';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Errore di rete durante il caricamento dei documenti.';
    } catch (_) {
      _errorMessage = 'Errore imprevisto durante il recupero dei documenti.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Segna un documento dell'azienda come letto (presa visione)
  Future<bool> markAsRead(int documentId) async {
    try {
      final response = await apiService.dio.post('api/mobile/documenti/$documentId/presa-visione');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        // Aggiorna lo stato locale senza rifare la chiamata di rete completa
        final index = _documents.indexWhere((d) => d.id == documentId);
        if (index != -1) {
          final oldDoc = _documents[index];
          _documents[index] = DocumentModel(
            id: oldDoc.id,
            titolo: oldDoc.titolo,
            descrizione: oldDoc.descrizione,
            tipo: oldDoc.tipo,
            direzione: oldDoc.direzione,
            nomeFile: oldDoc.nomeFile,
            dimensioneByte: oldDoc.dimensioneByte,
            presaVisioneAt: DateTime.parse(data['presa_visione_at'] as String),
            createdAt: oldDoc.createdAt,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (_) {
      // Gestisci errore silenziosamente
    }
    return false;
  }

  // Carica un documento (es. certificato medico) verso l'azienda
  Future<bool> uploadDocument({
    required String title,
    required String type,
    required List<int> bytes,
    required String filename,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'titolo': title,
        'tipo': type,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await apiService.dio.post(
        'api/mobile/documenti',
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        // Ricarichiamo la lista aggiornata
        await fetchDocuments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] as String? ?? 'Errore nel caricamento del file.';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Errore di rete durante il caricamento.';
    } catch (_) {
      _errorMessage = 'Impossibile inviare il documento.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
