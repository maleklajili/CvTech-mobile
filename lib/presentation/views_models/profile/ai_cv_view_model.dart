import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';

class AiCvViewModel extends SafeChangeNotifier {
  final AiCvRepository _repository;

  AiCvViewModel({AiCvRepository? repository})
      : _repository = repository ?? AiCvRepository();

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
    notifyListeners();
  }

  void setSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  void setFormat(String format) {
    _selectedFormat = format;
    notifyListeners();
  }

  void selectCv(AiCvModel? cv) {
    _selectedCv = cv;
    notifyListeners();
  }

  /// Load all user's generated CVs
  Future<void> loadCvs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cvs = await _repository.getMyCvs();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a new CV
  Future<void> generateCv({String? customPrompt}) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

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
      notifyListeners();
    }
  }

  /// Reformulate an existing CV
  Future<void> reformulateCv(String cvId, {String? instructions}) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

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
      notifyListeners();
    }
  }

  /// Delete a CV
  Future<bool> deleteCv(String cvId) async {
    try {
      await _repository.delete(cvId);
      _cvs.removeWhere((cv) => cv.id == cvId);
      if (_selectedCv?.id == cvId) {
        _selectedCv = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
