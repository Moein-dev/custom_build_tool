import 'dart:io';
import 'dart:convert';

class ConfigManager {
  static void configureDefaults() {
    Map<String, dynamic> config = {};

    // Configure default build type
    config['platformChoice'] = getPlatformChoice();
    config['build_type'] = 'release'; // Default build type
    config['noVersion'] = false; // Default version upgrade choice

    // Save configuration
    saveConfig(config);
    print("\nConfiguration saved.");
  }

  static int getPlatformChoice() {
    print("Choose your platform:\n");
    print("1. Android");
    print("2. iOS");
    print("3. Both");
    print("\n =>");
    String? platformChoice = stdin.readLineSync();
    return int.parse(platformChoice!);
  }

  static List<String> getAndroidBuildTypes() {
    List<String> buildTypes = [];
    File buildGradle = File('android/app/build.gradle');
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
    File buildGradle = File('android/app/build.gradle');
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

  static List<String> getAllBuildTypes() {
    List<String> buildTypes = getAndroidBuildTypes();
    buildTypes.addAll(getAndroidProductFlavors());
    buildTypes.addAll(getIOSSchemes());
    buildTypes = buildTypes.map((e) => e.toLowerCase()).toList();
    if (!buildTypes.contains('debug')) {
      buildTypes.add('debug');
    }
    return buildTypes;
  }

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
}
