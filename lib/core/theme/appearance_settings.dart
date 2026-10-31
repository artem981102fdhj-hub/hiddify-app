import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-adjustable look of the app. A `null` colour or radius means "keep the app's own default",
/// so a fresh install looks exactly like before until something is changed.
@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.seedColor,
    this.idleButtonColor,
    this.connectedButtonColor,
    this.cornerRadius,
    this.fontScale = 1.0,
  });

  /// Main colour the whole palette is built from. `null` = system (wallpaper) colours when the
  /// device has them, otherwise the default blue.
  final Color? seedColor;

  /// Connection button while disconnected. `null` = default.
  final Color? idleButtonColor;

  /// Connection button while connected. `null` = default.
  final Color? connectedButtonColor;

  /// Corner radius of cards, dialogs, buttons and inputs. `null` = Material default.
  final double? cornerRadius;

  /// Multiplier on top of the system font size.
  final double fontScale;

  static const double minRadius = 0;
  static const double maxRadius = 32;
  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.4;

  static const Color defaultSeed = Color(0xFF293CA0);
  static const Color defaultIdle = Color(0xFF4a4d8b);
  static const Color defaultConnected = Color(0xFF44a334);

  bool get isDefault =>
      seedColor == null &&
      idleButtonColor == null &&
      connectedButtonColor == null &&
      cornerRadius == null &&
      fontScale == 1.0;
}

/// Colours offered as one-tap presets in the colour picker.
const List<Color> appearancePresetColors = [
  Color(0xFF293CA0), // default blue
  Color(0xFF1E88E5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFFFB8C00),
  Color(0xFFE53935),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF5E35B1),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
  Color(0xFF212121),
];

/// Parses `RRGGBB` or `#RRGGBB` (case-insensitive). Returns `null` when the text is not a colour.
Color? parseHexColor(String input) {
  var text = input.trim();
  if (text.startsWith('#')) text = text.substring(1);
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(text)) return null;
  return Color(0xFF000000 | int.parse(text, radix: 16));
}

/// `#RRGGBB` for display.
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class AppearanceNotifier extends Notifier<AppearanceSettings> {
  static const _seedKey = 'appearance_seed_color';
  static const _idleKey = 'appearance_idle_button_color';
  static const _connectedKey = 'appearance_connected_button_color';
  static const _radiusKey = 'appearance_corner_radius';
  static const _fontScaleKey = 'appearance_font_scale';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider).requireValue;

  @override
  AppearanceSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider).requireValue;
    Color? readColor(String key) {
      final value = prefs.getInt(key);
      return value == null ? null : Color(value);
    }

    final radius = prefs.getDouble(_radiusKey);
    final scale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    return AppearanceSettings(
      seedColor: readColor(_seedKey),
      idleButtonColor: readColor(_idleKey),
      connectedButtonColor: readColor(_connectedKey),
      cornerRadius: radius?.clamp(AppearanceSettings.minRadius, AppearanceSettings.maxRadius).toDouble(),
      fontScale: scale.clamp(AppearanceSettings.minFontScale, AppearanceSettings.maxFontScale).toDouble(),
    );
  }

  Future<void> _writeColor(String key, Color? color) async {
    if (color == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, color.toARGB32());
    }
  }

  Future<void> setSeedColor(Color? color) async {
    final old = state;
    state = AppearanceSettings(
      seedColor: color,
      idleButtonColor: old.idleButtonColor,
      connectedButtonColor: old.connectedButtonColor,
      cornerRadius: old.cornerRadius,
      fontScale: old.fontScale,
    );
    await _writeColor(_seedKey, color);
  }

  Future<void> setIdleButtonColor(Color? color) async {
    final old = state;
    state = AppearanceSettings(
      seedColor: old.seedColor,
      idleButtonColor: color,
      connectedButtonColor: old.connectedButtonColor,
      cornerRadius: old.cornerRadius,
      fontScale: old.fontScale,
    );
    await _writeColor(_idleKey, color);
  }

  Future<void> setConnectedButtonColor(Color? color) async {
    final old = state;
    state = AppearanceSettings(
      seedColor: old.seedColor,
      idleButtonColor: old.idleButtonColor,
      connectedButtonColor: color,
      cornerRadius: old.cornerRadius,
      fontScale: old.fontScale,
    );
    await _writeColor(_connectedKey, color);
  }

  Future<void> setCornerRadius(double? radius) async {
    final old = state;
    state = AppearanceSettings(
      seedColor: old.seedColor,
      idleButtonColor: old.idleButtonColor,
      connectedButtonColor: old.connectedButtonColor,
      cornerRadius: radius,
      fontScale: old.fontScale,
    );
    if (radius == null) {
      await _prefs.remove(_radiusKey);
    } else {
      await _prefs.setDouble(_radiusKey, radius);
    }
  }

  Future<void> setFontScale(double scale) async {
    final old = state;
    state = AppearanceSettings(
      seedColor: old.seedColor,
      idleButtonColor: old.idleButtonColor,
      connectedButtonColor: old.connectedButtonColor,
      cornerRadius: old.cornerRadius,
      fontScale: scale,
    );
    await _prefs.setDouble(_fontScaleKey, scale);
  }

  Future<void> resetAll() async {
    state = const AppearanceSettings();
    for (final key in [_seedKey, _idleKey, _connectedKey, _radiusKey, _fontScaleKey]) {
      await _prefs.remove(key);
    }
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, AppearanceSettings>(AppearanceNotifier.new);
