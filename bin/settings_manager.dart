import 'dart:io';
import 'dart:convert';

class SettingsManager {
  static Map<String, dynamic> loadSettings() {
    try {
      String content = File('settings.json').readAsStringSync();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

  static void saveSettings(Map<String, dynamic> settings) {
    String content = jsonEncode(settings);
    File('settings.json').writeAsStringSync(content);
  }

  static void resetSettings() {
    File('settings.json').writeAsStringSync('{}');
  }
}
