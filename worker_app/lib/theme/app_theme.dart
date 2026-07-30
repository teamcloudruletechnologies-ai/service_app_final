import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand Palette ─────────────────────────────────────────────
  static const primary   = Color(0xFF006837); // Rich Emerald Green
  static const sandal    = Color(0xFFE3D0BA); // Warm Sandal
  static const olive     = Color(0xFF4A5343); // Muted Olive Green
  static const milkWhite = Color(0xFFF5F5F3); // Crisp Milk White
  static const matteBlack = Color(0xFF1A1A1A); // Pure Matte Black
  static const zomatoRed = Color(0xFFE23744); // Zomato Red (pending/new)

  // Aliases for legacy usage
  static const primaryDark = Color(0xFF004D28);
  static const accent      = Color(0xFFE3D0BA); // Warm Sandal
  static const secondary   = Color(0xFF4A5343); // Olive
  static const surface     = Color(0xFFF5F5F3); // Milk White
  static const card        = Colors.white;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary:   primary,
        secondary: olive,
        tertiary:  sandal,
        surface:   surface,
        onSurface: primary,
        surfaceContainer:        Colors.white,
        surfaceContainerHigh:    Colors.white,
        surfaceContainerHighest: Colors.white,
      ),
      scaffoldBackgroundColor: surface,

      // ─── AppBar ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),

      // ─── Bottom Nav ───────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.white,
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.2)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade600, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.normal, fontSize: 12);
        }),
      ),

      // ─── Card ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ─── Input Fields ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sandal, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sandal, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: olive, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFF5C5C5A)),
        hintStyle: const TextStyle(color: Color(0xFF9A978F)),
      ),

      // ─── Elevated Button ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: milkWhite,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button ──────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),

      // ─── Text Button ──────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: olive,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ─── FAB ──────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: olive,
        foregroundColor: milkWhite,
      ),

      // ─── Switch ───────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? olive : const Color(0xFF9A978F);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? const Color(0xFFD0D9CC) : const Color(0xFFE0DDD8);
        }),
      ),

      // ─── Chip ─────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: milkWhite,
        selectedColor: sandal,
        labelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        side: const BorderSide(color: sandal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ─── Divider ──────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE3D0BA),
        thickness: 1,
      ),
    );
  }
}
