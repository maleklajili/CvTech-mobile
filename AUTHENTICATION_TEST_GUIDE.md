# Guide de Test - Authentification Flutter avec Backend Bun

## 🚀 Configuration et Test

### 1. Vérifier que le Backend est en cours d'exécution

Le backend doit être démarré sur le port **9000**.

```bash
cd Social-media-backend
bun run src/server.ts
```

Si le serveur est déjà en cours, vous verrez le message :
```
ERROR: Failed to start server: Error: Failed to start server. Is port 9000 in use?
```

### 2. Configuration de l'URL dans Flutter

**✨ NOUVEAU : Configuration Dynamique !**

Vous n'avez plus besoin de modifier le code source ! Utilisez l'écran de configuration réseau dans l'application :

1. Ouvrez l'application
2. Allez dans **Paramètres → Configuration Réseau**
3. Activez "Utiliser une URL personnalisée"
4. Entrez l'URL de votre backend
5. Testez et sauvegardez

**Pour trouver votre IP :**
- Windows : `ipconfig` → Cherchez "IPv4 Address"
- Mac/Linux : `ifconfig` → Cherchez "inet"

**URLs par plateforme :**
- **Android Emulator** : `http://10.0.2.2:9000` (détecté automatiquement)
- **iOS Simulator** : `http://localhost:9000` (détecté automatiquement)
- **Téléphone Réel** : `http://[VOTRE_IP]:9000` (ex: `http://192.168.1.120:9000`)
- **PC/Web** : `http://localhost:9000` (détecté automatiquement)

📖 **Voir le guide complet** : [GUIDE_CONFIGURATION_RESEAU.md](GUIDE_CONFIGURATION_RESEAU.md)

**⚠️ Important :** Votre téléphone et PC doivent être sur le **même Wi-Fi**

### 3. Tester la connexion avec l'écran de test

1. Lancez l'application Flutter
2. Sur l'écran de connexion, cliquez sur l'icône **🐛 Bug** en haut à droite
3. Vous accéderez à l'écran de test API

**Tests disponibles :**
- ✅ **Tester la connexion** : Vérifie que le backend est accessible
- ✅ **Envoyer OTP** : Teste l'envoi d'un code de vérification
- ✅ **Tester Login** : Teste la connexion avec des identifiants demo

### 4. Flow d'inscription complet

#### Étape 1 : Inscription
1. Ouvrez l'application Flutter
2. Cliquez sur **"S'inscrire"**
3. Remplissez le formulaire :
   - **Prénom** : Minimum 2 caractères
   - **Nom** : Minimum 2 caractères
   - **Email** : Format valide (exemple@email.com)
   - **Mot de passe** : 
     - Minimum 6 caractères
     - Au moins une lettre
     - Au moins un chiffre
   - **Confirmer le mot de passe**
   - **Accepter les conditions** : Cochez la case
4. Cliquez sur **"Créer mon compte"**

#### Étape 2 : Vérification OTP
1. Un code à 6 chiffres est envoyé à votre email
2. Vérifiez votre boîte mail (ou les logs du backend)
3. Entrez le code OTP
4. Le compte est créé automatiquement
5. Vous êtes redirigé vers l'application

#### Étape 3 : Connexion
1. Sur l'écran de connexion
2. Entrez votre **email ou username**
3. Entrez votre **mot de passe**
4. Cliquez sur **"Se connecter"**

### 5. Vérifier les logs du Backend

Dans le terminal du backend, vous devriez voir :
```
POST /auth/send-otp/test@example.com - 200 OK
POST /auth/verify-otp/123456 - 200 OK
POST /auth/login - 200 OK
```

### 6. Test avec Postman (optionnel)

#### Envoyer OTP
```http
POST http://localhost:9000/auth/send-otp/test@example.com
```

#### Vérifier OTP et créer compte
```http
POST http://localhost:9000/auth/verify-otp/123456
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "test@example.com",
  "password": "test123",
  "userName": "",
  "bio": "",
  "city": "",
  "adress": "",
  "professionalTitle": "",
  "postalCode": 0,
  "phone": "",
  "website": "",
  "location": "",
  "fullName": "John Doe",
  "coins": 0
}
```

#### Login
```http
POST http://localhost:9000/auth/login
Content-Type: application/json

{
  "identifier": "test@example.com",
  "password": "test123"
}
```

### 7. Récupération du code OTP

Le code OTP est visible dans :
1. **Les logs du backend** (console)
2. **L'email envoyé** (si SendGrid est configuré)
3. **La réponse de l'API** (en mode DEV) :
```json
{
  "success": true,
  "data": {
    "otp": "123456",
    "expiresAt": "2026-01-16T10:45:00.000Z"
  }
}
```

### 8. Dépannage

#### Problème : Cannot connect to backend
**Solution :**
1. Vérifiez que le backend est en cours d'exécution
2. Vérifiez l'URL dans `env.dart`
3. Pour Android Emulator, utilisez `10.0.2.2` au lieu de `localhost`
4. Désactivez le pare-feu si nécessaire

#### Problème : Email already exists
**Solution :**
- Utilisez un autre email
- Ou supprimez l'utilisateur de la base de données MongoDB

#### Problème : Invalid OTP
**Solution :**
- Le code OTP expire après 5 minutes
- Demandez un nouveau code avec "Renvoyer"

#### Problème : Certificate verify failed (pour iOS)
**Solution :**
Ajoutez dans `ios/Runner/Info.plist` :
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 9. Variables d'environnement Backend (.env)

```env
DATABASE_URL=mongodb+srv://cvtech:cvtech@cluster0.asfulb4.mongodb.net/cv-techMA
DATABASE_NAME=cv-tech
PORT=9000
JWT_SECRET=[votre_secret]
EMAIL_ADRESS=social-media@thymsys.com
EXP_ACCESS_TOKEN=1d
EXP_REFRESH_TOKEN=7d
MODEV=DEV
RESET_TOKEN_EXPIRY_MS=3600000
SENDGRID_API_KEY=[votre_clé]
FRONT_URL=http://127.0.0.1:3002
```

### 10. Fonctionnalités implémentées

✅ **Authentification complète avec BLoC**
- Login avec email/username
- Inscription avec OTP
- Mot de passe oublié
- Gestion sécurisée des tokens (JWT)
- Refresh token automatique

✅ **Validations robustes**
- Format email
- Force du mot de passe
- Confirmation de mot de passe
- Acceptation des conditions

✅ **Sécurité**
- Stockage sécurisé des tokens (FlutterSecureStorage)
- Hachage des mots de passe (côté backend)
- Expiration des tokens
- Protection CSRF

✅ **UX/UI**
- Indicateurs de chargement
- Messages d'erreur clairs
- Validation en temps réel
- Animations de succès
- Dark mode support

---

## 📝 Notes

- Le **username** est généré automatiquement par le backend
- Les nouveaux utilisateurs reçoivent **300 coins** par défaut
- Le code OTP expire après **5 minutes**
- Le token d'accès expire après **1 jour**
- Le token de rafraîchissement expire après **7 jours**

## 🎯 Prochaines étapes

- [ ] Ajouter l'authentification Google/Facebook
- [ ] Implémenter la déconnexion
- [ ] Ajouter un profil utilisateur
- [ ] Gestion des erreurs réseau améliorée
- [ ] Tests unitaires et d'intégration
