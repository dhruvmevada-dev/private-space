import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const bg = Color(0xFF0B0D14);
  static const surface = Color(0xFF141824);
  static const surfaceHigh = Color(0xFF1C2132);
  static const outline = Color(0xFF272D42);
  static const primary = Color(0xFF7C6CFF);
  static const secondary = Color(0xFF4F8CFF);
  static const accent = Color(0xFF4FD1C5);
  static const text = Color(0xFFE8EAF2);
  static const muted = Color(0xFF8A91A8);
  static const error = Color(0xFFFF6B7A);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

/// Subtle fade + upward slide for every route.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
    outline: AppColors.outline,
  );
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme);

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    dividerColor: AppColors.outline,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.text,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: border(AppColors.outline),
      enabledBorder: border(AppColors.outline),
      focusedBorder: border(AppColors.primary, 1.6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
    }),
  );
}
