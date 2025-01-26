import 'dart:io';
import 'build/build_manager.dart';
import 'config_manager.dart';
import 'version_manager.dart';
import 'readme_manager.dart';
import 'settings_manager.dart';
import 'utils/input_handler.dart';

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
  bool usePreferences = settings.isNotEmpty && settings['default'] == true;

  // If settings are empty, it's the first run
  if (settings.isEmpty) {
    print("\nIt looks like this is your first time running the CLI.");
    print("Would you like to set the current configuration as default?\n");
    print("1. Yes");
    print("2. No");
    stdout.write("\n => ");
    final input = await InputHandler.readKey();

    if (input == '1') {
      settings['default'] = true;
    } else {
      settings['default'] = false;
      SettingsManager.resetSettings();
    }
  }

  if (!usePreferences) {
    int platformChoice = await ConfigManager.getPlatformChoice();
    settings['platformChoice'] = platformChoice;
    String buildType = await BuildManager.getBuildType(
        {}, {}, ConfigManager.getAllBuildTypes());
    settings['build_type'] = buildType;
    String upgradeVersion =
        await VersionManager.getVersionUpgradeChoice({}, {});
    settings['upgrade_version'] = upgradeVersion;
  }

  int platformChoice = settings['platformChoice'];
  String buildType = settings['build_type'];
  bool upgradeVersion = settings['upgrade_version'] == 'yes';

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

  String version = VersionManager.getCurrentVersion();
  String newVersion = version;
  String semanticVersion = version.split('+').first;

  if (upgradeVersion) {
    String upgradeType = await VersionManager.getUpgradeType();
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
      'upgrade_version': upgradeVersion ? 'yes' : 'no',
      'default': settings['default'],
    });
  }

  // Ask user if they want to add details in README.md for this version
  ReadmeManager.promptForReadmeUpdate(newVersion);
}
