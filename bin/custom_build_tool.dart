import 'dart:io';
import 'build_manager.dart';
import 'config_manager.dart';
import 'preferences_manager.dart';
import 'version_manager.dart';
import 'readme_manager.dart';

void main(List<String> arguments) async {
  if (arguments.contains("--help")) {
    print("\nUsage: flutter pub run custom_build_tool [--reset] [--configure]");
    exit(1);
  }

  if (arguments.contains("--reset")) {
    PreferencesManager.resetPreferences();
    print("\nPreferences have been reset.");
    exit(0);
  }

  if (arguments.contains("--configure")) {
    ConfigManager.configureDefaults();
    exit(0);
  }

  // Load user preferences and config
  Map<String, dynamic> preferences = PreferencesManager.loadPreferences();
  Map<String, dynamic> config = ConfigManager.loadConfig();

  bool usePreferences = preferences['save'] == 'on';

  // If preferences are empty and config is empty, it's the first run
  if (preferences.isEmpty && config.isEmpty) {
    print("\nIt looks like this is your first time running the CLI.");
    ConfigManager.promptForDefaultConfig();
    preferences = PreferencesManager.loadPreferences();
    config = ConfigManager.loadConfig();
    usePreferences = preferences['save'] == 'on';
  }

  int platformChoice = usePreferences ? preferences['platformChoice'] : ConfigManager.getPlatformChoice();

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

  String buildType = usePreferences ? preferences['buildType'] : BuildManager.getBuildType(preferences, config, allBuildTypes.toList());

  bool noVersion = usePreferences ? preferences['noVersion'] : VersionManager.getVersionUpgradeChoice(preferences, config);

  String version = VersionManager.getCurrentVersion();
  String newVersion = version;
  String semanticVersion = version.split('+').first;

  if (!noVersion) {
    String upgradeType = VersionManager.getUpgradeType();
    newVersion = VersionManager.incrementVersion(version, upgradeType);
    VersionManager.updateVersion(newVersion, File('pubspec.yaml').readAsStringSync());
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
    PreferencesManager.savePreferences({
      'platformChoice': platformChoice,
      'buildType': buildType,
      'noVersion': noVersion,
      'save': 'off',
    });
  }

  ReadmeManager.promptForReadmeUpdate(newVersion);
}
