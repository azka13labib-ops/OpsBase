import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/user_provider.dart';
import 'services/preferences_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: sebelum production, tambahkan Firebase.initializeApp() di sini
  // setelah file google-services.json / GoogleService-Info.plist ditambahkan.
  // Lihat: https://firebase.google.com/docs/flutter/setup

  await initializeDateFormatting('id_ID', null);
  await AuthService.init();
  
  final prefs = PreferencesProvider();
  await prefs.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: prefs),
      ],
      child: const CommunitySuiteApp(),
    ),
  );
}

class CommunitySuiteApp extends StatelessWidget {
  const CommunitySuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    return MaterialApp(
      title: 'Community Suite',
      debugShowCheckedModeBanner: false,
      themeMode: prefs.themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5865F2),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F7),
          foregroundColor: Color(0xFF1D1D1F),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF5865F2),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (AuthService.isLoggedIn) {
            return const HomeShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
