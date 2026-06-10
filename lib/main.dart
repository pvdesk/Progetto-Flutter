import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/config_provider.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/main_shell_screen.dart';
import 'widgets/update_checker_wrapper.dart';

// ── Handler background/terminated — richiamato da Google Play Services ────────
// Funziona anche con app killata: FCM è gestito a livello OS
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Il messaggio è già mostrato dall'OS via il canale 'inthegra_channel'
}

// Navigatore globale per navigare da notifica tap senza BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp();

  // Registra handler per messaggi quando app è in background o terminata
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mostra notifiche anche con app in foreground (iOS + configura Android)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Su Android: i messaggi FCM con payload "notification" vengono mostrati
  // automaticamente dall'OS via il canale 'inthegra_channel' (AndroidManifest)
  // anche con app killata — nessun plugin aggiuntivo necessario.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Qui possiamo aggiornare badge o stato in-app se necessario
    debugPrint('[FCM Foreground] ${message.notification?.title}');
  });

  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<ConfigProvider>(
          create: (_) => ConfigProvider(apiService),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(apiService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(apiService),
        ),
        ChangeNotifierProvider<DocumentProvider>(
          create: (_) => DocumentProvider(apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  /// Gestisce la navigazione quando l'utente tocca una notifica FCM.
  /// Funziona sia quando l'app è in background che terminata (cold start).
  void _setupNotificationNavigation() {
    // App in background → utente tocca la notifica
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App terminata → utente tocca la notifica (cold start)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    // Naviga alla schermata giusta in base al tipo di notifica
    if (type == 'chat' || type == 'chat_group') {
      // Tab 0 = Contatti/Chat
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen(initialTab: 0)),
        (route) => false,
      );
    } else if (type == 'documento') {
      // Tab 1 = Documenti
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen(initialTab: 1)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: themeProvider.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: themeProvider.primaryColor,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.dark(
              primary: themeProvider.primaryColor,
              secondary: themeProvider.secondaryColor,
              surface: const Color(0xFF1E293B),
            ),
            useMaterial3: true,
          ),
          home: const UpdateCheckerWrapper(
            child: AuthGate(),
          ),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Rotte condizionali basate sullo stato di autenticazione e privacy
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authProvider.hasAcceptedPrivacy) {
      return const PrivacyScreen();
    }

    return const MainShellScreen();
  }
}

