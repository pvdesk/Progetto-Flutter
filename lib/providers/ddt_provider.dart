import 'package:flutter/material.dart';
import '../models/ddt_model.dart';
import '../services/ddt_service.dart';

class DdtProvider extends ChangeNotifier {
  final DdtService _ddtService;

  List<DdtModel> _ddts = [];
  bool _isLoading = false;
  String? _errorMessage;

  DdtModel? _selectedDdt;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;

  List<DdtModel> get ddts => _ddts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DdtModel? get selectedDdt => _selectedDdt;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailErrorMessage => _detailErrorMessage;

  DdtProvider(this._ddtService);

  Future<void> fetchAssignedDdt() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ddts = await _ddtService.fetchAssignedDdt();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDdtDetail(int id) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      _selectedDdt = await _ddtService.fetchDdtDetail(id);
    } catch (e) {
      _detailErrorMessage = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> updateStato(int id, String stato) async {
    await _ddtService.updateStato(id, stato);
    await fetchDdtDetail(id);
    await fetchAssignedDdt();
  }

  Future<void> inviaFirma(int id, String ruolo, String base64Firma, String? firmatarioNome) async {
    await _ddtService.inviaFirma(id, ruolo, base64Firma, firmatarioNome);
    await fetchDdtDetail(id);
    await fetchAssignedDdt();
  }

  void clearSelected() {
    _selectedDdt = null;
    notifyListeners();
  }
}
