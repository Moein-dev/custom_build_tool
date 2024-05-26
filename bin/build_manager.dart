import 'dart:io';

class BuildManager {
  static void buildAndroidApk(
      String appName, String semanticVersion, String buildType) {
    print("\nBuilding APK for Android with build type: $buildType...");

    bool releaseKeyExists = _checkReleaseKeyExists();

    List<String> buildArgs = ['build', 'apk'];
    if (buildType == 'release' && !releaseKeyExists) {
      print(
          "\nYou don't have a release key in android/app/build.gradle. Building without --release flag.");
    } else if (buildType != 'test') {
      buildArgs.add('--$buildType');
    }

    ProcessResult result = Process.runSync('flutter', buildArgs);
    if (result.exitCode != 0) {
      print(
          "\nError: Failed to build APK. Please check the flutter build output for details.");
      print(result.stderr);
      exit(1);
    }
    print("\nBuild completed successfully.");

    String apkPath =
        _getApkPath(buildType == 'test' ? 'release' : buildType, 'android');
    String newApkName =
        "${appName}_v${semanticVersion}_${buildType == 'test' ? 'test' : buildType}.apk";
    String newApkPath =
        "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}$newApkName";

    if (File(apkPath).existsSync()) {
      File(apkPath).renameSync(newApkPath);
      print("APK renamed to $newApkName\n");
      print("You can find the APK at:\n");
      print(
          "\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newApkPath\x1B[0m");
    } else {
      print(
          "\nError: APK file not found at $apkPath. Please check the build output.");
    }
  }

  static void buildIosApp(
      String appName, String semanticVersion, String buildType) {
    print("\nBuilding app for iOS with build type: $buildType...");

    List<String> buildArgs = ['build', 'ios', '--$buildType'];
    ProcessResult result = Process.runSync('flutter', buildArgs);
    if (result.exitCode != 0) {
      print(
          "\nError: Failed to build iOS app. Please check the flutter build output for details.");
      print(result.stderr);
      exit(1);
    }
    print("\nBuild completed successfully.");

    String newIpaName = "${appName}_v${semanticVersion}_$buildType.ipa";
    String ipaPath =
        "build${Platform.pathSeparator}ios${Platform.pathSeparator}ipa";
    String newIpaPath = "$ipaPath${Platform.pathSeparator}$newIpaName";

    Directory(ipaPath).listSync().forEach((file) {
      if (file.path.endsWith('.ipa')) {
        File(file.path).renameSync(newIpaPath);
        print("IPA renamed to $newIpaName\n");
        print("You can find the IPA at:\n");
        print(
            "\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newIpaPath\x1B[0m");
      }
    });
  }

  static bool _checkReleaseKeyExists() {
    File buildGradle = File(
        'android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      return content.contains('signingConfig signingConfigs.release');
    }
    return false;
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

  static String getBuildType(Map<String, dynamic> preferences,
      Map<String, dynamic> config, List<String> allBuildTypes) {
    String? buildType = preferences['buildType'] ?? config['buildType'];

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
