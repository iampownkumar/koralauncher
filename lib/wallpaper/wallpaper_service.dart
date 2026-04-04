import 'package:flutter/foundation.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperService {
  static const String _wallpaperPathKey = 'custom_wallpaper_path';
  static final ImagePicker _picker = ImagePicker();

  static Future<void> openWallpaperPicker() async {
    try {
      final intent = const AndroidIntent(
        action: 'android.intent.action.SET_WALLPAPER',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Failed to open wallpaper intent: $e');
    }
  }

  static Future<String?> pickAndSaveCustomWallpaper() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_wallpaperPathKey, image.path);
        return image.path;
      }
    } catch (e) {
      debugPrint("Error picking custom wallpaper: $e");
    }
    return null;
  }

  static Future<String?> getSavedWallpaperPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_wallpaperPathKey);
  }
}
