import 'package:flutter/foundation.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';

class AiCvViewModel extends ChangeNotifier {
  final AiCvRepository _repository;

  AiCvViewModel({AiCvRepository? repository})
      : _repository = repository ?? AiCvRepository();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // States
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  List<AiCvModel> _cvs = [];
  AiCvModel? _selectedCv;

  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  List<AiCvModel> get cvs => _cvs;
  AiCvModel? get selectedCv => _selectedCv;

  // Selected generation options
  String _selectedLanguage = 'fr';
  String _selectedSection = 'full';
  String _selectedFormat = 'standard';

  String get selectedLanguage => _selectedLanguage;
  String get selectedSection => _selectedSection;
  String get selectedFormat => _selectedFormat;

  void setLanguage(String language) {
    _selectedLanguage = language;
    _safeNotify();
  }

  void setSection(String section) {
    _selectedSection = section;
    _safeNotify();
  }

  void setFormat(String format) {
    _selectedFormat = format;
    _safeNotify();
  }

  void selectCv(AiCvModel? cv) {
    _selectedCv = cv;
    _safeNotify();
  }

  /// Load all user's generated CVs
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

  /// Generate a new CV
  Future<void> generateCv({String? customPrompt}) async {
    _isGenerating = true;
    _error = null;
    _safeNotify();

    try {
      final cv = await _repository.generate(
        language: _selectedLanguage,
        section: _selectedSection,
        format: _selectedFormat,
        customPrompt: customPrompt,
      );
      _cvs.insert(0, cv);
      _selectedCv = cv;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isGenerating = false;
      _safeNotify();
    }
  }

  /// Reformulate an existing CV
  Future<void> reformulateCv(String cvId, {String? instructions}) async {
    _isGenerating = true;
    _error = null;
    _safeNotify();

    try {
      final cv = await _repository.reformulate(
        cvId: cvId,
        instructions: instructions,
      );
      _cvs.insert(0, cv);
      _selectedCv = cv;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isGenerating = false;
      _safeNotify();
    }
  }

  /// Delete a CV
  Future<void> deleteCv(String cvId) async {
    try {
      await _repository.delete(cvId);
      _cvs.removeWhere((cv) => cv.id == cvId);
      if (_selectedCv?.id == cvId) {
        _selectedCv = null;
      }
      _safeNotify();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
    }
  }
}
