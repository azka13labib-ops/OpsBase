import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/user_provider.dart';
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
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const CommunitySuiteApp(),
    ),
  );
}

class CommunitySuiteApp extends StatelessWidget {
  const CommunitySuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5865F2), // warna khas Discord "blurple"
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
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
