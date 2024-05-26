import 'dart:io';
import 'dart:convert';
import 'preferences_manager.dart';

class ConfigManager {
  static Map<String, dynamic> loadConfig() {
    try {
      String content = File('config.json').readAsStringSync();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

  static void saveConfig(Map<String, dynamic> config) {
    String content = jsonEncode(config);
    File('config.json').writeAsStringSync(content);
  }

  static void configureDefaults() {
    Map<String, dynamic> config = {};

    print("Set default build type:\n");
    List<String> androidBuildTypes = getAndroidBuildTypes();
    List<String> iosSchemes = getIOSSchemes();

    Set<String> allBuildTypes = {
      ...androidBuildTypes.map((e) => e.toLowerCase()),
      ...iosSchemes.map((e) => e.toLowerCase())
    };

    allBuildTypes.add("test");

    for (int i = 0; i < allBuildTypes.length; i++) {
      print("${i + 1}. ${allBuildTypes.elementAt(i)}");
    }
    print("\n =>");
    String? buildTypeChoice = stdin.readLineSync();
    int choiceIndex = int.parse(buildTypeChoice!) - 1;

    if (choiceIndex < allBuildTypes.length) {
      config['buildType'] = allBuildTypes.elementAt(choiceIndex);
    } else {
      print("\nInvalid choice. Defaulting to 'release'.\n");
      config['buildType'] = 'release';
    }

    print("Set default version upgrade choice:\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? upgradeChoice = stdin.readLineSync();
    config['noVersion'] = (upgradeChoice == '2');

    saveConfig(config);
    print("\nConfiguration saved.");
  }

  static List<String> getAndroidBuildTypes() {
    List<String> buildTypes = [];
    File buildGradle = File(
        'android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      RegExp exp = RegExp(r'buildTypes\s*\{([^}]+)\}');
      Match? match = exp.firstMatch(content);
      if (match != null) {
        String buildTypesContent = match.group(1)!;
        RegExp buildTypeExp = RegExp(r'\b(\w+)\s*\{');
        for (Match buildTypeMatch
            in buildTypeExp.allMatches(buildTypesContent)) {
          buildTypes.add(buildTypeMatch.group(1)!);
        }
      }
    }
    return buildTypes;
  }

  static List<String> getAndroidProductFlavors() {
    List<String> flavors = [];
    File buildGradle = File(
        'android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
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
      schemes = ['Release', 'Debug'];
    }
    return schemes;
  }

  static void promptForDefaultConfig() {
    ConfigManager.configureDefaults();

    print("Would you like to save the current configuration as default?\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? choice = stdin.readLineSync();

    if (choice == '1') {
      PreferencesManager.savePreferences({'save': 'on'});
    } else {
      PreferencesManager.savePreferences({'save': 'off'});
      print("\nProceeding without saving defaults.");
    }
  }

  static int getPlatformChoice() {
    int choice;
    do {
      print("Which platform would you like to build for?\n");
      print("1. Android");
      print("2. iOS");
      print("3. Both");
      print("\n =>");
      String? platformChoice = stdin.readLineSync();
      choice = int.tryParse(platformChoice!) ?? -1;
      if (choice < 1 || choice > 3) {
        print("\nInvalid choice. Please select a valid option.\n");
      }
    } while (choice < 1 || choice > 3);
    return choice;
  }
}
