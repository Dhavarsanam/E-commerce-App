import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Lumière commerce experience.
///
/// Every colour used by the app is defined here as part of a [Palette]
/// theme extension so light and dark mode stay in lock-step.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.bgElevated,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accent2,
    required this.accent3,
    required this.gold,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glass,
    required this.shadow,
  });

  final Color bg;
  final Color bgElevated;
  final Color surface;
  final Color surfaceHigh;
  final Color stroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accent2;
  final Color accent3;
  final Color gold;
  final Color success;
  final Color warning;
  final Color danger;
  final Color glass;
  final Color shadow;

  LinearGradient get brandGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent2]);

  LinearGradient get auroraGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent2, accent3]);

  static const dark = Palette(
    bg: Color(0xFF07070D),
    bgElevated: Color(0xFF0E0E18),
    surface: Color(0xFF141422),
    surfaceHigh: Color(0xFF1C1C2E),
    stroke: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF5F4FA),
    textSecondary: Color(0xFFB4B2C6),
    textMuted: Color(0xFF6F6D85),
    accent: Color(0xFF7C5CFF),
    accent2: Color(0xFFFF5C8A),
    accent3: Color(0xFFFFB36B),
    gold: Color(0xFFE8C77A),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFF5470),
    glass: Color(0x14FFFFFF),
    shadow: Color(0xB3000000),
  );

  static const light = Palette(
    bg: Color(0xFFF6F5FB),
    bgElevated: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEFEDF7),
    stroke: Color(0x14000000),
    textPrimary: Color(0xFF14121F),
    textSecondary: Color(0xFF55526A),
    textMuted: Color(0xFF9592A8),
    accent: Color(0xFF6A47FF),
    accent2: Color(0xFFFF3D74),
    accent3: Color(0xFFFF9A3D),
    gold: Color(0xFFC49A3A),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    glass: Color(0xB3FFFFFF),
    shadow: Color(0x33302A5C),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      bg: l(bg, other.bg),
      bgElevated: l(bgElevated, other.bgElevated),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      stroke: l(stroke, other.stroke),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accent2: l(accent2, other.accent2),
      accent3: l(accent3, other.accent3),
      gold: l(gold, other.gold),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      glass: l(glass, other.glass),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension PaletteX on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Motion tokens: one place for every duration and curve.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const xslow = Duration(milliseconds: 900);

  static const Curve emphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve spring = ElasticOutCurve(0.8);
  static const Curve smooth = Curves.easeOutCubic;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const xl = 34.0;
}

class AppTheme {
  /// Disabled in widget tests, which run without network access.
  static bool useGoogleFonts = true;

  static ThemeData build(Brightness brightness) {
    final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
        primary: p.accent,
        secondary: p.accent2,
        surface: p.surface,
        error: p.danger,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final display = useGoogleFonts ? GoogleFonts.soraTextTheme(base.textTheme) : base.textTheme;
    final body = useGoogleFonts ? GoogleFonts.interTextTheme(base.textTheme) : base.textTheme;
    final text = body
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.5),
          displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2),
          displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
          headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
          headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        )
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);

    return base.copyWith(
      textTheme: text,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceHigh.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: p.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.accent, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.stroke, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surfaceHigh,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
    );
  }
}
