import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GameMarketApp());
}

class GameMarketApp extends StatelessWidget {
  const GameMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7B3FFF);
    const bgColor = Color(0xFF120023);
    const accentPink = Color(0xFFFF4E87);
    const accentOrange = Color(0xFFFFA000);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game ID Market',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: accentPink,
          surface: const Color(0xFF1C0733),
          background: bgColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C0733),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFFB9A9D9)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF24103C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF8E7BB7)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
