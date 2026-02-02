# 📚 Guide de Développement - CvTech Mobile

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK 3.x+
- Dart SDK 3.x+
- Android Studio / VS Code
- Backend CvTech en cours d'exécution

### Installation
```bash
cd CvTech-mobile
flutter pub get
flutter run
```

---

## 📁 Organisation du Code

### Créer une nouvelle fonctionnalité

```
1. Model      → lib/data/models/{feature}_model.dart
2. Repository → lib/data/repositories/{feature}_repository.dart
3. ViewModel  → lib/presentation/views_models/{feature}/{feature}_view_model.dart
4. View       → lib/presentation/views/{feature}/{feature}_view.dart
5. Widgets    → lib/presentation/widgets/{feature}/
```

### Exemple : Ajouter une fonctionnalité "Certifications"

#### 1. Créer le modèle
```dart
// lib/data/models/profile/certification_model.dart
class CertificationModel extends BaseModel {
  final String name;
  final String issuer;
  final DateTime issueDate;
  final String? credentialUrl;
  
  // fromJson, toMap, copyWith...
}
```

#### 2. Créer le repository
```dart
// lib/data/repositories/certification_repository.dart
class CertificationRepository {
  final ApiClient _apiClient;
  
  Future<List<CertificationModel>> getAll() async { ... }
  Future<CertificationModel> create(CertificationModel cert) async { ... }
  Future<CertificationModel> update(String id, CertificationModel cert) async { ... }
  Future<void> delete(String id) async { ... }
}
```

#### 3. Créer le ViewModel
```dart
// lib/presentation/views_models/certification/certification_view_model.dart
class CertificationViewModel extends ChangeNotifier {
  final CertificationRepository _repository;
  
  List<CertificationModel> _certifications = [];
  bool _isLoading = false;
  
  Future<void> loadCertifications() async { ... }
  Future<void> addCertification(CertificationModel cert) async { ... }
}
```

#### 4. Créer la View
```dart
// lib/presentation/views/certification/certification_view.dart
class CertificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CertificationViewModel(),
      child: Consumer<CertificationViewModel>(
        builder: (context, viewModel, _) => ...
      ),
    );
  }
}
```

---

## 🔧 Patterns Utilisés

### 1. Repository Pattern
```dart
// Abstraction de l'accès aux données
class UserRepository {
  final ApiClient _apiClient;
  
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.dio.get('/user/current-user');
    return UserModel.fromJson(response.data['data']);
  }
}
```

### 2. ViewModel (MVVM)
```dart
class ProfileViewModel extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  
  // Exposer l'état
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  
  // Modifier l'état
  void _update() => notifyListeners();
  
  Future<void> loadProfile() async {
    _isLoading = true;
    _update();
    
    _user = await _repository.getCurrentUser();
    
    _isLoading = false;
    _update();
  }
}
```

### 3. BLoC (pour l'authentification)
```dart
// Events
abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}

// States
abstract class AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
```

---

## 🌐 Gestion des APIs

### Configuration du Client API
```dart
// lib/data/api/api_client.dart
class ApiClient {
  late final Dio _dio;
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,  // Depuis env.dart
      connectTimeout: Duration(seconds: 30),
    ));
    
    // Intercepteur pour le token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
```

### Ajouter un nouvel endpoint
```dart
// lib/data/api/api_endpoints.dart
class ApiEndpoints {
  // Ajouter ici
  static const String certification = '/certifications';
  static const String certificationCreate = '$certification/add';
  static const String certificationUpdate = '$certification/update/'; // + :id
}
```

---

## 🖼️ Gestion des Images

### Afficher une image depuis le serveur
```dart
// ✅ Correct - Utiliser imageUrl
Image.network(
  user.imageUrl ?? '',  // URL complète générée par ImageUrlHelper
  errorBuilder: (context, error, stack) => Icon(Icons.person),
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return CircularProgressIndicator();
  },
)

// ❌ Incorrect - Ne pas utiliser image directement
Image.network(user.image ?? '')  // Ceci est juste le nom du fichier
```

### Upload d'image
```dart
Future<void> uploadImage(String imagePath) async {
  final formData = FormData.fromMap({
    'image': await MultipartFile.fromFile(
      imagePath,
      filename: 'profile.jpg',
    ),
  });
  
  await _apiClient.dio.put(
    '/user/update-profile',
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );
}
```

---

## 🎨 Thème et Styles

### Utiliser les couleurs du thème
```dart
// ✅ Correct
Container(
  color: Theme.of(context).primaryColor,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.headlineMedium,
  ),
)

// ❌ Éviter les couleurs en dur
Container(
  color: Colors.blue,  // Préférer Theme.of(context)
)
```

### Constantes de couleurs
```dart
// lib/core/constants/app_colors.dart
class AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  // ...
}
```

---

## 🧪 Tests

### Test unitaire d'un repository
```dart
// test/repositories/user_repository_test.dart
void main() {
  group('UserRepository', () {
    late UserRepository repository;
    late MockApiClient mockApiClient;
    
    setUp(() {
      mockApiClient = MockApiClient();
      repository = UserRepository(apiClient: mockApiClient);
    });
    
    test('getCurrentUser returns user on success', () async {
      when(mockApiClient.dio.get(any)).thenAnswer(
        (_) async => Response(data: {'data': userJson}),
      );
      
      final user = await repository.getCurrentUser();
      
      expect(user.email, 'test@test.com');
    });
  });
}
```

### Test widget
```dart
// test/widgets/profile_view_test.dart
void main() {
  testWidgets('ProfileView shows user name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: ProfileView(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    expect(find.text('John Doe'), findsOneWidget);
  });
}
```

---

## 📱 Commandes Flutter Utiles

```bash
# Développement
flutter run                    # Lancer l'app
flutter run -d chrome          # Lancer sur Chrome
flutter run -d windows         # Lancer sur Windows
flutter run --release          # Mode release

# Build
flutter build apk              # Build APK debug
flutter build apk --release    # Build APK release
flutter build appbundle        # Build AAB (Play Store)

# Maintenance
flutter clean                  # Nettoyer le projet
flutter pub get               # Installer les dépendances
flutter pub upgrade           # Mettre à jour les dépendances

# Qualité
flutter analyze               # Analyser le code
dart format lib/              # Formater le code
flutter test                  # Lancer les tests
```

---

## 🐛 Debugging

### Logs réseau
```dart
// Activer les logs Dio
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

### Debug print
```dart
debugPrint('User: ${user.toJson()}');
```

### Inspecter le widget tree
- Flutter DevTools : `flutter pub global run devtools`
- Dans VS Code : Palette > "Flutter: Open DevTools"
