import 'dart:io';
import 'dart:convert';

class SettingsManager {
  static const String settingsFilePath = 'settings.json';

  static Map<String, dynamic> loadSettings() {
    try {
      if (File(settingsFilePath).existsSync()) {
        String content = File(settingsFilePath).readAsStringSync();
        return jsonDecode(content);
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static void saveSettings(Map<String, dynamic> settings) {
    String content = jsonEncode(settings);
    File(settingsFilePath).writeAsStringSync(content);
  }

  static void resetSettings() {
    File(settingsFilePath).writeAsStringSync('{}');
  }
}
