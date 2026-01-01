import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color purple = Color(0xFF6C63FF);
  static const Color darkPurple = Color(0xFF4C2D86);
  static const Color orange = Color(0xFFFF8F00);
  static const Color grey = Color(0xFFF0F0F0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteBackground = Color(0xFFF8F8FA);
  static const Color black = Color(0xFF2D2D2D); // Softer black
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white70;
}

class AppTheme {
  static InputDecorationTheme _buildInputDecoration(
    Color fillColor,
    Color borderColor,
    Color focusColor,
    Color labelColor,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(color: labelColor),
      floatingLabelStyle: TextStyle(color: focusColor),
      prefixIconColor: labelColor.withValues(alpha: 0.7),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.whiteBackground,
      primaryColor: AppColors.purple,
      cardColor: Colors.white,
      hintColor: Colors.grey[500],
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.purple,
        secondary: AppColors.orange,
        surface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey,
        selectedColor: AppColors.purple,
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.purple,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.purple
              : Colors.grey[300],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            inherit: false,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: _buildInputDecoration(
        Colors.white,
        AppColors.purple,
        AppColors.orange,
        Colors.grey[700]!,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.darkPurple,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: AppColors.black),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: AppColors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.purple,
      cardColor: AppColors.darkSurface,
      hintColor: Colors.grey[500],
      colorScheme: const ColorScheme.dark().copyWith(
        primary: AppColors.purple,
        secondary: AppColors.orange,
        surface: AppColors.darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white10,
        selectedColor: AppColors.purple,
        labelStyle: const TextStyle(color: Colors.white70),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.purple,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.purple
              : Colors.grey[800],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            inherit: false,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.purple),
      ),
      inputDecorationTheme: _buildInputDecoration(
        AppColors.darkSurface,
        AppColors.purple,
        AppColors.orange,
        AppColors.darkText,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            headlineLarge: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.orange,
            ),
            headlineMedium: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
            titleMedium: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.darkText,
            ),
            bodyMedium: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.darkText,
            ),
          ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeValue;
    if (mode == ThemeMode.dark) {
      themeValue = 'dark';
    } else if (mode == ThemeMode.light) {
      themeValue = 'light';
    } else {
      themeValue = 'system';
    }
    await prefs.setString(_themeKey, themeValue);
    notifyListeners();
  }
}
