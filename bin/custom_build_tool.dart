import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  if (arguments.contains("--help")) {
    print("\nUsage: flutter pub run custom_build_tool [--reset] [--configure]\n");
    exit(1);
  }

  if (arguments.contains("--reset")) {
    _resetPreferences();
    print("\nPreferences have been reset.\n");
    exit(0);
  }

  if (arguments.contains("--configure")) {
    _configureDefaults();
    exit(0);
  }

  // Load user preferences
  Map<String, dynamic> preferences = _loadPreferences();
  Map<String, dynamic> config = _loadConfig();

  // Check if this is the first run
  if (preferences.isEmpty && config.isEmpty) {
    print("\nIt looks like this is your first time running the CLI.\n");
    _promptForDefaultConfig();
    preferences = _loadPreferences();
    config = _loadConfig();
  }

  // Read Android build types and flavors
  List<String> androidBuildTypes = _getAndroidBuildTypes();
  List<String> androidFlavors = _getAndroidProductFlavors();

  // Read iOS schemes and configurations
  List<String> iosSchemes = _getIOSSchemes();

  // Mix android build types, flavors, and iOS schemes if they are the same
  Set<String> allBuildTypes = {...androidBuildTypes.map((e) => e.toLowerCase()), ...iosSchemes.map((e) => e.toLowerCase()), ...androidFlavors.map((e) => e.toLowerCase())};

  // Add "test" build type manually
  allBuildTypes.add("test");

  // Interactive CLI for build type selection
  String buildType = _getBuildType(preferences, config, allBuildTypes.toList());

  // Interactive CLI for version upgrade
  bool noVersion = _getVersionUpgradeChoice(preferences, config);

  // Read and parse pubspec.yaml content
  File pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print("\nError: pubspec.yaml file not found.\n");
    exit(1);
  }
  String pubspecContent = pubspecFile.readAsStringSync();
  var pubspec = loadYaml(pubspecContent);

  String? appName = pubspec['name'];
  String? currentVersion = pubspec['version'];

  if (appName == null || currentVersion == null) {
    print("\nError: 'name' or 'version' not found in pubspec.yaml\n");
    exit(1);
  }

  String version = currentVersion;
  String newVersion = version;
  String semanticVersion = version.split('+').first;

  if (!noVersion) {
    String upgradeType = _getUpgradeType();
    newVersion = _incrementVersion(version, upgradeType);
    String updatedPubspecContent = pubspecContent.replaceFirst('version: $currentVersion', 'version: $newVersion');
    pubspecFile.writeAsStringSync(updatedPubspecContent);
    print("\nVersion updated to $newVersion\n");
  } else {
    print("\nUsing existing version $version\n");
  }

  // Update semanticVersion after increment
  semanticVersion = newVersion.split('+').first;

  // Run flutter build apk based on the build type
  print("\nBuilding APK with build type: $buildType...\n");
  List<String> buildArgs = ['build', 'apk'];
  if (buildType != 'test') {
    buildArgs.add('--$buildType');
  }
  ProcessResult result = Process.runSync('flutter', buildArgs);
  if (result.exitCode != 0) {
    print("\nError: Failed to build APK. Please check the flutter build output for details.\n");
    print(result.stderr);
    exit(1);
  }
  print("\nBuild completed successfully.\n");

  // Determine the output APK path based on build type
  String apkPath = _getApkPath(buildType == 'test' ? 'release' : buildType);

  // Define the new APK file name
  String newApkName = "${appName}_v${semanticVersion}_${buildType == 'test' ? 'test' : buildType}.apk";
  String newApkPath = "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}$newApkName";

  if (File(apkPath).existsSync()) {
    File(apkPath).renameSync(newApkPath);
    print("\nAPK renamed to $newApkName\n");
    print("You can find the APK at:\n");
    print("\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newApkPath\x1B[0m\n");
  } else {
    print("\nError: APK file not found at $apkPath. Please check the build output.\n");
  }

  // Save user preferences
  _savePreferences({'buildType': buildType, 'noVersion': noVersion});
}

void _promptForDefaultConfig() {
  print("\nWould you like to set the current configuration as default?\n");
  print("1. Yes\n");
  print("2. No\n");
  print("\n =>");
  String? choice = stdin.readLineSync();

  if (choice == '1') {
    _configureDefaults();
  } else {
    print("\nProceeding without saving defaults.\n");
  }
}

