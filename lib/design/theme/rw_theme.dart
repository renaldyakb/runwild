import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

abstract final class RwTheme {
  static ThemeData get light => _build();
  static ThemeData get dark =>
      _build(); // Hanya tema terang (light mode) sesuai arahan

  static ThemeData _build() {
    const foreground = RwColors.ink950;
    const surface = RwColors.paper50;
    const cardSurface = Color(0xFFFFFFFF);
    const muted = RwColors.mutedTextOnLight;

    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: foreground,
      onPrimary: RwColors.lime500,
      secondary: RwColors.ink800,
      onSecondary: Colors.white,
      error: RwColors.dangerTextOnLight,
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainer: cardSurface,
      surfaceContainerHigh: RwColors.surfaceMuted,
      onSurfaceVariant: muted,
      outline: RwColors.borderControl,
      outlineVariant: RwColors.borderCard,
    );

    TextStyle display(double size) => TextStyle(
      fontFamily: RwType.family,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.05,
      color: foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final text =
        TextTheme(
          displayLarge: display(RwType.displayXL),
          displayMedium: display(RwType.displayL),
          displaySmall: display(RwType.displayM),
          headlineSmall: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.title,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: foreground,
          ),
          titleLarge: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.title,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: foreground,
          ),
          titleMedium: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.body,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          bodyLarge: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.body,
            height: RwType.bodyHeight,
            color: foreground,
          ),
          bodyMedium: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.bodySmall,
            height: RwType.bodyHeight,
            color: muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.bodySmall,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          labelSmall: const TextStyle(
            fontFamily: RwType.family,
            fontSize: RwType.label,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ).apply(
          fontFamily: RwType.family,
          bodyColor: foreground,
          displayColor: foreground,
        );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      cardColor: cardSurface,
      textTheme: text,
      fontFamily: RwType.family,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium?.copyWith(fontSize: 18),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(RwSize.touch),
          foregroundColor: foreground,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: RwColors.borderControl,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RwSpace.md,
          vertical: RwSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          borderSide: const BorderSide(color: RwColors.borderControl, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          borderSide: const BorderSide(color: RwColors.borderControl, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          borderSide: const BorderSide(color: foreground, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          borderSide: const BorderSide(
            color: RwColors.dangerTextOnLight,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          borderSide: const BorderSide(
            color: RwColors.dangerTextOnLight,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: RwType.family,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: RwType.family,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RwRadius.lg),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          side: const BorderSide(color: RwColors.borderCard, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: text.bodyMedium?.copyWith(color: surface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
