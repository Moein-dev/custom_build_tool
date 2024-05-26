import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  if (arguments.contains("--help")) {
    print("Usage: flutter pub run custom_build_tool [--reset] [--configure]");
    exit(1);
  }

  if (arguments.contains("--reset")) {
    _resetPreferences();
    print("Preferences have been reset.");
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
    print("It looks like this is your first time running the CLI.");
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
  Set<String> allBuildTypes = {...androidBuildTypes, ...iosSchemes, ...androidFlavors};

  // Interactive CLI for build type selection
  String buildType = _getBuildType(preferences, config, allBuildTypes.toList());

  // Interactive CLI for version upgrade
  bool noVersion = _getVersionUpgradeChoice(preferences, config);

  // Read and parse pubspec.yaml content
  File pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print("Error: pubspec.yaml file not found.");
    exit(1);
  }
  String pubspecContent = pubspecFile.readAsStringSync();
  var pubspec = loadYaml(pubspecContent);

  String? appName = pubspec['name'];
  String? currentVersion = pubspec['version'];

  if (appName == null || currentVersion == null) {
    print("Error: 'name' or 'version' not found in pubspec.yaml");
    exit(1);
  }

  String version = currentVersion;
  String semanticVersion = version.split('+').first;

  if (!noVersion) {
    String upgradeType = _getUpgradeType();
    String newVersion = _incrementVersion(version, upgradeType);
    String updatedPubspecContent = pubspecContent.replaceFirst('version: $currentVersion', 'version: $newVersion');
    pubspecFile.writeAsStringSync(updatedPubspecContent);
    print("Version updated to $newVersion");
  } else {
    print("Using existing version $version");
  }

  // Run flutter build apk based on the build type
  print("Building APK with build type: $buildType...");
  ProcessResult result = Process.runSync('flutter', ['build', 'apk', '--$buildType']);
  if (result.exitCode != 0) {
    print("Error: Failed to build APK. Please check the flutter build output for details.");
    print(result.stderr);
    exit(1);
  }
  print("Build completed successfully.");

  // Determine the output APK path based on build type
  String apkPath = _getApkPath(buildType);

  // Define the new APK file name
  String newApkName = "${appName}_v${semanticVersion}_$buildType.apk";
  String newApkPath = "build/app/outputs/flutter-apk/$newApkName";

  if (File(apkPath).existsSync()) {
    File(apkPath).renameSync(newApkPath);
    print("APK renamed to $newApkName");
    print("You can find the APK at:");
    print("\x1B[34mfile://${Directory.current.path}/$newApkPath\x1B[0m");
  } else {
    print("Error: APK file not found at $apkPath. Please check the build output.");
  }

  // Save user preferences
  _savePreferences({'buildType': buildType, 'noVersion': noVersion});
}

void _promptForDefaultConfig() {
  print("Would you like to set the current configuration as default?");
  print("1. Yes");
  print("2. No");
  String? choice = stdin.readLineSync();

  if (choice == '1') {
    _configureDefaults();
  } else {
    print("Proceeding without saving defaults.");
  }
}

String _getBuildType(Map<String, dynamic> preferences, Map<String, dynamic> config, List<String> allBuildTypes) {
  String? buildType = preferences['buildType'] ?? config['buildType'];

  if (buildType == null || buildType.isEmpty) {
    print("Choose your build type:");
    for (int i = 0; i < allBuildTypes.length; i++) {
      print("${i + 1}. ${allBuildTypes[i]}");
    }
    String? buildTypeChoice = stdin.readLineSync();
    int choiceIndex = int.parse(buildTypeChoice!) - 1;

    if (choiceIndex < allBuildTypes.length) {
      buildType = allBuildTypes[choiceIndex];
    } else {
      print("Invalid choice. Defaulting to 'release'.");
      buildType = 'release';
    }
  } else {
    print("Using default build type: $buildType");
  }
  return buildType;
}

bool _getVersionUpgradeChoice(Map<String, dynamic> preferences, Map<String, dynamic> config) {
  bool? noVersion = preferences['noVersion'] ?? config['noVersion'];

  if (noVersion == null) {
    print("Upgrade version?");
    print("1. yes");
    print("2. no");
    String? upgradeChoice = stdin.readLineSync();

    noVersion = (upgradeChoice == '2');
  } else {
    print("Using default version upgrade choice: ${noVersion ? 'no' : 'yes'}");
  }
  return noVersion;
}

String _getUpgradeType() {
  print("What is your upgrade type?");
  print("1. major");
  print("2. minor");
  print("3. patch");
  String? upgradeTypeChoice = stdin.readLineSync();

  switch (upgradeTypeChoice) {
    case '1':
      return 'major';
    case '2':
      return 'minor';
    case '3':
      return 'patch';
    default:
      print("Invalid choice. Defaulting to 'patch'.");
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
      return "build/app/outputs/flutter-apk/app-release.apk";
    case 'debug':
      return "build/app/outputs/flutter-apk/app-debug.apk";
    case 'profile':
      return "build/app/outputs/flutter-apk/app-profile.apk";
    default:
      return "build/app/outputs/flutter-apk/app-release.apk";
  }
}

List<String> _getAndroidBuildTypes() {
  List<String> buildTypes = [];
  File buildGradle = File('android/app/build.gradle');
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
  print("Set default build type:");
  List<String> androidBuildTypes = _getAndroidBuildTypes();
  List<String> iosSchemes = _getIOSSchemes();

  Set<String> allBuildTypes = {...androidBuildTypes, ...iosSchemes};

  for (int i = 0; i < allBuildTypes.length; i++) {
    print("${i + 1}. ${allBuildTypes.elementAt(i)}");
  }

  String? buildTypeChoice = stdin.readLineSync();
  int choiceIndex = int.parse(buildTypeChoice!) - 1;

  if (choiceIndex < allBuildTypes.length) {
    config['buildType'] = allBuildTypes.elementAt(choiceIndex);
  } else {
    print("Invalid choice. Defaulting to 'release'.");
    config['buildType'] = 'release';
  }

  // Configure default version upgrade choice
  print("Set default version upgrade choice:");
  print("1. yes");
  print("2. no");
  String? upgradeChoice = stdin.readLineSync();
  config['noVersion'] = (upgradeChoice == '2');

  // Save configuration
  _saveConfig(config);
  print("Configuration saved.");
}
