import 'dart:io';
import 'settings_manager.dart';

class ConfigManager {
  static Map<String, dynamic> loadConfig() {
    return SettingsManager.loadSettings();
  }

  static void saveConfig(Map<String, dynamic> config) {
    SettingsManager.saveSettings(config);
  }

  static void configureDefaults() {
    Map<String, dynamic> config = loadConfig();

    // Set default app paths
    config['app_path'] = {
      'android': "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk",
      'ios': "build${Platform.pathSeparator}ios${Platform.pathSeparator}ipa"
    };

    // Set default build type
    print("Set default build type:\n");
    List<String> buildTypes = _getBuildTypes();
    for (int i = 0; i < buildTypes.length; i++) {
      print("${i + 1}. ${buildTypes[i]}");
    }
    print("\n =>");
    String? buildTypeChoice = stdin.readLineSync();
    int choiceIndex = int.tryParse(buildTypeChoice!)! - 1;
    config['build_type'] = buildTypes[choiceIndex];

    // Set default version upgrade choice
    print("Set default version upgrade choice:\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? upgradeChoice = stdin.readLineSync();
    config['noVersion'] = (upgradeChoice == '2');

    // Set default saving option
    print("Set default configuration:\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? saveChoice = stdin.readLineSync();
    config['default'] = (saveChoice == '1');

    saveConfig(config);
    print("\nConfiguration saved.");
  }

  static void promptForDefaultConfig() {
    print("Would you like to set the current configuration as default?\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? choice = stdin.readLineSync();

    if (choice == '1') {
      configureDefaults();
    } else {
      print("\nProceeding without saving defaults.");
    }
  }

  static List<String> _getBuildTypes() {
    // Example build types, replace with actual fetching logic
    return ['release', 'debug', 'profile', 'test'];
  }

  static int getPlatformChoice() {
    print("Choose your platform:\n");
    print("1. Android");
    print("2. iOS");
    print("3. Both");
    print("\n =>");
    String? platformChoice = stdin.readLineSync();
    return int.tryParse(platformChoice!) ?? 3;
  }

  static List<String> getAndroidBuildTypes() {
    List<String> buildTypes = [];
    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      RegExp exp = RegExp(r'buildTypes\s*\{([^}]+)\}');
      Match? match = exp.firstMatch(content);
      if (match != null) {
        String buildTypesContent = match.group(1)!;
        RegExp buildTypeExp = RegExp(r'\b(\w+)\s*\{');
        for (Match buildTypeMatch in buildTypeExp.allMatches(buildTypesContent)) {
          buildTypes.add(buildTypeMatch.group(1)!);
        }
      }
    }
    return buildTypes;
  }

  static List<String> getAndroidProductFlavors() {
    List<String> flavors = [];
    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      RegExp exp = RegExp(r'productFlavors\s*\{([^}]+)\}');
      Match? match = exp.firstMatch(content);
      if (match != null) {
        String flavorsContent = match.group(1)!;
        RegExp flavorExp = RegExp(r'\b(\w+)\s*\{');
        for (Match flavorMatch in flavorExp.allMatches(flavorsContent)) {
          flavors.add(flavorMatch.group(1)!);
        }
      }
    }
    return flavors;
  }

  static List<String> getIOSSchemes() {
    List<String> schemes = [];
    try {
      ProcessResult result = Process.runSync('xcodebuild', ['-list']);
      if (result.exitCode == 0) {
        String output = result.stdout;
        RegExp exp = RegExp(r'Schemes:\s*([\s\S]*?)\n\n', multiLine: true);
        Match? match = exp.firstMatch(output);
        if (match != null) {
          String schemesContent = match.group(1)!;
          schemes = schemesContent.split('\n').map((s) => s.trim()).toList();
        }
      }
    } catch (e) {
      print("Error: Unable to retrieve iOS schemes. Using default schemes.");
    }

    if (schemes.isEmpty) {
      // Set default schemes if nothing is found or an error occurs
      schemes = ['Release', 'Debug'];
    }
    return schemes;
  }
}
