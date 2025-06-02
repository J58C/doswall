import 'package:flutter/material.dart';
import 'app_colors.dart'; // Impor konstanta warna
import 'custom_colors.dart'; // Impor CustomColors ThemeExtension

// Fungsi ini bisa tetap di sini atau dipindahkan ke file utilitas teks jika perlu
TextTheme _buildTextTheme(TextTheme base, Color textColor, String fontFamily) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.bold),
    displayMedium: base.displayMedium?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.bold),
    displaySmall: base.displaySmall?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.bold),
    headlineLarge: base.headlineLarge?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.bold),
    headlineMedium: base.headlineMedium?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.w600),
    headlineSmall: base.headlineSmall?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(color: textColor, fontFamily: fontFamily),
    titleSmall: base.titleSmall?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.w500),
    bodyLarge: base.bodyLarge?.copyWith(color: textColor, fontFamily: fontFamily),
    bodyMedium: base.bodyMedium?.copyWith(color: textColor, fontFamily: fontFamily),
    bodySmall: base.bodySmall?.copyWith(color: textColor.withAlpha((0.7 * 255).round()), fontFamily: fontFamily),
    labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily, fontWeight: FontWeight.bold),
    labelMedium: base.labelMedium?.copyWith(color: textColor, fontFamily: fontFamily, fontWeight: FontWeight.w500),
    labelSmall: base.labelSmall?.copyWith(color: textColor, fontFamily: fontFamily),
  ).apply(
    bodyColor: textColor,
    displayColor: textColor,
    fontFamily: fontFamily,
  );
}

