import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/services/api_client.dart';
import 'shared/theme/app_theme.dart';
import 'shared/screens/login_screen.dart';

/// SmartTransport GH — Unified App Entry Point
/// Routes to role-specific dashboard after login based on user role.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadCustomUrl();
  runApp(
    const ProviderScope(
      child: SmartTransportApp(),
    ),
  );
}

class SmartTransportApp extends StatelessWidget {
  const SmartTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTransport GH',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
