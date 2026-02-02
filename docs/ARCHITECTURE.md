# 🏗️ Architecture du Projet CvTech Mobile

## 📋 Vue d'ensemble

CvTech Mobile est une application Flutter utilisant une architecture **Clean Architecture** avec le pattern **MVVM (Model-View-ViewModel)** et **BLoC** pour la gestion d'état.

---

## 📁 Structure des Dossiers

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── app.dart                     # Configuration de l'application (routes, thème)
│
├── core/                        # 🔧 Couche Core (utilitaires et configuration)
│   ├── env.dart                 # Configuration d'environnement (URLs API)
│   ├── connectivity_test.dart   # Test de connectivité réseau
│   ├── constants/               # Constantes de l'application
│   │   └── app_strings.dart
│   │   └── app_colors.dart
│   ├── enums/                   # Énumérations
│   └── utils/                   # Utilitaires
│       ├── auth_error_handler.dart
│       ├── image_url_helper.dart    # Helper pour les URLs d'images
│       ├── navigator_utils.dart
│       ├── media/               # Gestion des médias
│       ├── preferences/         # Préférences utilisateur (SharedPreferences)
│       └── validators/          # Validateurs de formulaires
│
├── constants/                   # 📌 Constantes métier
│   ├── professional_categories.dart
│   └── professional_domains.dart
│
├── data/                        # 💾 Couche Data (accès aux données)
│   ├── api/                     # Configuration API
│   │   ├── api_client.dart      # Client HTTP (Dio)
│   │   └── api_endpoints.dart   # Points de terminaison API
│   │
│   ├── models/                  # Modèles de données
│   │   ├── base/                # Modèles de base
│   │   │   └── base_model.dart
│   │   ├── auth/                # Modèles d'authentification
│   │   │   ├── user_model.dart
│   │   │   ├── auth_response.dart
│   │   │   ├── login_request.dart
│   │   │   └── register_request.dart
│   │   ├── profile/             # Modèles de profil
│   │   │   ├── education_model.dart
│   │   │   ├── experience_model.dart
│   │   │   ├── project_model.dart
│   │   │   ├── skill_model.dart
│   │   │   └── certification_model.dart
│   │   ├── company_model.dart
│   │   ├── job_model.dart
│   │   ├── transaction_model.dart
│   │   └── post.dart
│   │
│   ├── repositories/            # Repositories (accès aux données)
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── education_repository.dart
│   │   ├── experience_repository.dart
│   │   ├── project_repository.dart
│   │   ├── skill_repository.dart
│   │   ├── company_repository.dart
│   │   ├── job_repository.dart
│   │   └── transaction_repository.dart
│   │
│   └── test/                    # Tests de la couche data
│
├── presentation/                # 🎨 Couche Présentation (UI)
│   ├── blocs/                   # BLoCs (Business Logic Components)
│   │   └── auth/
│   │       ├── auth_bloc.dart
│   │       ├── auth_event.dart
│   │       └── auth_state.dart
│   │
│   ├── views_models/            # ViewModels (MVVM)
│   │   ├── app/
│   │   │   └── theme_view_model.dart
│   │   ├── base/
│   │   ├── home/
│   │   ├── main/
│   │   └── profile/
│   │       └── profile_view_model.dart
│   │
│   ├── views/                   # Vues (Écrans)
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/                # Écrans d'authentification
│   │   │   ├── login_view.dart
│   │   │   ├── register_view.dart
│   │   │   ├── forgot_password_view.dart
│   │   │   ├── otp_verification_view.dart
│   │   │   └── enter_otp_view.dart
│   │   ├── main/                # Écran principal (navigation)
│   │   │   ├── main_view.dart
│   │   │   └── widgets/
│   │   ├── home/                # Écran d'accueil
│   │   ├── profile/             # Écrans de profil
│   │   │   ├── profile_view.dart
│   │   │   ├── edit_profile_view.dart
│   │   │   ├── edit_profile_image_view.dart
│   │   │   ├── professional_profile_view.dart
│   │   │   ├── forms/           # Formulaires de profil
│   │   │   │   ├── education_form_view.dart
│   │   │   │   ├── experience_form_view.dart
│   │   │   │   ├── project_form_view.dart
│   │   │   │   └── skill_form_view.dart
│   │   │   └── widgets/
│   │   └── test/                # Écrans de test
│   │
│   └── widgets/                 # Widgets réutilisables
│       ├── common/              # Widgets communs
│       ├── auth/                # Widgets d'authentification
│       ├── profile/             # Widgets de profil
│       │   └── profile_image_picker.dart
│       ├── create_button.dart
│       └── custom_tab_bar.dart
│
└── theme/                       # 🎨 Configuration du thème
    ├── app_theme.dart           # Thème principal
    ├── custom_text_theme.dart
    ├── custom_card_theme.dart
    └── ...