ThemeData buildLightTheme() { // Nama diubah agar lebih jelas saat diimpor
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: darkTextColor,
      primaryContainer: Color.lerp(primaryColor, Colors.white, 0.2),
      onPrimaryContainer: darkTextColor,
      secondary: secondaryColor,
      onSecondary: darkTextColor,
      secondaryContainer: Color.lerp(secondaryColor, Colors.white, 0.2),
      onSecondaryContainer: darkTextColor,
      tertiary: accentOrangeColor,
      onTertiary: darkTextColor,
      tertiaryContainer: Color.lerp(accentOrangeColor, Colors.white, 0.2),
      onTertiaryContainer: darkTextColor,
      error: errorRedColor,
      onError: Colors.white,
      errorContainer: Color.lerp(errorRedColor, Colors.white, 0.4),
      onErrorContainer: darkTextColor,     // Menggunakan konstanta dari app_colors.dart
      surface: Colors.white, // Atau lightBackgroundColor jika ingin surface sama dengan background
      onSurface: darkTextColor,
      surfaceContainerHighest: Color.lerp(lightBackgroundColor, Colors.black, 0.05),
      onSurfaceVariant: darkTextColor,
      outline: primaryColor.withAlpha((0.5 * 255).round()),
      outlineVariant: darkTextColor.withAlpha((0.3 * 255).round()),
      shadow: Colors.black.withAlpha((0.1 * 255).round()),
      scrim: Colors.black.withAlpha((0.5 * 255).round()),
      inverseSurface: darkBackgroundColor,
      onInverseSurface: lightTextColor,
      inversePrimary: primaryColor,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    textTheme: _buildTextTheme(base.textTheme, darkTextColor, 'Inter'), // Pastikan font Inter terdaftar di pubspec.yaml
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: darkTextColor,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextColor, fontFamily: 'Inter'),
      iconTheme: IconThemeData(color: darkTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: darkTextColor,
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: BorderSide(color: secondaryColor, width: 1.5),
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryColor.withAlpha((0.05 * 255).round()),
      hintStyle: TextStyle(color: darkTextColor.withAlpha((0.6 * 255).round()), fontFamily: 'Inter'),
      labelStyle: TextStyle(color: primaryColor, fontFamily: 'Inter'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryColor.withAlpha((0.3 * 255).round())),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryColor.withAlpha((0.5 * 255).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: secondaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRedColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRedColor, width: 2.0),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1.0,
      color: Colors.white, // Ini adalah colorScheme.surface untuk light theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.all(8.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentOrangeColor,
      foregroundColor: darkTextColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentOrangeColor,
      unselectedLabelColor: darkTextColor.withAlpha((0.7 * 255).round()),
      indicatorColor: accentOrangeColor,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      unselectedLabelStyle: TextStyle(fontFamily: 'Inter'),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: secondaryColor,
      linearTrackColor: secondaryColor.withAlpha((0.3 * 255).round()),
      circularTrackColor: secondaryColor.withAlpha((0.3 * 255).round()),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentOrangeColor,
      inactiveTrackColor: accentOrangeColor.withAlpha((0.3 * 255).round()),
      thumbColor: accentOrangeColor,
      overlayColor: accentOrangeColor.withAlpha(0x29),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return accentOrangeColor;
        return lightBackgroundColor.withAlpha((0.8 * 255).round());
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return accentOrangeColor.withAlpha((0.5 * 255).round());
        return darkTextColor.withAlpha((0.2 * 255).round());
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return darkTextColor.withAlpha((0.2 * 255).round());
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return successGreenColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(darkTextColor),
      side: BorderSide(color: darkTextColor.withAlpha((0.7 * 255).round()), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return successGreenColor;
        return null;
      }),
    ),
    iconTheme: IconThemeData(color: secondaryColor),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
      disabledColor: darkTextColor.withAlpha((0.05 * 255).round()),
      selectedColor: successGreenColor,
      secondarySelectedColor: primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      labelStyle: TextStyle(color: darkTextColor, fontFamily: 'Inter'),
      secondaryLabelStyle: TextStyle(color: darkTextColor, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      iconTheme: IconThemeData(color: darkTextColor, size: 18),
      checkmarkColor: darkTextColor,
      deleteIconColor: errorRedColor,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightBackgroundColor,
      titleTextStyle: TextStyle(color: darkTextColor, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      contentTextStyle: TextStyle(color: darkTextColor, fontSize: 16, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      actionsPadding: EdgeInsets.all(24),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkTextColor.withAlpha((0.9 * 255).round()),
      contentTextStyle: TextStyle(color: lightBackgroundColor, fontFamily: 'Inter'),
      actionTextColor: accentOrangeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: <ThemeExtension<dynamic>>[
      const CustomColors(success: successGreenColor), // Menggunakan konstanta dari app_colors.dart
    ],
  );
}

ThemeData buildDarkTheme() { // Nama diubah agar lebih jelas saat diimpor
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: lightTextColor,
      primaryContainer: Color.lerp(primaryColor, Colors.black, 0.6),
      onPrimaryContainer: lightTextColor,
      secondary: secondaryColor,
      onSecondary: lightTextColor,
      secondaryContainer: Color.lerp(secondaryColor, Colors.black, 0.6),
      onSecondaryContainer: lightTextColor,
      tertiary: accentOrangeColor,
      onTertiary: Colors.black,
      tertiaryContainer: Color.lerp(accentOrangeColor, Colors.black, 0.6),
      onTertiaryContainer: lightTextColor,
      error: errorRedColor,
      onError: Colors.white,
      errorContainer: Color.lerp(errorRedColor, Colors.black, 0.4),
      onErrorContainer: lightTextColor,    // Menggunakan konstanta dari app_colors.dart
      surface: darkSurfaceColor,
      onSurface: lightTextColor,
      surfaceContainerHighest: Color.lerp(darkBackgroundColor, Colors.white, 0.08),
      onSurfaceVariant: lightTextColor,
      outline: primaryColor.withAlpha((0.5 * 255).round()),
      outlineVariant: lightTextColor.withAlpha((0.3 * 255).round()),
      shadow: Colors.black.withAlpha((0.2 * 255).round()),
      scrim: Colors.black.withAlpha((0.6 * 255).round()),
      inverseSurface: lightBackgroundColor,
      onInverseSurface: darkTextColor,
      inversePrimary: primaryColor,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: _buildTextTheme(base.textTheme, lightTextColor, 'Inter'), // Pastikan font Inter terdaftar
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: lightTextColor,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextColor, fontFamily: 'Inter'),
      iconTheme: IconThemeData(color: lightTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: lightTextColor,
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentOrangeColor,
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentOrangeColor,
        side: BorderSide(color: accentOrangeColor, width: 1.5),
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor.withAlpha((0.8 * 255).round()), // Sedikit penyesuaian
      hintStyle: TextStyle(color: lightTextColor.withAlpha((0.6 * 255).round()), fontFamily: 'Inter'),
      labelStyle: TextStyle(color: lightTextColor.withAlpha((0.8 * 255).round()), fontFamily: 'Inter'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightTextColor.withAlpha((0.3 * 255).round())),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: lightTextColor.withAlpha((0.5 * 255).round())),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: accentOrangeColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRedColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorRedColor, width: 2.0),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1.0,
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.all(8.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentOrangeColor,
      foregroundColor: Colors.black,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentOrangeColor,
      unselectedLabelColor: lightTextColor.withAlpha((0.7 * 255).round()),
      indicatorColor: accentOrangeColor,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      unselectedLabelStyle: TextStyle(fontFamily: 'Inter'),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentOrangeColor,
      linearTrackColor: accentOrangeColor.withAlpha((0.3 * 255).round()),
      circularTrackColor: accentOrangeColor.withAlpha((0.3 * 255).round()),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentOrangeColor,
      inactiveTrackColor: accentOrangeColor.withAlpha((0.3 * 255).round()),
      thumbColor: accentOrangeColor,
      overlayColor: accentOrangeColor.withAlpha(0x29),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return accentOrangeColor;
        return lightTextColor.withAlpha((0.6 * 255).round());
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return accentOrangeColor.withAlpha((0.5 * 255).round());
        return lightTextColor.withAlpha((0.2 * 255).round());
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return lightTextColor.withAlpha((0.2 * 255).round());
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return successGreenColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(darkSurfaceColor),
      side: BorderSide(color: lightTextColor.withAlpha((0.7 * 255).round()), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) return successGreenColor;
        return null;
      }),
    ),
    iconTheme: IconThemeData(color: lightTextColor.withAlpha(220)),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withAlpha((0.15 * 255).round()),
      disabledColor: lightTextColor.withAlpha((0.1 * 255).round()),
      selectedColor: successGreenColor,
      secondarySelectedColor: primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      labelStyle: TextStyle(color: lightTextColor, fontFamily: 'Inter'),
      secondaryLabelStyle: TextStyle(color: darkTextColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      iconTheme: IconThemeData(color: lightTextColor, size: 18),
      checkmarkColor: darkTextColor,
      deleteIconColor: errorRedColor,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceColor,
      titleTextStyle: TextStyle(color: lightTextColor, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      contentTextStyle: TextStyle(color: lightTextColor, fontSize: 16, fontFamily: 'Inter'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      actionsPadding: EdgeInsets.all(24),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightTextColor.withAlpha((0.9 * 255).round()),
      contentTextStyle: TextStyle(color: darkBackgroundColor, fontFamily: 'Inter'),
      actionTextColor: accentOrangeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: <ThemeExtension<dynamic>>[
      const CustomColors(success: successGreenColor), // Menggunakan konstanta dari app_colors.dart
    ],
  );
}