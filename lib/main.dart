import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/config_provider.dart';
import 'providers/notification_provider.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'inthegra_channel_v2',
  'Notifiche InThegra',
  description: 'Canale usato per le notifiche di InThegra.',
  importance: Importance.max,
  playSound: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp();

  // Inizializza Flutter Local Notifications e crea il canale per Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_notification');
  const initializationSettingsIOS = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    // Gestione opzionale del tap quando l'app è in foreground
  });

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
  // quando l'app è in background. In foreground, mostriamo noi la notifica.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'ic_stat_notification',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
    
    // Aggiorniamo il badge sull'icona dell'app
    AppBadgePlus.isSupported().then((isSupported) {
      if (isSupported) {
        AppBadgePlus.updateBadge(1);
      }
    });
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
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(apiService),
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
    
    // Rimuovi il badge quando l'app viene aperta
    AppBadgePlus.isSupported().then((isSupported) {
      if (isSupported) {
        AppBadgePlus.updateBadge(0);
      }
    });
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
    } else if (type == 'comunicazione' || type == 'notifica') {
      // Tab 2 = Notifiche
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen(initialTab: 2)),
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

