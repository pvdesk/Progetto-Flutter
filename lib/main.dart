import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/document_provider.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/main_shell_screen.dart';
import 'widgets/update_checker_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
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
    return MaterialApp(
      title: 'Connexia Chat',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF6B35),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFF8C61),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const UpdateCheckerWrapper(
        child: AuthGate(),
      ),
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
