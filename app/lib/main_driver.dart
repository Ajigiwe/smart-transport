import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'shared/screens/login_screen.dart';

/// SmartTransport GH - Driver App Entry Point
void main() {
  runApp(
    const ProviderScope(
      child: DriverApp(),
    ),
  );
}

class DriverApp extends StatelessWidget {
  const DriverApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTransport GH - Driver',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
