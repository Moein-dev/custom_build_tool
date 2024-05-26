import 'dart:io';
import 'dart:convert';

class PreferencesManager {
 static Map<String, dynamic> loadPreferences() {
    try {
      String content = File('preferences.json').readAsStringSync();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

 static void savePreferences(Map<String, dynamic> preferences) {
    String content = jsonEncode(preferences);
    File('preferences.json').writeAsStringSync(content);
  }

 static void resetPreferences() {
    File('preferences.json').writeAsStringSync('{}');
  }
}
