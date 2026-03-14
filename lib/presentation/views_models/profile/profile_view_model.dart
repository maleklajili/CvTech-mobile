// Project imports:
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/models/language_model.dart';
import 'package:cv_tech/data/repositories/language_repository.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/presentation/views_models/main/scroll_listener.dart';

enum ProfileState { initial, loading, loaded, error }

class ProfileViewModel extends ScrollListener {
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
  final UserRepository _userRepository;
  final LanguageRepository _languageRepository;

  UserModel? _user;
  ProfileState _state = ProfileState.initial;
  String? _errorMessage;

  // Stats
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  DateTime? _memberSince;

  // Languages
  List<LanguageModel> _languages = [];

  ProfileViewModel(super.context, {UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository(),
        _languageRepository = LanguageRepository() {
    initScrollListener();
    loadUserProfile();
  }

  // Getters
  UserModel? get user => _user;
  ProfileState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProfileState.loading;
  bool get hasError => _state == ProfileState.error;
  bool get isLoaded => _state == ProfileState.loaded;

  // Stats getters
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  int get postsCount => _postsCount;
  DateTime? get memberSince => _memberSince;

  // Languages
  List<LanguageModel> get languages => _languages;

  // Informations de l'utilisateur
  String get fullName => _user?.fullName ?? 'Utilisateur';
  String get userName => _user?.userName ?? '';
  String get email => _user?.email ?? '';
  String get professionalTitle => _user?.professionalTitle ?? '';
  String get bio => _user?.bio ?? '';
  String get city => _user?.city ?? '';
  String get address => _user?.address ?? '';
  String get phone => _user?.phone ?? '';
  String get website => _user?.website ?? '';
  String get location => _user?.location ?? '';
  String? get image => _user?.imageUrl;  // Utiliser imageUrl au lieu de image
  String? get cover => _user?.coverUrl;  // Utiliser coverUrl au lieu de cover
  int get coins => _user?.coins ?? 0;

  /// Charger le profil de l'utilisateur connecté
  Future<void> loadUserProfile() async {
    _state = ProfileState.loading;
    _errorMessage = null;
    update();

    try {
      _user = await _userRepository.getCurrentUser();
      print('🔍 ProfileViewModel - User loaded: ${_user?.toString()}');
      print('🔍 ProfileViewModel - Image field: ${_user?.image}');
      print('🔍 ProfileViewModel - Cover field: ${_user?.cover}');
      print('🔍 ProfileViewModel - ImageUrl getter: ${_user?.imageUrl}');
      print('🔍 ProfileViewModel - CoverUrl getter: ${_user?.coverUrl}');
      _state = ProfileState.loaded;
      // Load stats in background (non-blocking)
      _loadStats();
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    update();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _userRepository.getUserStats(),
        _languageRepository.getAll(page: 1, limit: 50),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      _followersCount = (stats['followers'] as num?)?.toInt() ?? 0;
      _followingCount = (stats['following'] as num?)?.toInt() ?? 0;
      _postsCount = (stats['posts'] as num?)?.toInt() ?? 0;
      final createdAtStr = stats['createdAt'];
      if (createdAtStr != null) {
        _memberSince = DateTime.tryParse(createdAtStr.toString());
      }

      _languages = results[1] as List<LanguageModel>;
      update();
    } catch (_) {
      // Silently ignore stats errors — profile still shows
    }
  }

  /// Rafraîchir le profil
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  /// Mettre à jour l'utilisateur après modification
  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    update();
  }

  /// Mettre à jour le profil avec image et/ou cover
  Future<bool> updateProfileWithImages({
    UpdateProfileRequest? request,
    String? imagePath,
    String? coverPath,
    List<int>? imageBytes,
    List<int>? coverBytes,
  }) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    update();

    try {
      // Si pas de request fournie, créer une avec les données actuelles
      final profileRequest = request ?? _createRequestFromCurrentUser();
      
      final updatedUser = await _userRepository.updateProfile(
        profileRequest,
        imagePath: imagePath,
        coverPath: coverPath,
        imageBytes: imageBytes,
        coverBytes: coverBytes,
      );

      _user = updatedUser;
      _state = ProfileState.loaded;
      update();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = ProfileState.error;
      update();
      return false;
    }
  }

  /// Uploader uniquement l'image de profil (support web et mobile)
  Future<bool> uploadProfileImage(String? imagePath, {List<int>? imageBytes}) async {
    bool success = await updateProfileWithImages(
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
    if (success) {
      // Forcer le rafraîchissement pour récupérer la nouvelle image
      await refreshProfile();
    }
    return success;
  }

  /// Uploader uniquement l'image de couverture (support web et mobile)
  Future<bool> uploadCoverImage(String? coverPath, {List<int>? coverBytes}) async {
    bool success = await updateProfileWithImages(
      coverPath: coverPath,
      coverBytes: coverBytes,
    );
    if (success) {
      // Forcer le rafraîchissement pour récupérer la nouvelle image
      await refreshProfile();
    }
    return success;
  }

  /// Créer un UpdateProfileRequest avec les données actuelles de l'utilisateur
  UpdateProfileRequest _createRequestFromCurrentUser() {
    if (_user == null) {
      return const UpdateProfileRequest();
    }

    return UpdateProfileRequest(
      firstName: _user!.firstName,
      lastName: _user!.lastName,
      userName: _user!.userName,
      email: _user!.email,
      bio: _user!.bio,
      city: _user!.city,
      address: _user!.address,
      professionalTitle: _user!.professionalTitle,
      postalCode: _user!.postalCode,
      phone: _user!.phone,
      website: _user!.website,
      location: _user!.location,
      professionalStatus: _user!.professionalStatus,
      previousDomain: _user!.previousDomain,
      currentDomain: _user!.currentDomain,
      professionalCategory: _user!.professionalCategory,
      keywords: _user!.keywords,
    );
  }
}



