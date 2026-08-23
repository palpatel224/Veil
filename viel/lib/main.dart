import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/main_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Could not load .env file: $e");
  }
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
