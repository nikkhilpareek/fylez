import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Enable for web development
      builder: (context) => const FylezApp(),
    ),
  );
}

class FylezApp extends StatelessWidget {
  const FylezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fylez - Blockchain Storage',
      debugShowCheckedModeBanner: false,
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
