import 'dart:io';
import '../settings_manager.dart';
import 'release_key_manager.dart';

class BuildManager {
  static void buildAndroidApk(String appName, String semanticVersion, String buildType) {
    print("\nBuilding APK for Android with build type: $buildType...");

    if (buildType != 'test') {
      bool releaseKeyExists = ReleaseKeyManager.checkReleaseKeyExists();

      if (!releaseKeyExists && buildType == 'release') {
        if (ReleaseKeyManager.promptForReleaseKeyCreation()) {
         Map<String,dynamic> data = ReleaseKeyManager.createReleaseKey();
          ReleaseKeyManager.configureReleaseKeyInGradle(data);
        }
      }
    }

    List<String> buildArgs = ['build', 'apk'];
    if (buildType == 'release' && !ReleaseKeyManager.checkReleaseKeyExists()) {
      print("\nYou don't have a release key in android/app/build.gradle. Building without --release flag.");
      buildArgs.remove('--release');
    } else if (buildType != 'test') {
      buildArgs.add('--$buildType');
    }

    ProcessResult result = Process.runSync('flutter', buildArgs);
    if (result.exitCode != 0) {
      print("\nError: Failed to build APK. Please check the flutter build output for details.");
      print(result.stderr);
      exit(1);
    }
    print("\nBuild completed successfully.");

    String defaultApkPath = _getApkPath(buildType == 'test' ? 'release' : buildType, 'android');
    String newApkName = "${appName}_v${semanticVersion}_${buildType == 'test' ? 'test' : buildType}.apk";

    Map<String, dynamic> settings = SettingsManager.loadSettings();
    String userSpecifiedPath = settings['app_path']?['android'] ?? "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk";
    String newApkPath = userSpecifiedPath.endsWith(Platform.pathSeparator) ? "$userSpecifiedPath$newApkName" : "$userSpecifiedPath${Platform.pathSeparator}$newApkName";

    if (File(defaultApkPath).existsSync()) {
      if (defaultApkPath != newApkPath) {
        Directory(userSpecifiedPath).createSync(recursive: true);
        File(defaultApkPath).renameSync(newApkPath);
      }
      print("APK renamed to $newApkName\n");
      print("You can find the APK at:\n");
      print("\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newApkPath\x1B[0m");
    } else {
      print("\nError: APK file not found at $defaultApkPath. Please check the build output.");
    }
  }

  static void buildIosApp(String appName, String semanticVersion, String buildType) {
    print("\nBuilding app for iOS with build type: $buildType...");

    List<String> buildArgs = ['build', 'ios', '--$buildType'];
    ProcessResult result = Process.runSync('flutter', buildArgs);
    if (result.exitCode != 0) {
      print("\nError: Failed to build iOS app. Please check the flutter build output for details.");
      print(result.stderr);
      exit(1);
    }
    print("\nBuild completed successfully.");

    String defaultIpaPath = "build${Platform.pathSeparator}ios${Platform.pathSeparator}ipa";
    String newIpaName = "${appName}_v${semanticVersion}_$buildType.ipa";

    Map<String, dynamic> settings = SettingsManager.loadSettings();
    String userSpecifiedPath = settings['app_path']?['ios'] ?? defaultIpaPath;
    String userIpaPath = userSpecifiedPath.endsWith(Platform.pathSeparator) ? "$userSpecifiedPath$newIpaName" : "$userSpecifiedPath${Platform.pathSeparator}$newIpaName";

    if (Directory(defaultIpaPath).existsSync()) {
      Directory(defaultIpaPath).listSync().forEach((file) {
        if (file.path.endsWith('.ipa')) {
          if (file.path != userIpaPath) {
            Directory(userSpecifiedPath).createSync(recursive: true);
            File(file.path).renameSync(userIpaPath);
          }
          print("IPA renamed to $newIpaName\n");
          print("You can find the IPA at:\n");
          print("\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$userIpaPath\x1B[0m");
        }
      });
    } else {
      print("\nError: IPA file not found at $defaultIpaPath. Please check the build output.");
    }
  }

  static String _getApkPath(String buildType, String platform) {
    if (platform == 'android') {
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
    } else {
      return "build${Platform.pathSeparator}ios${Platform.pathSeparator}ipa";
    }
  }

  static String getBuildType(Map<String, dynamic> preferences, Map<String, dynamic> config, List<String> allBuildTypes) {
    if (!allBuildTypes.contains('debug')) {
      allBuildTypes.add('debug');
    }

    String? buildType = preferences['build_type'] ?? config['build_type'];

    if (buildType == null || buildType.isEmpty) {
      int choiceIndex;
      do {
        print("Choose your build type:\n");
        for (int i = 0; i < allBuildTypes.length; i++) {
          print("${i + 1}. ${allBuildTypes[i]}");
        }
        print("\n =>");
        String? buildTypeChoice = stdin.readLineSync();
        choiceIndex = int.tryParse(buildTypeChoice!) ?? -1;
        if (choiceIndex < 1 || choiceIndex > allBuildTypes.length) {
          print("\nInvalid choice. Please select a valid option.\n");
        }
      } while (choiceIndex < 1 || choiceIndex > allBuildTypes.length);
      buildType = allBuildTypes[choiceIndex - 1];
    } else {
      print("\nUsing default build type: $buildType");
    }
    return buildType;
  }
}
