# MANUALE TECNICO — Progetto-Flutter (INTHEGRA Mobile)
> App mobile per dipendenti della ristorazione collettiva  
> Versione documento: **2.0** — aggiornato: giugno 2026

---

## Indice
1. [Panoramica](#1-panoramica)
2. [Stack Tecnologico](#2-stack-tecnologico)
3. [Architettura](#3-architettura)
4. [Struttura del Progetto](#4-struttura-progetto)
5. [Schermate e Navigazione](#5-schermate)
6. [Provider (State Management)](#6-provider)
7. [Servizi](#7-servizi)
8. [Modelli Dati](#8-modelli)
9. [Autenticazione Bearer Token](#9-autenticazione)
10. [Integrazione API Server](#10-api)
11. [Notifiche Push (FCM)](#11-notifiche-push)
12. [Risoluzione CodiceAzienda](#12-codice-azienda)
13. [Branding Dinamico](#13-branding)
14. [Build e Distribuzione APK](#14-build-apk)
15. [Configurazione Ambiente Docker](#15-docker)
16. [Guida alla Ricostruzione](#16-ricostruzione)

---

## 1. Panoramica

**INTHEGRA Mobile** è l'applicazione Flutter dedicata ai dipendenti delle aziende clienti della piattaforma INTHEGRA (app_gestione). Permette ai dipendenti di:

- Autenticarsi tramite CodiceAzienda + email + password
- Chattare con colleghi (1-to-1) e in stanze di gruppo (Punti di Servizio)
- Ricevere/caricare documenti aziendali (buste paga, certificati, ecc.)
- Ricevere notifiche push (Firebase FCM)
- Visualizzare il profilo e gestire l'account
- Accettare la privacy policy GDPR al primo accesso

Il backend di riferimento è `app_gestione` (Laravel). La comunicazione avviene tramite **REST API con autenticazione Bearer Token**.

---

## 2. Stack Tecnologico

| Componente | Tecnologia | Versione |
|---|---|---|
| Framework | Flutter | Stabile (≥ 3.x) |
| Linguaggio | Dart | ≥ 3.0.0 < 4.0.0 |
| State Management | Provider | ^6.1.1 |
| HTTP Client | Dio | ^5.4.0 |
| Storage locale | SharedPreferences | ^2.2.0 |
| File system | path_provider | ^2.1.1 |
| Internazionalizzazione | intl | ^0.19.0 |
| File picker | file_picker | ^8.0.0 |
| URL launcher | url_launcher | ^6.3.2 |
| Push Notifications | firebase_messaging | ^16.3.0 |
| Versioning info | package_info_plus | ^8.0.0 |
| Icone launcher | flutter_launcher_icons | ^0.13.1 |

> **Rimosso in v1.1.0:** `cookie_jar`, `dio_cookie_manager` (sostituiti da Bearer Token)

---

## 3. Architettura

```
┌─────────────────────────────────┐
│           UI (Screens)          │
│  login, contacts, chat,         │
│  documents, profile, register   │
└──────────────┬──────────────────┘
               │ Consumer<Provider>
               ▼
┌─────────────────────────────────┐
│      State Management           │
│  AuthProvider  │  ChatProvider  │
│  DocProvider   │  ConfigProvider│
│  ThemeProvider                  │
└──────────────┬──────────────────┘
               │ calls
               ▼
┌─────────────────────────────────┐
│          ApiService             │
│  Dio HTTP Client                │
│  + Bearer Token Interceptor     │
│  + SSL bypass (device fisici)   │
│  + SharedPreferences (persist)  │
└──────────────┬──────────────────┘
               │ HTTPS/HTTP
               ▼
    ┌──────────────────────┐
    │   Backend Laravel    │
    │   (app_gestione)     │
    │   API Mobile v1      │
    └──────────────────────┘
```

### Flusso login completo
```
1. User inserisce: CodiceAzienda, Email, Password
2. AuthProvider.login()
   a. resolveCompanyCode(CodiceAzienda) → GET https://www.inthegra.it/app_gestione/public/app_clients.json
   b. Trova URL server associato al codice
   c. setBaseUrl(serverUrl) → persiste in SharedPreferences
   d. POST api/login {email, password}
   e. Risposta: { success:true, token:"abc...", user:{...} }
   f. setToken(token) → salva in SharedPreferences + attiva interceptor Dio
   g. Crea UserModel (con apiToken incluso)
   h. persistUser() → cache JSON in SharedPreferences
3. Navigazione → MainShellScreen (se privacy accettata)
              → PrivacyScreen (se privacy non accettata)
```

---

## 4. Struttura del Progetto

```
Progetto-Flutter/
├── lib/
│   ├── main.dart                  ← Entry point, Provider setup, Firebase init
│   │
│   ├── models/
│   │   ├── user_model.dart        ← Utente autenticato (con apiToken)
│   │   ├── contact_model.dart     ← Contatto chat
│   │   ├── message_model.dart     ← Messaggio 1-to-1
│   │   ├── room_model.dart        ← Stanza di gruppo (Punto di Servizio)
│   │   ├── group_chat_message_model.dart ← Messaggio di gruppo
│   │   └── document_model.dart    ← Documento aziendale
│   │
│   ├── providers/
│   │   ├── auth_provider.dart     ← Auth state: login, logout, register, privacy
│   │   ├── chat_provider.dart     ← Chat state: contatti, messaggi, polling
│   │   ├── document_provider.dart ← Documenti: lista, upload, presa visione
│   │   ├── config_provider.dart   ← Config app: URL server, branding
│   │   └── theme_provider.dart    ← Tema light/dark
│   │
│   ├── services/
│   │   └── api_service.dart       ← HTTP client centralizzato con token
│   │
│   ├── screens/
│   │   ├── login_screen.dart      ← Login: CodiceAzienda + email + password
│   │   ├── register_screen.dart   ← Registrazione nuovo account
│   │   ├── privacy_screen.dart    ← Accettazione privacy GDPR
│   │   ├── main_shell_screen.dart ← Shell con bottom navigation bar
│   │   ├── contacts_screen.dart   ← Lista contatti chat + stanze
│   │   ├── chat_screen.dart       ← Chat 1-to-1 con polling
│   │   ├── group_chat_screen.dart ← Chat di gruppo con polling
│   │   ├── documents_screen.dart  ← Documenti (ricevuti + inviati + upload)
│   │   └── profile_screen.dart    ← Profilo utente + logout + elimina account
│   │
│   ├── utils/
│   │   ├── web_utils_web.dart     ← Utility specifiche web (dart:js)
│   │   └── web_utils_stub.dart    ← Stub per build non-web
│   │
│   └── widgets/
│       └── update_checker_wrapper.dart ← Controllo aggiornamenti app
│
├── android/                       ← Configurazione Android (google-services.json)
├── ios/                           ← Configurazione iOS
├── assets/
│   └── icon/
│       ├── logo.png               ← Logo INTHEGRA quadrato
│       ├── logo_orizzontale.png   ← Logo orizzontale
│       └── app_icon_square.png    ← Icona launcher (512x512)
├── pubspec.yaml                   ← Dipendenze e configurazione
└── Makefile                       ← Comandi utili (build, clean, ecc.)
```

---

## 5. Schermate e Navigazione

### Flusso di navigazione
```
Avvio app
    │
    ├─► [Utente NON autenticato]
    │       → LoginScreen
    │           ├─► [Login OK + privacy OK] → MainShellScreen
    │           ├─► [Login OK + privacy NO] → PrivacyScreen → MainShellScreen
    │           └─► RegisterScreen
    │
    └─► [Utente autenticato (token in SharedPrefs)]
            → MainShellScreen (diretto, senza login)
```

### MainShellScreen — Bottom Navigation Bar
```
Tab 0: Contatti/Chat (ContactsScreen)
Tab 1: Documenti (DocumentsScreen)
Tab 2: Profilo (ProfileScreen)
```

### Dettaglio schermate

#### LoginScreen (`login_screen.dart`)
- Tre campi: CodiceAzienda, Email, Password
- Risolve il server tramite `app_clients.json` (CDN centrale)
- Mostra errori dal server (credenziali errate, server non raggiungibile)
- Link a RegisterScreen

#### ContactsScreen (`contacts_screen.dart`)
- Tab: Chat Privata | Stanze di Gruppo
- Mostra badge non letti per ogni contatto
- Navigazione a ChatScreen / GroupChatScreen

#### ChatScreen (`chat_screen.dart`)
- Polling ogni 3 secondi per nuovi messaggi
- Invio testo con `POST /api/chat/messages`
- Visualizza mittente + timestamp

#### GroupChatScreen (`group_chat_screen.dart`)
- Polling ogni 3 secondi
- Stanze = Punti di Servizio (luoghi di lavoro)
- `POST /api/chat/rooms/messages`

#### DocumentsScreen (`documents_screen.dart`)
- Tab: Ricevuti (dall'azienda) | Inviati (dall'utente)
- Upload: file_picker → multipart POST
- Presa visione: `POST /api/mobile/documenti/{id}/presa-visione`
- Download/apertura file

#### ProfileScreen (`profile_screen.dart`)
- Mostra nome, cognome, email, ruolo
- Bottone logout: cancella token + cache
- Bottone elimina account: `DELETE /api/user/account`

#### PrivacyScreen (`privacy_screen.dart`)
- Testo informativa privacy
- `POST /api/chat/accept-privacy` → aggiorna DB e sblocca accesso

---

## 6. Provider (State Management)

### AuthProvider (`auth_provider.dart`)

```dart
// Stato esposto
UserModel? currentUser     // Utente autenticato
bool isAuthenticated       // true se currentUser != null
bool isLoading             // Durante operazioni async
String? errorMessage       // Errore da mostrare in UI
bool hasAcceptedPrivacy    // currentUser.privacyAccettata

// Metodi principali
Future<bool> login(companyCode, email, password)
Future<bool> register(companyCode, nome, cognome, email, password, cf, dataNascita)
Future<bool> acceptPrivacy()
Future<bool> deleteAccount()
Future<void> logout()
void clearError()
```

**Persistenza:** Il `UserModel` serializzato (con `api_token` incluso) viene salvato in `SharedPreferences` alla chiave `cached_user`. Al riavvio, viene caricato e il token viene reinserito in `ApiService`.

### ChatProvider (`chat_provider.dart`)

```dart
// Stato esposto
List<ContactModel> contacts
List<MessageModel> messages
List<RoomModel> rooms
List<GroupChatMessageModel> roomMessages
int unreadCount
bool isLoadingContacts, isLoadingMessages, isLoadingRooms

// Metodi principali
Future<void> fetchContacts()
Future<void> fetchRooms()
Future<void> fetchMessages(int contactId)
Future<void> fetchRoomMessages(int roomId)
Future<bool> sendMessage(int contactId, String text)
Future<bool> sendRoomMessage(int roomId, String text)
Future<void> fetchUnreadCount()
void startPolling(ContactModel contact)    // Timer 3s
void stopPolling()
void startRoomPolling(RoomModel room)      // Timer 3s
void stopRoomPolling()
```

### DocumentProvider (`document_provider.dart`)

```dart
// Stato esposto
List<DocumentModel> documents
List<DocumentModel> receivedDocuments    // dove isCompanySent=true
List<DocumentModel> sentDocuments        // dove isCompanySent=false
int unreadDocumentsCount
bool isLoading

// Metodi principali
Future<void> fetchDocuments()
Future<bool> markAsRead(int documentId)
Future<bool> uploadDocument({title, type, bytes, filename})
```

---

## 7. Servizi

### ApiService (`services/api_service.dart`)

**Classe singleton** (passata via Provider) che gestisce tutta la comunicazione HTTP.

```dart
// Costanti
static const String _baseUrlKey = 'api_base_url';   // Key SharedPreferences
static const String _tokenKey   = 'api_bearer_token'; // Key SharedPreferences
static const String masterConfigUrl = 'https://www.inthegra.it/app_gestione/public/app_clients.json';

// Proprietà
late final Dio dio          // Client HTTP con interceptor
String _baseUrl             // URL base server corrente
String? _bearerToken        // Bearer token attivo
```

#### Interceptor Bearer Token
```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    if (_bearerToken != null && _bearerToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_bearerToken';
    }
    return handler.next(options);
  },
));
```

#### Metodi pubblici
```dart
Future<void> init()                     // Carica URL e token da SharedPrefs
Future<void> setToken(String token)     // Imposta e persiste il token
Future<void> clearToken()               // Cancella token (logout)
Future<void> clearSession()             // = clearToken (pulizia completa)
Future<void> setBaseUrl(String url)     // Imposta e persiste URL server
Future<String?> resolveCompanyCode(String code) // Risolve codice → URL
Future<Map?> checkAppUpdate()           // GET /api/mobile/version
Future<void> updateDeviceToken(String fcmToken) // POST /api/user/device-token
```

#### SSL bypass (device fisici Android)
```dart
// Abilitato su device non-web per gestire certificati self-signed o catena SSL incompleta
dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  },
);
```
> ⚠️ **Produzione:** Se il server ha SSL valido e completo, rimuovere questo bypass.

---

## 8. Modelli Dati

### UserModel

```dart
int id
String nome, cognome, email
String ruolo              // 'superadmin' | 'admin' | 'responsabile' | 'operatore'
String ruoloEtichetta     // Label leggibile
bool privacyAccettata
bool attivoChatEnabled
String? apiToken          // Bearer token (persiste in SharedPrefs via toJson)

// Getter
String get nomeCompleto   // '$nome $cognome'
```

### ContactModel
```dart
int id
String nomeCompleto
String ruolo, ruoloEtichetta
int unreadCount
```

### MessageModel
```dart
int id
int mittente, destinatario
String testo
bool isOwn              // true se mittente == currentUser.id
String? nomeCompleto    // mittente
DateTime createdAt
```

### RoomModel
```dart
int id
String nome             // Nome Punto di Servizio
String? indirizzo
int unreadCount
```

### GroupChatMessageModel
```dart
int id
int userId
int puntoServizioId
String testo
String? nomeCompleto
bool isOwn
DateTime createdAt
```

### DocumentModel
```dart
int id
String titolo, tipo     // tipo: 'busta_paga' | 'certificato' | 'comunicazione' | ecc.
String direzione        // 'azienda_a_dipendente' | 'dipendente_a_azienda'
String? nomeFile, descrizione
int? dimensioneByte
DateTime? presaVisioneAt    // null = non letto
DateTime createdAt

// Getter
bool get isCompanySent  // direzione == 'azienda_a_dipendente'
bool get isRead         // presaVisioneAt != null
```

---

## 9. Autenticazione Bearer Token

### Flusso completo (dal primo avvio)

```
1. PRIMO AVVIO
   ├── ApiService.init() → carica baseUrl da SharedPrefs (o default)
   ├── AuthProvider._loadPersistedUser() → cerca 'cached_user' in SharedPrefs
   └── Se non trovato → mostra LoginScreen

2. LOGIN
   ├── resolveCompanyCode() → scarica app_clients.json, trova URL
   ├── setBaseUrl() → salva in SharedPrefs
   ├── POST api/login → riceve { token, user }
   ├── setToken(token) → salva in SharedPrefs['api_bearer_token']
   ├── UserModel.fromJson({ ...user, api_token: token })
   └── persistUser() → salva JSON in SharedPrefs['cached_user']

3. USO NORMALE
   └── Ogni richiesta Dio → interceptor aggiunge Authorization: Bearer <token>

4. RIAVVIO APP
   ├── ApiService.init() → carica baseUrl da SharedPrefs
   ├── AuthProvider._loadPersistedUser() → carica cached_user
   ├── Estrae api_token da cached_user
   └── ApiService.setToken(token) → interceptor riattivato

5. LOGOUT
   ├── ApiService.clearSession() → SharedPrefs['api_bearer_token'] = null
   ├── clearPersistedUser() → rimuove 'cached_user'
   └── _currentUser = null → UI torna a LoginScreen
```

---

## 10. Integrazione API Server

Base URL: configurabile dall'utente tramite `resolveCompanyCode`.

### Struttura risposta standard
```json
{ "success": true,  "data": {...} }
{ "success": false, "message": "Testo errore" }
```

### Timeout configurato
```dart
dio.options.connectTimeout = const Duration(seconds: 10);
dio.options.receiveTimeout = const Duration(seconds: 10);
```

### Gestione errori
Tutti i provider usano `DioException catch (e)` con accesso a `e.response?.data?['message']` per mostrare errori del server in UI.

Codici HTTP gestiti:
- `200` → successo
- `401` → token non valido → fare logout
- `403` → privacy non accettata → PrivacyScreen
- `422` → errori di validazione → mostrare messaggi campo

---

## 11. Notifiche Push (FCM)

### Configurazione
- File: `android/app/google-services.json` (non nel repository, da aggiungere manualmente)
- Libreria: `firebase_messaging ^16.3.0`

### Flusso registrazione
1. Al login, `AuthProvider._syncDeviceToken()` viene chiamato
2. Richiede permesso notifiche all'utente
3. Se concesso → `FirebaseMessaging.instance.getToken()`
4. `POST /api/user/device-token { "token": "<fcm_token>" }` → salva in `users.fcm_token`

### Gestione in background
- Il `main.dart` registra un `FirebaseMessaging.onBackgroundMessage` handler
- Le notifiche vengono inviate dal server tramite Firebase Admin SDK

---

## 12. Risoluzione CodiceAzienda

### Meccanismo
Il file `app_clients.json` è ospitato su un CDN centrale e contiene la mappatura:

```json
{
  "RIST001": "https://cliente1.inthegra.it/app_gestione/public/",
  "RIST002": "https://cliente2.inthegra.it/app_gestione/public/",
  "LOCAL":   "http://localhost/app_gestione/public/"
}
```

### URL del file
```dart
static const String masterConfigUrl =
    'https://www.inthegra.it/app_gestione/public/app_clients.json';
```

### Normalizzazione URL
Il metodo `_normalizeUrl()` in `ApiService`:
- Aggiunge `http://` per localhost/IP locali
- Aggiunge `https://` per domini esterni
- Assicura che termini con `/`

---

## 13. Branding Dinamico

L'endpoint `GET /api/theme` restituisce i colori e i loghi configurati dall'amministratore:

```json
{
  "colore_primario": "#e65c00",
  "colore_secondario": "#198754",
  "logo_url": "https://.../storage/logo.png",
  "nome_applicazione": "INTHEGRA"
}
```

Gestito da `ConfigProvider` che aggiorna i `ThemeData` dell'app dinamicamente.

---

## 14. Build e Distribuzione APK

### Prerequisiti
- Flutter SDK installato e nel PATH
- Android SDK installato
- `android/app/google-services.json` presente

### Aggiornare l'icona launcher
1. Posizionare l'icona quadrata (min 512×512px) in `assets/icon/app_icon_square.png`
2. Configurato in `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: true
     image_path: "assets/icon/app_icon_square.png"
     remove_alpha_ios: true
   ```
3. Eseguire:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### Build APK Release
```bash
# Aggiorna dipendenze
flutter pub get

# Analisi statica (no errori critici)
flutter analyze lib/

# Build APK universale
flutter build apk --release

# Output:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build APK per architettura specifica (consigliato per produzione)
```bash
# Genera APK separati per arm64-v8a (moderna), armeabi-v7a (vecchia)
flutter build apk --release --split-per-abi

# Output:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← consigliato
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### Versioning
Il version code è in `pubspec.yaml`:
```yaml
version: 1.1.0+2
#         │   └── versionCode (Android build number)
#         └────── versionName (visibile all'utente)
```

Storico versioni:
| Versione | Build | Cambiamenti |
|---|---|---|
| 1.0.0 | 1 | Prima release |
| 1.0.1 | 1 | Fix minori |
| 1.1.0 | 2 | **Migrazione a Bearer Token** (rimossi cookie) |

### Firma APK (produzione)
Creare `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=<path/to/keystore.jks>
```
Riferirlo in `android/app/build.gradle`.

---

## 15. Configurazione Ambiente Docker

Il file `docker-compose.yml` include:

| Servizio | Porta | Descrizione |
|---|---|---|
| Flutter Web | 8090 | App web in debug mode |
| Flutter DevTools | 9290 | Debug tools |
| PHP Backend | 8084 | API Laravel |
| PhpMyAdmin | 8083 | Gestione DB |
| MySQL | 3309 | Database (porta custom) |
| MongoDB | 27018 | (opzionale, porta custom) |
| Mongo Express | 8085 | Gestione MongoDB |

Le porte sono configurabili in `.env` (root del progetto Flutter).

---

## 16. Guida alla Ricostruzione

### 16.1 Prerequisiti
```bash
flutter doctor   # Verifica tutto l'ambiente
# Deve mostrare ✓ per: Flutter, Android toolchain, VS Code (o altro IDE)
```

### 16.2 Clonare e configurare
```bash
git clone <repo-url>
cd Progetto-Flutter

# Aggiungere il file Firebase (NON è nel repository)
# Copiare google-services.json in: android/app/google-services.json

# Installare dipendenze
flutter pub get

# Generare icone launcher
flutter pub run flutter_launcher_icons
```

### 16.3 File critici da aggiungere manualmente (non in git)
| File | Dove | Contenuto |
|---|---|---|
| `google-services.json` | `android/app/` | Firebase config (dal Firebase Console) |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase config per iOS |
| Keystore (`.jks`) | path configurato | Firma APK per produzione |
| `key.properties` | `android/` | Riferimento al keystore |

### 16.4 Aggiornare l'URL del server
Per puntare a un nuovo server, aggiornare il file ospitato su:
```
https://www.inthegra.it/app_gestione/public/app_clients.json
```
Aggiungere/modificare la voce corrispondente al CodiceAzienda.

### 16.5 File critici del codice sorgente
| File | Importanza | Note |
|---|---|---|
| `lib/services/api_service.dart` | 🔴 Critico | HTTP client + Bearer Token interceptor |
| `lib/providers/auth_provider.dart` | 🔴 Critico | Login, logout, token persistenza |
| `lib/models/user_model.dart` | 🔴 Critico | Include apiToken per persistenza |
| `lib/main.dart` | 🔴 Critico | Entry point, Provider setup, Firebase |
| `pubspec.yaml` | 🔴 Critico | Dipendenze e versioning |
| `android/app/build.gradle` | 🟠 Alto | MinSdk, targetSdk, firma |
| `assets/icon/app_icon_square.png` | 🟠 Alto | Icona launcher (512×512px) |

### 16.6 Debug su dispositivo fisico

```bash
# Lista dispositivi collegati
flutter devices

# Esegui su dispositivo specifico
flutter run -d <device-id>

# Con log dettagliati
flutter run -d <device-id> --verbose

# Ispeziona con DevTools
flutter run --devtools-server-address=localhost:9290
```

### 16.7 Problemi comuni

| Problema | Causa | Soluzione |
|---|---|---|
| `401 Unauthorized` | Token non inviato | Verificare `_bearerToken` in `ApiService` |
| `DioException: Connection refused` | URL server sbagliato | Verificare `app_clients.json` e il CodiceAzienda |
| App si disconnette al riavvio | Token non persistito | Verificare `_loadPersistedUser()` e `setToken()` |
| Icone mancanti | `flutter_launcher_icons` non eseguito | Eseguire `flutter pub run flutter_launcher_icons` |
| Build fallisce (Gradle) | JDK o SDK mancante | Verificare `flutter doctor` |
| FCM non funziona | `google-services.json` mancante | Aggiungere il file da Firebase Console |

---

*Documento mantenuto da: Pietro Vasta — pvdesk@github*  
*Ultima modifica: giugno 2026*
