import 'package:flutter/material.dart';
import 'landing_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Response App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDC2626)),
        useMaterial3: true,
      ),
      // Step 1: Set LandingScreen as the app entry point
      home: const LandingScreen(),
    );
  }
}