```

---

## 🔄 Flux de Données

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRÉSENTATION                             │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐     │
│  │    View     │◄───│  ViewModel   │◄───│   BLoC/State    │     │
│  │  (Widget)   │    │   (Provider) │    │   (flutter_bloc)│     │
│  └─────────────┘    └──────────────┘    └─────────────────┘     │
│         │                  │                     │               │
└─────────┼──────────────────┼─────────────────────┼───────────────┘
          │                  │                     │
          ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                            DATA                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                     Repository                           │    │
│  │   (AuthRepository, UserRepository, EducationRepo...)    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                     ApiClient (Dio)                      │    │
│  │         (Intercepteurs, Token, Refresh Token)            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       BACKEND (Bun.js)                          │
│                    http://localhost:9000                         │
│                          MongoDB                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Gestion de l'Authentification

### Pattern utilisé : BLoC + Secure Storage

```dart
// États d'authentification
AuthInitial        → État initial
AuthLoading        → Chargement en cours
AuthAuthenticated  → Utilisateur connecté
AuthUnauthenticated → Utilisateur non connecté
AuthError          → Erreur d'authentification
```

### Flux d'authentification :

1. **Démarrage** : `AuthCheckRequested` → Vérifie le token stocké
2. **Connexion** : `AuthLoginRequested` → Appel API → Stockage token → `AuthAuthenticated`
3. **Déconnexion** : `AuthLogoutRequested` → Suppression token → `AuthUnauthenticated`
4. **Refresh Token** : Automatique via intercepteur Dio

---

## 🖼️ Gestion des Images

### URLs des images (ImageUrlHelper)

```dart
// Format des URLs
Profile Image: {baseUrl}/uploads/images-{userId}/{imageName}
Cover Image:   {baseUrl}/uploads/images-{userId}/{coverName}
Certificate:   {baseUrl}/uploads/images-{userId}/certfication/{certName}
Project:       {baseUrl}/uploads/images-{userId}/projects/{imageName}
```

### Configuration dynamique (env.dart)

```dart
// Détection automatique de la plateforme
- Web/Desktop:     http://localhost:9000
- Android Emulator: http://10.0.2.2:9000
- iOS Simulator:    http://127.0.0.1:9000
- Téléphone réel:   http://192.168.1.120:9000 (IP du PC)
```

---

## 📦 Dépendances Principales

| Package | Usage |
|---------|-------|
| `flutter_bloc` | Gestion d'état (BLoC pattern) |
| `provider` | Injection de dépendances, MVVM |
| `dio` | Client HTTP |
| `flutter_secure_storage` | Stockage sécurisé des tokens |
| `image_picker` | Sélection d'images |
| `shared_preferences` | Préférences utilisateur |
| `intl` | Internationalisation |

---

## 🎯 Conventions de Nommage

| Type | Convention | Exemple |
|------|------------|---------|
| Fichiers | snake_case | `user_repository.dart` |
| Classes | PascalCase | `UserRepository` |
| Variables | camelCase | `currentUser` |
| Constantes | camelCase | `baseUrl` |
| Widgets | PascalCase | `ProfileView` |
| ViewModels | PascalCase + ViewModel | `ProfileViewModel` |
| BLoCs | PascalCase + Bloc | `AuthBloc` |

---

## 🔗 Correspondance Backend

| Flutter Endpoint | Backend Route | Description |
|------------------|---------------|-------------|
| `/auth/login` | POST `/auth/login` | Connexion |
| `/auth/refreshToken` | POST `/auth/refreshToken` | Refresh token |
| `/user/current-user` | GET `/user/current-user` | Profil actuel |
| `/user/update-profile` | PUT `/user/update-profile` | Mise à jour profil |
| `/education/*` | GET/POST/PUT/DELETE | CRUD éducation |
| `/experience/*` | GET/POST/PUT/DELETE | CRUD expérience |
| `/projects/*` | GET/POST/PUT/DELETE | CRUD projets |

---

## 📱 Navigation

```
SplashScreen
    │
    ▼
AuthWrapper ─────────────────────────────────┐
    │                                         │
    ▼ (Non authentifié)                       ▼ (Authentifié)
LoginView                                  MainView
    │                                         │
    ├── RegisterView                          ├── HomeView (Tab 0)
    ├── ForgotPasswordView                    ├── SearchView (Tab 1)
    └── OTPVerificationView                   ├── CreateView (Tab 2)
                                              ├── MessagesView (Tab 3)
                                              └── ProfileView (Tab 4)
                                                    │
                                                    ├── EditProfileView
                                                    ├── EducationFormView
                                                    ├── ExperienceFormView
                                                    └── ProjectFormView
```
