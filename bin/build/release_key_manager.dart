import 'dart:io';

import 'package:path/path.dart';

class ReleaseKeyManager {
  static bool checkReleaseKeyExists() {
    return File('android/app/key.jks').existsSync();
  }

  static bool promptForReleaseKeyCreation() {
    print("\nDo you want to create a release key?\n");
    print("1. Yes");
    print("2. No");
    print("\n =>");
    String? choice = stdin.readLineSync();
    return choice == '1';
  }

  static Map<String, dynamic> createReleaseKey() {
    print("\nCreating release key...");

    print("Please enter the following details:");
    print("Key store password: ");
    String? storePass = stdin.readLineSync();
    print("Key alias: ");
    String? alias = stdin.readLineSync();
    print("Key password: ");
    String? keyPass = stdin.readLineSync();
    print("Your first and last name: ");
    String? dname = stdin.readLineSync();
    print("Your organizational unit: ");
    String? ou = stdin.readLineSync();
    print("Your organization: ");
    String? o = stdin.readLineSync();
    print("Your city or locality: ");
    String? l = stdin.readLineSync();
    print("Your state or province: ");
    String? s = stdin.readLineSync();
    print("Your two-letter country code: ");
    String? c = stdin.readLineSync();

    String dnameComplete = 'CN=$dname, OU=$ou, O=$o, L=$l, S=$s, C=$c';

    ProcessResult result = Process.runSync('keytool', [
      '-genkey',
      '-v',
      '-keystore',
      'android/app/key.jks',
      '-keyalg',
      'RSA',
      '-keysize',
      '2048',
      '-validity',
      '10000',
      '-alias',
      alias!,
      '-dname',
      dnameComplete,
      '-storepass',
      storePass!,
      '-keypass',
      keyPass!
    ]);

    if (result.exitCode != 0) {
      print(
          "\nError: Failed to create the keystore. Please check the keytool output for details.");
      print(result.stderr);
      exit(1);
    } else {
      print("\nKeystore created successfully.");
    }
    return {
      "storePass": storePass,
      "keyPass": keyPass,
      "alias": alias,
    };
  }

  static void configureReleaseKeyInGradle(Map<String, dynamic> data) {
    print("\nConfiguring release key in build.gradle...");

    // Write the key properties file
    File keyPropertiesFile = File('android/key.properties');
    keyPropertiesFile.writeAsStringSync('''
storePassword=${data["storePass"]}
keyPassword=${data["keyPass"]}
keyAlias=${data["alias"]}
storeFile=key.jks
''');
    print("Key properties file created at android/key.properties");

    // Define the path to the build.gradle file
    final buildGradlePath = join('android', 'app', 'build.gradle');

    // Read the build.gradle file
    final buildGradleFile = File(buildGradlePath);
    if (!buildGradleFile.existsSync()) {
      print('build.gradle file not found!');
      return;
    }

    final buildGradleContent = buildGradleFile.readAsStringSync();

    // Define the code to be inserted after android { starts
    final codeToInsertInsideAndroid = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.debug
        signingConfig signingConfigs.release
    }
}
''';

    // Find the android {} section
    final androidRegex = RegExp(r'android\s*\{');
    final androidMatch = androidRegex.firstMatch(buildGradleContent);

    if (androidMatch == null) {
      print('android {} section not found in build.gradle!');
      return;
    }

    final insertPositionInsideAndroid = androidMatch.end;

    // Insert the code inside android {}
    final updatedBuildGradleContent =
        '${buildGradleContent.substring(0, insertPositionInsideAndroid)}\n$codeToInsertInsideAndroid${buildGradleContent.substring(insertPositionInsideAndroid)}';

    // Write the updated content back to build.gradle
    buildGradleFile.writeAsStringSync(updatedBuildGradleContent);

    print("\nRelease key configured successfully in build.gradle.");
  }
}
