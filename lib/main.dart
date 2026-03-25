import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RelevixApp());
}

class RelevixApp extends StatelessWidget {
  const RelevixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relevix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
