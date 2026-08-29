import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'shared/screens/login_screen.dart';

/// SmartTransport GH - Passenger App Entry Point
void main() {
  runApp(
    const ProviderScope(
      child: PassengerApp(),
    ),
  );
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTransport GH - Passenger',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
