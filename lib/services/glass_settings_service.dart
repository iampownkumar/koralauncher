import 'package:shared_preferences/shared_preferences.dart';

enum GlassTint { light, medium, dark }

class GlassSettingsService {
  static const String _tintKey = 'glass_tint_preference';

  static Future<void> saveTintPreference(GlassTint tint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tintKey, tint.index);
  }

  static Future<GlassTint> getTintPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_tintKey) ?? GlassTint.medium.index;
    if (index >= 0 && index < GlassTint.values.length) {
      return GlassTint.values[index];
    }
    return GlassTint.medium;
  }

  static double getOpacityForTint(GlassTint tint) {
    switch (tint) {
      case GlassTint.light:
        return 0.35;
      case GlassTint.medium:
        return 0.55;
      case GlassTint.dark:
        return 0.85;
    }
  }
}
