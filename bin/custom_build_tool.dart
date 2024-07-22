import 'dart:io';
import 'build/build_manager.dart';
import 'config_manager.dart';
import 'version_manager.dart';
import 'readme_manager.dart';
import 'settings_manager.dart';

void main(List<String> arguments) async {
  if (arguments.contains("--help")) {
    print("\nUsage: flutter pub run custom_build_tool [--reset] [--configure]");
    exit(1);
  }

  if (arguments.contains("--reset")) {
    SettingsManager.resetSettings();
    print("\nSettings have been reset.");
    exit(0);
  }

  if (arguments.contains("--configure")) {
    ConfigManager.configureDefaults();
    exit(0);
  }

  // Load user settings
  Map<String, dynamic> settings = SettingsManager.loadSettings();
  print("Loaded settings: $settings"); // Debug print
  print(
      "Type of 'default' in settings: ${settings['default']?.runtimeType}"); // Debug print
  bool usePreferences = settings['default'] == true;

  // If settings are empty, it's the first run
  if (settings.isEmpty) {
    print("\nIt looks like this is your first time running the CLI.");
    ConfigManager.promptForDefaultConfig();
    settings = SettingsManager.loadSettings();
    usePreferences = settings['default'] == true;
  }

  // Ask all questions if default is set to false
  if (!usePreferences) {
    settings['platformChoice'] = ConfigManager.getPlatformChoice();
    settings['build_type'] =
        BuildManager.getBuildType({}, {}, ConfigManager.getAllBuildTypes());
    settings['noVersion'] = VersionManager.getVersionUpgradeChoice({}, {});
  }

  int platformChoice = settings['platformChoice'];

  List<String> buildTypes = [];
  if (platformChoice == 1 || platformChoice == 3) {
    buildTypes.addAll(ConfigManager.getAndroidBuildTypes());
    buildTypes.addAll(ConfigManager.getAndroidProductFlavors());
  }
  if (platformChoice == 2 || platformChoice == 3) {
    buildTypes.addAll(ConfigManager.getIOSSchemes());
  }

  Set<String> allBuildTypes = {...buildTypes.map((e) => e.toLowerCase())};
  allBuildTypes.add("test");

  String buildType = settings['build_type'];

  bool noVersion = settings['noVersion'];

  String version = VersionManager.getCurrentVersion();
  String newVersion = version;
  String semanticVersion = version.split('+').first;

  if (!noVersion) {
    String upgradeType = VersionManager.getUpgradeType();
    newVersion = VersionManager.incrementVersion(version, upgradeType);
    VersionManager.updateVersion(
        newVersion, File('pubspec.yaml').readAsStringSync());
    semanticVersion = newVersion.split('+').first;
  } else {
    print("\nUsing existing version $version");
  }

  String appName = VersionManager.getAppName();

  if (platformChoice == 1 || platformChoice == 3) {
    BuildManager.buildAndroidApk(appName, semanticVersion, buildType);
  }
  if (platformChoice == 2 || platformChoice == 3) {
    BuildManager.buildIosApp(appName, semanticVersion, buildType);
  }

  if (!usePreferences) {
    SettingsManager.saveSettings({
      'platformChoice': platformChoice,
      'build_type': buildType,
      'noVersion': noVersion,
      'default': false,
    });
  }

  // Ask user if they want to add details in README.md for this version
  ReadmeManager.promptForReadmeUpdate(newVersion);
}
