import 'dart:io';

class BuildManager {
  static void buildAndroidApk(String appName, String semanticVersion, String buildType) {
    print("\nBuilding APK for Android with build type: $buildType...");

    bool releaseKeyExists = _checkReleaseKeyExists();

    if (!releaseKeyExists) {
      if (_promptForReleaseKeyCreation()) {
        _createReleaseKey();
        _configureReleaseKeyInGradle();
      }
    }

    List<String> buildArgs = ['build', 'apk'];
    if (buildType == 'release' && !releaseKeyExists) {
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

    String apkPath = _getApkPath(buildType == 'test' ? 'release' : buildType, 'android');
    String newApkName = "${appName}_v${semanticVersion}_${buildType == 'test' ? 'test' : buildType}.apk";
    String newApkPath = "build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}flutter-apk${Platform.pathSeparator}$newApkName";

    if (File(apkPath).existsSync()) {
      File(apkPath).renameSync(newApkPath);
      print("APK renamed to $newApkName\n");
      print("You can find the APK at:\n");
      print("\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newApkPath\x1B[0m");
    } else {
      print("\nError: APK file not found at $apkPath. Please check the build output.");
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

    String newIpaName = "${appName}_v${semanticVersion}_$buildType.ipa";
    String ipaPath = "build${Platform.pathSeparator}ios${Platform.pathSeparator}ipa";
    String newIpaPath = "$ipaPath${Platform.pathSeparator}$newIpaName";

    Directory(ipaPath).listSync().forEach((file) {
      if (file.path.endsWith('.ipa')) {
        File(file.path).renameSync(newIpaPath);
        print("IPA renamed to $newIpaName\n");
        print("You can find the IPA at:\n");
        print("\x1B[34mfile://${Directory.current.path}${Platform.pathSeparator}$newIpaPath\x1B[0m");
      }
    });
  }

  static bool _checkReleaseKeyExists() {
    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      return content.contains('signingConfig signingConfigs.release');
    }
    return false;
  }

  static bool _promptForReleaseKeyCreation() {
    print("Do you want to create a release key?\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? choice = stdin.readLineSync();
    return choice == '1';
  }

  static void _createReleaseKey() {
    print("\nCreating release key...");
    print("Please enter the following details:");

    print("Key store password: ");
    String? keyStorePassword = stdin.readLineSync();

    print("Key alias: ");
    String? keyAlias = stdin.readLineSync();

    print("Key password: ");
    String? keyPassword = stdin.readLineSync();

    print("Your first and last name: ");
    String? name = stdin.readLineSync();

    print("Your organizational unit: ");
    String? organizationalUnit = stdin.readLineSync();

    print("Your organization: ");
    String? organization = stdin.readLineSync();

    print("Your city or locality: ");
    String? city = stdin.readLineSync();

    print("Your state or province: ");
    String? state = stdin.readLineSync();

    print("Your two-letter country code: ");
    String? countryCode = stdin.readLineSync();

    Process.runSync('keytool', [
      '-genkey',
      '-v',
      '-keystore',
      'android${Platform.pathSeparator}app${Platform.pathSeparator}key.jks',
      '-keyalg',
      'RSA',
      '-keysize',
      '2048',
      '-validity',
      '10000',
      '-alias',
      keyAlias!,
      '-keypass',
      keyPassword!,
      '-storepass',
      keyStorePassword!,
      '-dname',
      'CN=$name, OU=$organizationalUnit, O=$organization, L=$city, S=$state, C=$countryCode'
    ]);

    // Create the key.properties file
    File keyProperties = File('android${Platform.pathSeparator}key.properties');
    keyProperties.writeAsStringSync('''storePassword=$keyStorePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=key.jks''');
  }

  static void _configureReleaseKeyInGradle() {
    print("\nConfiguring release key in build.gradle...");

    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      if (!content.contains('signingConfigs.release')) {
        content = content.replaceFirst(
          'buildTypes {',
          '''signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {''');
        buildGradle.writeAsStringSync(content);
      }

      // Update buildTypes.release signingConfig
      content = buildGradle.readAsStringSync();
      content = content.replaceFirst(
        '// TODO: Add your own signing config for the release build.\n            // Signing with the debug keys for now, so `flutter run --release` works.\n            signingConfig signingConfigs.debug',
        'signingConfig signingConfigs.release'
      );
      buildGradle.writeAsStringSync(content);
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
