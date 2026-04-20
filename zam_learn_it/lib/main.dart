import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ZamTranslateApp());
}

class ZamTranslateApp extends StatelessWidget {
  const ZamTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zam Learn It',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
