import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/main_shell_screen.dart';
import 'widgets/update_checker_wrapper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Gestione messaggi in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Qui puoi gestire eventuali notifiche in-app custom
  });

  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: themeProvider.appName,
          debugShowCheckedModeBanner: false,
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
