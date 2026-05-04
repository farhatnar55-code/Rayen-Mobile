import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.accentSurface,
        onSecondaryContainer: AppColors.accentDark,
        error: AppColors.error,
        onError: AppColors.textInverse,
        errorContainer: AppColors.errorSurface,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.inputBorder,
        outlineVariant: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: AppDimensions.fontXl,
          fontWeight: FontWeight.w600,
          color: AppColors.textInverse,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textInverse,
          size: AppDimensions.iconMd,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.backgroundLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.primaryLight.withValues(
            alpha: 0.4,
          ),
          disabledForegroundColor: AppColors.textInverse.withValues(alpha: 0.6),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: _inter(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: AppColors.textInverse,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHint,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: _inter(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _inter(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSm,
            vertical: AppDimensions.paddingXs,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        hintStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        ),
        errorStyle: _inter(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        floatingLabelStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySurface,
        selectedColor: AppColors.primary,
        labelStyle: _inter(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavLight,
        selectedItemColor: AppColors.textInverse,
        unselectedItemColor: AppColors.textInverse.withValues(alpha: 0.75),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: _inter(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w600,
          color: AppColors.textInverse,
        ),
        unselectedLabelStyle: _inter(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w400,
          color: AppColors.textInverse.withValues(alpha: 0.75),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primarySurface,
        selectionHandleColor: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: _buildTextTheme(
        AppColors.textPrimary,
        AppColors.textSecondary,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.accentDark,
        onSecondaryContainer: AppColors.accentLight,
        error: AppColors.error,
        onError: AppColors.textInverse,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.dividerDark,
        outlineVariant: AppColors.dividerDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: AppDimensions.fontXl,
          fontWeight: FontWeight.w600,
          color: AppColors.textInverse,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textInverse,
          size: AppDimensions.iconMd,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
          disabledForegroundColor: AppColors.textInverse.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: _inter(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: AppColors.textInverse,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          textStyle: _inter(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: _inter(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryLight,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textHintDark,
        ),
        errorStyle: _inter(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
        floatingLabelStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.dividerDark, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryDark.withValues(alpha: 0.3),
        selectedColor: AppColors.primary,
        labelStyle: _inter(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavDark,
        selectedItemColor: AppColors.textInverse,
        unselectedItemColor: AppColors.textInverse.withValues(alpha: 0.75),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: _inter(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w600,
          color: AppColors.textInverse,
        ),
        unselectedLabelStyle: _inter(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w400,
          color: AppColors.textInverse.withValues(alpha: 0.75),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primaryLight,
        selectionColor: AppColors.primaryLight.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.primaryLight,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.progressTrackDark,
        circularTrackColor: AppColors.progressTrackDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: _inter(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: _buildTextTheme(
        AppColors.textPrimaryDark,
        AppColors.textSecondaryDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: AppDimensions.fontDisplay,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontSize: AppDimensions.fontXxxl,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: AppDimensions.fontXxl,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontSize: AppDimensions.fontXxl,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: AppDimensions.fontXl,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        titleSmall: TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w400,
          color: primary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w400,
          color: primary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w400,
          color: secondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w500,
          color: secondary,
        ),
        labelSmall: TextStyle(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w400,
          color: secondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
