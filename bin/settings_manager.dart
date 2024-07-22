import 'dart:io';
import 'dart:convert';

class SettingsManager {
  static Map<String, dynamic> loadSettings() {
    try {
      String content = File('settings.json').readAsStringSync();
      Map<String, dynamic> settings = jsonDecode(content);
      // Ensure 'default' is a boolean
      if (settings.containsKey('default') && settings['default'] is! bool) {
        settings['default'] =
            settings['default'].toString().toLowerCase() == 'true';
      }
      return settings;
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
