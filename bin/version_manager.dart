import 'dart:io';
import 'package:yaml/yaml.dart';

class VersionManager {
  static String incrementVersion(String currentVersion, String upgradeType) {
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

  static void updateVersion(String newVersion, String pubspecContent) {
    File pubspecFile = File('pubspec.yaml');
    String updatedPubspecContent = pubspecContent.replaceFirst(
        RegExp(r'version: [0-9]+\.[0-9]+\.[0-9]+\+\d+'),
        'version: $newVersion');
    pubspecFile.writeAsStringSync(updatedPubspecContent);
    print("\nVersion updated to $newVersion");
  }

  static String getCurrentVersion() {
    File pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print("\nError: pubspec.yaml file not found.");
      exit(1);
    }
    String pubspecContent = pubspecFile.readAsStringSync();
    var pubspec = loadYaml(pubspecContent);

    String? currentVersion = pubspec['version'];
    if (currentVersion == null) {
      print("\nError: 'version' not found in pubspec.yaml");
      exit(1);
    }

    return currentVersion;
  }

  static String getAppName() {
    File pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print("\nError: pubspec.yaml file not found.");
      exit(1);
    }
    String pubspecContent = pubspecFile.readAsStringSync();
    var pubspec = loadYaml(pubspecContent);

    String? appName = pubspec['name'];
    if (appName == null) {
      print("\nError: 'name' not found in pubspec.yaml");
      exit(1);
    }

    return appName;
  }

  static bool getVersionUpgradeChoice(
      Map<String, dynamic> preferences, Map<String, dynamic> config) {
    bool? noVersion = preferences['noVersion'] ?? config['noVersion'];

    if (noVersion == null) {
      int choice;
      do {
        print("Upgrade version?\n");
        print("1. Yes");
        print("2. No");
        print("\n =>");
        String? upgradeChoice = stdin.readLineSync();
        choice = int.tryParse(upgradeChoice!) ?? -1;
        if (choice < 1 || choice > 2) {
          print("\nInvalid choice. Please select a valid option.\n");
        }
      } while (choice < 1 || choice > 2);
      noVersion = (choice == 2);
    } else {
      print(
          "\nUsing default version upgrade choice: ${noVersion ? 'No' : 'Yes'}");
    }
    return noVersion;
  }

  static String getUpgradeType() {
    int choice;
    do {
      print("What is your upgrade type?\n");
      print("1. Major");
      print("2. Minor");
      print("3. Patch");
      print("\n =>");
      String? upgradeTypeChoice = stdin.readLineSync();
      choice = int.tryParse(upgradeTypeChoice!) ?? -1;
      if (choice < 1 || choice > 3) {
        print("\nInvalid choice. Please select a valid option.\n");
      }
    } while (choice < 1 || choice > 3);

    switch (choice) {
      case 1:
        return 'major';
      case 2:
        return 'minor';
      case 3:
        return 'patch';
      default:
        print("\nInvalid choice. Defaulting to 'patch'.");
        return 'patch';
    }
  }
}
