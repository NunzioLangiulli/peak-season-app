import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seasonality_resolver.dart';
import '../models/app_enums.dart';
import '../models/notification_prefs.dart';

/// Global preferences: language, theme, climate zone, notifications.
/// Every change is saved immediately to `shared_preferences`.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _language = AppLanguage.fromCode(_prefs.getString(_kLanguage));
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_kTheme),
      orElse: () => ThemeMode.system,
    );
    _zone = ClimaticZone.fromCode(_prefs.getString(_kZone));
    _area = ItalyMacroArea.fromCode(_prefs.getString(_kArea));
    _allowApproximate = _prefs.getBool(_kApprox) ?? true;
    _peakNotifMode = PeakNotifMode.fromName(_prefs.getString(_kPeakNotif));
    _shoppingListMode = ShoppingNotifListMode.fromName(_prefs.getString(_kShoppingListMode));
    _storageTipsAfterShopping = _prefs.getBool(PrefKeys.storageTipsAfterShopping) ?? true;
    _storageTipsDelay = _prefs.getInt(PrefKeys.storageTipsDelayMinutes) ?? 0;
    _frost = _prefs.getDouble(_kFrost) ?? 0.6;
    _palette = BackdropPalette.fromName(_prefs.getString(_kPalette));
  }

  static const _kLanguage = PrefKeys.language;
  static const _kTheme = 'themeMode';
  static const _kZone = 'climaticZone';
  static const _kArea = 'italyMacroArea';
  static const _kApprox = 'allowApproximateSeasonality';
  static const _kPeakNotif = 'peakNotifMode';
  static const _kShoppingListMode = 'shoppingNotifListMode';
  static const _kFrost = 'frostStrength';
  static const _kPalette = 'backdropPalette';

  final SharedPreferences _prefs;

  late AppLanguage _language;
  late ThemeMode _themeMode;
  late ClimaticZone _zone;
  late ItalyMacroArea _area;
  late bool _allowApproximate;
  late PeakNotifMode _peakNotifMode;
  late ShoppingNotifListMode _shoppingListMode;
  late bool _storageTipsAfterShopping;
  late int _storageTipsDelay;
  late double _frost;
  late BackdropPalette _palette;

  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;
  ClimaticZone get zone => _zone;
  ItalyMacroArea get area => _area;
  bool get allowApproximate => _allowApproximate;
  PeakNotifMode get peakNotifMode => _peakNotifMode;
  ShoppingNotifListMode get shoppingListMode => _shoppingListMode;
  bool get storageTipsAfterShopping => _storageTipsAfterShopping;
  int get storageTipsDelay => _storageTipsDelay;

  /// Frosted-glass intensity, 0 (solid surfaces) - 1 (very transparent).
  double get frost => _frost;
  BackdropPalette get palette => _palette;

  Locale get locale => Locale(_language.name);

  SeasonalityResolver get resolver => SeasonalityResolver(
        zone: _zone,
        area: _area,
        allowApproximate: _allowApproximate,
      );

  void setLanguage(AppLanguage v) {
    if (v == _language) return;
    _language = v;
    _prefs.setString(_kLanguage, v.name);
    notifyListeners();
  }

  void setThemeMode(ThemeMode v) {
    if (v == _themeMode) return;
    _themeMode = v;
    _prefs.setString(_kTheme, v.name);
    notifyListeners();
  }

  void setZone(ClimaticZone v) {
    if (v == _zone) return;
    _zone = v;
    _prefs.setString(_kZone, v.code);
    notifyListeners();
  }

  void setArea(ItalyMacroArea v) {
    if (v == _area) return;
    _area = v;
    _prefs.setString(_kArea, v.code);
    notifyListeners();
  }

  void setAllowApproximate(bool v) {
    _allowApproximate = v;
    _prefs.setBool(_kApprox, v);
    notifyListeners();
  }

  void setPeakNotifMode(PeakNotifMode v) {
    _peakNotifMode = v;
    _prefs.setString(_kPeakNotif, v.name);
    notifyListeners();
  }

  void setShoppingListMode(ShoppingNotifListMode v) {
    _shoppingListMode = v;
    _prefs.setString(_kShoppingListMode, v.name);
    notifyListeners();
  }

  void setStorageTipsAfterShopping(bool v) {
    _storageTipsAfterShopping = v;
    _prefs.setBool(PrefKeys.storageTipsAfterShopping, v);
    notifyListeners();
  }

  void setStorageTipsDelay(int minutes) {
    _storageTipsDelay = minutes;
    _prefs.setInt(PrefKeys.storageTipsDelayMinutes, minutes);
    notifyListeners();
  }

  void setFrost(double v) {
    _frost = v.clamp(0, 1);
    _prefs.setDouble(_kFrost, _frost);
    notifyListeners();
  }

  void setPalette(BackdropPalette v) {
    _palette = v;
    _prefs.setString(_kPalette, v.name);
    notifyListeners();
  }
}
