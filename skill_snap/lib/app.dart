import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import './screens/dashboard/dashboard_screen.dart';
import './services/superbase_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'skill snap',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: user != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
