import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const VielApp());
}

class VielApp extends StatelessWidget {
  const VielApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veil',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