String _getBuildType(Map<String, dynamic> preferences, Map<String, dynamic> config, List<String> allBuildTypes) {
  String? buildType = preferences['buildType'] ?? config['buildType'];

  if (buildType == null || buildType.isEmpty) {
    print("\nChoose your build type:\n");
    for (int i = 0; i < allBuildTypes.length; i++) {
      print("${i + 1}. ${allBuildTypes[i]}\n");
    }
    print("\n =>");
    String? buildTypeChoice = stdin.readLineSync();
    int choiceIndex = int.parse(buildTypeChoice!) - 1;

    if (choiceIndex < allBuildTypes.length) {
      buildType = allBuildTypes[choiceIndex];
    } else {
      print("\nInvalid choice. Defaulting to 'release'.\n");
      buildType = 'release';
    }
  } else {
    print("\nUsing default build type: $buildType\n");
  }
  return buildType;
}

bool _getVersionUpgradeChoice(Map<String, dynamic> preferences, Map<String, dynamic> config) {
  bool? noVersion = preferences['noVersion'] ?? config['noVersion'];

  if (noVersion == null) {
    print("\nUpgrade version?\n");
    print("1. Yes\n");
    print("2. No\n");
    print("\n =>");
    String? upgradeChoice = stdin.readLineSync();

    noVersion = (upgradeChoice == '2');
  } else {
    print("\nUsing default version upgrade choice: ${noVersion ? 'No' : 'Yes'}\n");
  }
  return noVersion;
}

String _getUpgradeType() {
  print("\nWhat is your upgrade type?\n");
  print("1. Major\n");
  print("2. Minor\n");
  print("3. Patch\n");
  print("\n =>");
  String? upgradeTypeChoice = stdin.readLineSync();

  switch (upgradeTypeChoice) {
    case '1':
      return 'major';
    case '2':
      return 'minor';
    case '3':
      return 'patch';
    default:
      print("\nInvalid choice. Defaulting to 'patch'.\n");
      return 'patch';
  }
}

String _incrementVersion(String currentVersion, String upgradeType) {
  List<String> parts = currentVersion.split('+');
  String semver = parts[0].trim();
  int buildNumber = int.parse(parts[1].trim());

  List<String> semverParts = semver.split('.');
  int major = int.parse(semverParts[0]);
  int minor = int.parse(semverParts[1]);
  int patch = int.parse(semverParts[2]);

  switch (upgradeType) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
      patch++;
      break;
  }

  int newBuildNumber = buildNumber + 1;
  return "$major.$minor.$patch+$newBuildNumber";
}

String _getApkPath(String buildType) {
  switch (buildType) {
    case 'release':
    case 'test':
      return "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}app-release.apk";
    case 'debug':
      return "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}app-debug.apk";
    case 'profile':
      return "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}app-profile.apk";
    default:
      return "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}app-release.apk";
  }
}

List<String> _getAndroidBuildTypes() {
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

List<String> _getAndroidProductFlavors() {
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

List<String> _getIOSSchemes() {
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

Map<String, dynamic> _loadPreferences() {
  try {
    String content = File('preferences.json').readAsStringSync();
    return jsonDecode(content);
  } catch (e) {
    return {};
  }
}

void _savePreferences(Map<String, dynamic> preferences) {
  String content = jsonEncode(preferences);
  File('preferences.json').writeAsStringSync(content);
}

void _resetPreferences() {
  File('preferences.json').writeAsStringSync('{}');
}

Map<String, dynamic> _loadConfig() {
  try {
    String content = File('config.json').readAsStringSync();
    return jsonDecode(content);
  } catch (e) {
    return {};
  }
}

void _saveConfig(Map<String, dynamic> config) {
  String content = jsonEncode(config);
  File('config.json').writeAsStringSync(content);
}

void _configureDefaults() {
  Map<String, dynamic> config = {};

  // Configure default build type
  print("\nSet default build type:\n");
  List<String> androidBuildTypes = _getAndroidBuildTypes();
  List<String> iosSchemes = _getIOSSchemes();

  Set<String> allBuildTypes = {...androidBuildTypes.map((e) => e.toLowerCase()), ...iosSchemes.map((e) => e.toLowerCase())};

  // Add "test" build type manually
  allBuildTypes.add("test");

  for (int i = 0; i < allBuildTypes.length; i++) {
    print("${i + 1}. ${allBuildTypes.elementAt(i)}\n");
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

  // Configure default version upgrade choice
  print("\nSet default version upgrade choice:\n");
  print("1. Yes\n");
  print("2. No\n");
  print("\n =>");
  String? upgradeChoice = stdin.readLineSync();
  config['noVersion'] = (upgradeChoice == '2');

  // Save configuration
  _saveConfig(config);
  print("\nConfiguration saved.\n");
}
