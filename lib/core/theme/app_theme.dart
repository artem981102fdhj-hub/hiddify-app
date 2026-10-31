import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/appearance_settings.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily, [this.appearance = const AppearanceSettings()]);
  final AppThemeMode mode;
  final String fontFamily;
  final AppearanceSettings appearance;

  /// A chosen main colour wins; otherwise the system (wallpaper) colours, then the default blue.
  ColorScheme _scheme(ColorScheme? systemScheme, Brightness brightness) {
    final seed = appearance.seedColor;
    if (seed != null) return ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return systemScheme ?? ColorScheme.fromSeed(seedColor: AppearanceSettings.defaultSeed, brightness: brightness);
  }

  ConnectionButtonTheme get _buttonTheme => ConnectionButtonTheme(
    idleColor: appearance.idleButtonColor ?? ConnectionButtonTheme.light.idleColor,
    connectedColor: appearance.connectedButtonColor ?? ConnectionButtonTheme.light.connectedColor,
  );

  ThemeData _build(ColorScheme scheme, {Color? scaffoldBackgroundColor}) {
    final radius = appearance.cornerRadius;
    final shape = radius == null ? null : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: fontFamily,
      cardTheme: shape == null ? null : CardThemeData(shape: shape),
      dialogTheme: shape == null ? null : DialogThemeData(shape: shape),
      elevatedButtonTheme: shape == null
          ? null
          : ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: shape)),
      filledButtonTheme: shape == null ? null : FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape)),
      outlinedButtonTheme: shape == null
          ? null
          : OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: shape)),
      inputDecorationTheme: radius == null
          ? null
          : InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius))),
      extensions: <ThemeExtension<dynamic>>{_buttonTheme},
    );
  }

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    return _build(_scheme(lightColorScheme, Brightness.light));
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = _scheme(darkColorScheme, Brightness.dark);
    return _build(scheme, scaffoldBackgroundColor: mode.trueBlack ? Colors.black : scheme.surface);
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    // final def = CupertinoThemeData(brightness: Brightness.dark);

    // return def;
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
