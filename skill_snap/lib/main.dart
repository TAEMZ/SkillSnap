import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import './screens/auth/auth_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'shared/provider/skill_stats_provider.dart';
import './screens/chat/message_provider.dart';
import 'shared/provider/theme_provider.dart';
import './utils/main_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://itfwuizeohiwavlzdkqr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0Znd1aXplb2hpd2F2bHpka3FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NTM4ODEsImV4cCI6MjA2ODIyOTg4MX0.PQHBvdm1OkR9Qz6A6h9wq1OWEkitJLOXY1QiVH48s3Q',
  );

  Animate.restartOnHotReload = true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => SkillStatsProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSnap',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
      builder: (context, child) {
        return Animate(effects: const [FadeEffect()], child: child!);
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Animate(
      effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
      child:
          auth.currentUser != null
              ? const PersistentNavigation()
              : const LoginScreen(),
    );
  }
}

class AppThemes {
  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.teal.shade700,
      secondary: Colors.teal.shade400,
      surface: Colors.white,
      error: Colors.red.shade400,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    useMaterial3: true,
  );

  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Colors.teal.shade800,
      secondary: Colors.teal.shade600,
      surface: const Color(0xFF121212),
      error: Colors.red.shade700,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade800,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      color: const Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
    ),
    useMaterial3: true,
  );
}
