# 📖 Documentation CvTech Mobile

Bienvenue dans la documentation du projet CvTech Mobile.

## 📚 Documents Disponibles

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Structure du projet, flux de données, patterns utilisés |
| [TACHES.md](./TACHES.md) | Liste des tâches à faire, bugs à corriger |
| [GUIDE_DEVELOPPEMENT.md](./GUIDE_DEVELOPPEMENT.md) | Guide pour les développeurs |

## 🚀 Démarrage Rapide

```bash
# Cloner le projet
git clone <repo-url>
cd CvTech-mobile

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## 🔧 Configuration

### Pour PC/Web (localhost)
Aucune configuration nécessaire. L'application détecte automatiquement la plateforme.

### Pour Téléphone Réel
1. Ouvrir `lib/core/env.dart`
2. Modifier `baseUrlRealDevice` avec l'IP de votre PC
3. Décommenter la ligne `const String baseUrl = baseUrlRealDevice;`
4. S'assurer que le téléphone et le PC sont sur le même WiFi

## 📱 Plateformes Supportées

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔗 Liens Utiles

- [Backend API](../Social-media-backend/README.md)
- [Frontend Next.js](../CvTech-front/README.md)
- [Flutter Documentation](https://docs.flutter.dev/)
