import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/repositories/manual_cv_repository.dart';

class ManualCvViewModel extends ChangeNotifier {
  final ManualCvRepository _repository;

  ManualCvViewModel({ManualCvRepository? repository})
      : _repository = repository ?? ManualCvRepository();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // States
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  List<ManualCvModel> _cvs = [];
  ManualCvModel? _selectedCv;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<ManualCvModel> get cvs => _cvs;
  ManualCvModel? get selectedCv => _selectedCv;

  void selectCv(ManualCvModel? cv) {
    _selectedCv = cv;
    _safeNotify();
  }

  Future<void> loadCvs() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _cvs = await _repository.getMyCvs();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> createCv(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    _safeNotify();

    try {
      final cv = await _repository.create(data);
      _cvs.insert(0, cv);
      _selectedCv = cv;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> updateCv(String cvId, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    _safeNotify();

    try {
      final updated = await _repository.update(cvId, data);
      final index = _cvs.indexWhere((c) => c.id == cvId);
      if (index != -1) {
        _cvs[index] = updated;
      }
      _selectedCv = updated;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> deleteCv(String cvId) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _repository.delete(cvId);
      _cvs.removeWhere((c) => c.id == cvId);
      if (_selectedCv?.id == cvId) {
        _selectedCv = null;
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<List<int>?> downloadPdf(String cvId, {String? primaryColor, String? accentColor, String? fontFamily, String? format}) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final bytes = await _repository.downloadPdf(cvId, primaryColor: primaryColor, accentColor: accentColor, fontFamily: fontFamily, format: format);
      return bytes;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<bool> importFromProfile({
    String format = 'standard',
    String language = 'fr',
  }) async {
    _isSaving = true;
    _error = null;
    _safeNotify();

    try {
      final cv = await _repository.importFromProfile(
        format: format,
        language: language,
      );
      _cvs.insert(0, cv);
      _selectedCv = cv;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }
}
