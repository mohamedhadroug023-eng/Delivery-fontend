import 'package:flutter/material.dart';

import 'screens/role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const HadrougDeliveryApp());
}

// ============================================================
// HADROUG DELIVERY APP
// ============================================================

class HadrougDeliveryApp extends StatelessWidget {
  const HadrougDeliveryApp({super.key});

  static const Color primaryOrange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'HADROUG DELIVERY',

      // ========================================================
      // THEME
      // ========================================================

      theme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Arial',

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryOrange,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF7F7F7),

        appBarTheme: const AppBarTheme(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        // ======================================================
        // INPUTS
        // ======================================================

        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryOrange,
              width: 2,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),

        // ======================================================
        // ELEVATED BUTTON
        // ======================================================

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,

            minimumSize: const Size(
              double.infinity,
              52,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // ======================================================
        // CARD
        // ======================================================

        cardTheme: CardThemeData(
          elevation: 2,

          color: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // ========================================================
      // RTL
      // ========================================================

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },

      // ========================================================
      // FIRST SCREEN
      // ========================================================

      home: const RoleSelectionScreen(),
    );
  }
}
