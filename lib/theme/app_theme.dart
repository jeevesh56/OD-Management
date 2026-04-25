import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F3D91),
      onPrimary: Colors.white,
      secondary: Color(0xFF0E9F6E),
      onSecondary: Colors.white,
      error: Color(0xFFB71C1C),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF10213A),
      inverseSurface: Color(0xFF10213A),
      onInverseSurface: Colors.white,
      outline: Color(0xFFD7DFEA),
      outlineVariant: Color(0xFFE7EDF5),
      shadow: Color(0x22000000),
      scrim: Color(0x66000000),
      tertiary: Color(0xFF6A1B9A),
      onTertiary: Colors.white,
      primaryContainer: Color(0xFFE6F0FF),
      onPrimaryContainer: Color(0xFF0B2E66),
      secondaryContainer: Color(0xFFD9F5EA),
      onSecondaryContainer: Color(0xFF0B4E37),
      errorContainer: Color(0xFFFDE3E3),
      onErrorContainer: Color(0xFF7A1212),
      surfaceContainerHighest: Color(0xFFF3F6FB),
      surfaceContainerHigh: Color(0xFFF7F9FC),
      surfaceContainer: Color(0xFFF9FBFD),
      surfaceContainerLow: Color(0xFFFDFEFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
    );

    return _baseTheme(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7CB4FF),
      onPrimary: Color(0xFF062045),
      secondary: Color(0xFF75E4B4),
      onSecondary: Color(0xFF06271A),
      error: Color(0xFFFF8D8D),
      onError: Color(0xFF3D0000),
      surface: Color(0xFF101722),
      onSurface: Color(0xFFE7EDF7),
      inverseSurface: Color(0xFFE7EDF7),
      onInverseSurface: Color(0xFF101722),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF223044),
      shadow: Color(0x55000000),
      scrim: Color(0xAA000000),
      tertiary: Color(0xFFC084FC),
      onTertiary: Color(0xFF2A103F),
      primaryContainer: Color(0xFF173A67),
      onPrimaryContainer: Color(0xFFD7E7FF),
      secondaryContainer: Color(0xFF103D2B),
      onSecondaryContainer: Color(0xFFBDF3D9),
      errorContainer: Color(0xFF5A1A1A),
      onErrorContainer: Color(0xFFFFD9D9),
      surfaceContainerHighest: Color(0xFF16202E),
      surfaceContainerHigh: Color(0xFF141C28),
      surfaceContainer: Color(0xFF111824),
      surfaceContainerLow: Color(0xFF0E151F),
      surfaceContainerLowest: Color(0xFF0B1018),
    );

    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1018) : const Color(0xFFF4F7FB),
      cardColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        prefixIconColor: scheme.onSurface.withValues(alpha: 0.82),
        suffixIconColor: scheme.onSurface.withValues(alpha: 0.82),
      ),
      dataTableTheme: DataTableThemeData(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        headingTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        dataTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13,
        ),
        horizontalMargin: 14,
        columnSpacing: 18,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withValues(alpha: isDark ? 0.16 : 0.06);
          }
          return Colors.transparent;
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        unselectedIconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.7)),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
      ),
    );

    final mappedTextTheme = base.textTheme
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          bodyMedium: TextStyle(color: scheme.onSurface),
          titleLarge: TextStyle(color: scheme.onSurface),
        );

    return base.copyWith(
      textTheme: mappedTextTheme,
      iconTheme: IconThemeData(color: scheme.onSurface),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.65),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: isDark ? 0.36 : 0.24),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}