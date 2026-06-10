# CHANGELOG — INTHEGRA Mobile (Flutter)

Tutte le modifiche rilevanti al progetto sono documentate in questo file.  
Formato: [Semantic Versioning](https://semver.org/). Data: YYYY-MM-DD.

---

## [1.1.0] — 2026-06-10

### 🔴 Breaking Change — Migrazione Autenticazione
Rimosso il sistema basato su Cookie (sessioni PHP) a favore di **Bearer Token stateless**.

### Aggiunto
- `ApiService.setToken()` — persiste il Bearer Token in `SharedPreferences`
- `ApiService.clearToken()` / `clearSession()` — pulizia al logout
- `ApiService._loadToken()` — ripristina token al riavvio app
- Interceptor Dio automatico: aggiunge `Authorization: Bearer <token>` a ogni richiesta
- `UserModel.apiToken` — campo token nel modello utente (persiste in cache)
- `UserModel.attivoChatEnabled` — campo accesso chat

### Rimosso
- `cookie_jar ^4.0.8` — dipendenza rimossa da pubspec.yaml
- `dio_cookie_manager ^3.1.1` — dipendenza rimossa da pubspec.yaml
- `CookieManager` e `PersistCookieJar` — rimossi da `ApiService`
- `ApiService.clearCookies()` — sostituito da `clearSession()`

### Modificato
- `AuthProvider.login()` — ora legge `data['token']` dalla risposta server
- `AuthProvider._loadPersistedUser()` — ora ripristina il token in `ApiService`
- `AuthProvider.logout()` — chiama `clearSession()` invece di `clearCookies()`
- `AuthProvider.deleteAccount()` — chiama `clearSession()` invece di `clearCookies()`
- `pubspec.yaml` — versione bumped a 1.1.0+2

### Bug Fix
- **CRITICO:** L'app non riusciva a fare login perché il token Bearer restituito dal server veniva completamente ignorato
- **CRITICO:** Al riavvio dell'app, il token non veniva ripristinato e le chiamate API fallivano con 401

---

## [1.0.1] — 2026-06-09

### Aggiunto
- Chat di gruppo (stanze = Punti di Servizio)
- `GroupChatMessageModel`, `GroupChatScreen`
- `RoomModel`, rotte `/api/chat/rooms/*`

### Modificato
- `ChatProvider` — aggiunto `startRoomPolling()`, `stopRoomPolling()`, `fetchRooms()`

---

## [1.0.0] — 2026-05-29

### Prima release
- Login con CodiceAzienda + email + password
- Risoluzione server tramite `app_clients.json` centrale
- Chat 1-to-1 con polling ogni 3 secondi
- Gestione documenti (ricezione/invio)
- Notifiche push Firebase FCM
- Accettazione privacy GDPR
- Profilo utente e logout
- Schermata di registrazione
- Controllo aggiornamenti app
- Branding dinamico da API server
