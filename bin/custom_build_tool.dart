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

  // Interactive CLI for build type selection
  String buildType = _getBuildType(preferences, config);

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
    String newVersion = _incrementVersion(version);
    String updatedPubspecContent = pubspecContent.replaceFirst('version: $currentVersion', 'version: $newVersion');
    pubspecFile.writeAsStringSync(updatedPubspecContent);
    print("Version updated to $newVersion");
  } else {
    print("Using existing version $version");
  }

  // Run flutter build apk based on the build type
  print("Building APK with build type: $buildType...");
  ProcessResult result = Process.runSync('flutter', ['build', 'apk',]);
  if (result.exitCode != 0) {
    print("Error: Failed to build APK. Please check the flutter build output for details.");
    print(result.stderr);
    exit(1);
  }
  print("Build completed successfully.");

  // Determine the output APK path based on build type
  String apkPath = _getApkPath();

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

String _getBuildType(Map<String, dynamic> preferences, Map<String, dynamic> config) {
  String? buildType = preferences['buildType'] ?? config['buildType'];

  if (buildType == null || buildType.isEmpty) {
    print("Choose your build type:");
    print("1. release");
    print("2. debug");
    print("3. profile");
    String? buildTypeChoice = stdin.readLineSync();

    switch (buildTypeChoice) {
      case '1':
        buildType = 'release';
        break;
      case '2':
        buildType = 'debug';
        break;
      case '3':
        buildType = 'profile';
        break;
      default:
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

String _incrementVersion(String currentVersion) {
  List<String> parts = currentVersion.split('+');
  String semver = parts[0].trim();
  int buildNumber = int.parse(parts[1].trim());

  List<String> semverParts = semver.split('.');
  int major = int.parse(semverParts[0]);
  int minor = int.parse(semverParts[1]);
  int patch = int.parse(semverParts[2]);

  patch++;
  if (patch >= 10) {
    patch = 0;
    minor++;
  }
  if (minor >= 10) {
    minor = 0;
    major++;
  }

  int newBuildNumber = buildNumber + 1;
  return "$major.$minor.$patch+$newBuildNumber";
}

String _getApkPath({String buildType = 'release'}) {
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
  print("1. release");
  print("2. debug");
  print("3. profile");
  String? buildTypeChoice = stdin.readLineSync();

  switch (buildTypeChoice) {
    case '1':
      config['buildType'] = 'release';
      break;
    case '2':
      config['buildType'] = 'debug';
      break;
    case '3':
      config['buildType'] = 'profile';
      break;
    default:
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
