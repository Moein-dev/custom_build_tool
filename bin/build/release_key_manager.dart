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

  static void createReleaseKey() {
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
  }

  static void configureReleaseKeyInGradle() {
    print("\nConfiguring release key in build.gradle...");

    File keyPropertiesFile = File('android/key.properties');
    keyPropertiesFile.writeAsStringSync('''
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=key.jks
''');

    // Define the path to the build.gradle file
    final buildGradlePath = join('android', 'app', 'build.gradle');

    // Read the build.gradle file
    final buildGradleFile = File(buildGradlePath);
    if (!buildGradleFile.existsSync()) {
      print('build.gradle file not found!');
      return;
    }

    final buildGradleContent = buildGradleFile.readAsStringSync();

    // Define the code to be inserted after plugins {}
    final codeToInsertAfterPlugins = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
''';

    // Define the code to be inserted inside android {}
    final codeToInsertInsideAndroid = '''
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

    // Find the position after plugins {}
    final pluginsRegex = RegExp(r'plugins\s*\{[^}]*\}');
    final pluginsMatch = pluginsRegex.firstMatch(buildGradleContent);

    if (pluginsMatch == null) {
      print('plugins {} section not found in build.gradle!');
      return;
    }

    final insertPositionAfterPlugins = pluginsMatch.end;

    // Insert the code after plugins {}
    var updatedBuildGradleContent =
        '${buildGradleContent.substring(0, insertPositionAfterPlugins)}\n\n$codeToInsertAfterPlugins${buildGradleContent.substring(insertPositionAfterPlugins)}';

    // Find the android {} section
    final androidRegex = RegExp(r'android\s*\{');
    final androidMatch = androidRegex.firstMatch(updatedBuildGradleContent);

    if (androidMatch == null) {
      print('android {} section not found in build.gradle!');
      return;
    }

    final insertPositionInsideAndroid = androidMatch.end;

    // Insert the code inside android {}
    updatedBuildGradleContent =
        '${updatedBuildGradleContent.substring(0, insertPositionInsideAndroid)}\n$codeToInsertInsideAndroid${updatedBuildGradleContent.substring(insertPositionInsideAndroid)}';

    // Write the updated content back to build.gradle
    buildGradleFile.writeAsStringSync(updatedBuildGradleContent);

    buildGradleFile.writeAsStringSync(buildGradleContent
        .replaceAll('<store-password>',
            keyPropertiesFile.readAsLinesSync()[0].split('=')[1].trim())
        .replaceAll('<key-password>',
            keyPropertiesFile.readAsLinesSync()[1].split('=')[1].trim())
        .replaceAll('<key-alias>',
            keyPropertiesFile.readAsLinesSync()[2].split('=')[1].trim()));

    print("\nRelease key configured successfully in build.gradle.");
  }
}
