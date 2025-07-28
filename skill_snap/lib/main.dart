import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './screens/auth/auth_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'shared/provider/skill_stats_provider.dart';
import './screens/chat/message_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://itfwuizeohiwavlzdkqr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0Znd1aXplb2hpd2F2bHpka3FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NTM4ODEsImV4cCI6MjA2ODIyOTg4MX0.PQHBvdm1OkR9Qz6A6h9wq1OWEkitJLOXY1QiVH48s3Q',
  );

  runApp(
    MultiProvider(
      providers: [
        // Add to your MultiProvider
        ChangeNotifierProvider(create: (_) => SkillStatsProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSnap',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Consumer<AuthController>(
        builder: (context, auth, child) {
          return auth.currentUser != null
              ? const DashboardScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
