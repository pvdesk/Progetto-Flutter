# INTHEGRA Mobile

App mobile Flutter per i dipendenti della piattaforma INTHEGRA (ristorazione collettiva).

## Funzionalità
- Login con CodiceAzienda + email + password
- Chat 1-to-1 e stanze di gruppo
- Gestione documenti (ricezione + invio)
- Notifiche push (Firebase FCM)
- Profilo utente

## Stack
**Flutter 3+** · **Dart 3** · **Provider** · **Dio** · **Firebase Messaging**

## Documentazione
→ [MANUALE_TECNICO.md](MANUALE_TECNICO.md) — Documentazione tecnica completa

## Setup
```bash
flutter pub get
# Aggiungere android/app/google-services.json (da Firebase Console)
flutter pub run flutter_launcher_icons
```

## Build APK
```bash
# APK universale
flutter build apk --release

# APK ottimizzati per architettura (consigliato)
flutter build apk --release --split-per-abi
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## Versione corrente: 1.1.0+2
- Migrazione da Cookie Auth a Bearer Token
- Supporto `apiToken` in `UserModel`
- Rimossi `cookie_jar` e `dio_cookie_manager`
