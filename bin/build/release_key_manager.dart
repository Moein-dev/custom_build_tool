import 'dart:io';

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
      'android${Platform.pathSeparator}app${Platform.pathSeparator}key.jks',
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
      print("\nError: Failed to create the keystore. Please check the keytool output for details.");
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

    String buildGradlePath = 'android/app/build.gradle';
    File buildGradleFile = File(buildGradlePath);

    if (!buildGradleFile.existsSync()) {
      print("\nError: build.gradle file not found.");
      exit(1);
    }

    String buildGradleContent = buildGradleFile.readAsStringSync();

    if (!buildGradleContent.contains('keystoreProperties')) {
      buildGradleContent = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

  $buildGradleContent
      ''';
    }

    if (!buildGradleContent.contains('signingConfigs')) {
      buildGradleContent = buildGradleContent.replaceFirst('android {', '''
android {
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
            signingConfig signingConfigs.release
        }
    }
''');
    }

    buildGradleFile.writeAsStringSync(buildGradleContent.replaceAll('<store-password>', keyPropertiesFile.readAsLinesSync()[0].split('=')[1].trim())
        .replaceAll('<key-password>', keyPropertiesFile.readAsLinesSync()[1].split('=')[1].trim())
        .replaceAll('<key-alias>', keyPropertiesFile.readAsLinesSync()[2].split('=')[1].trim()));

    print("\nRelease key configured successfully in build.gradle.");
  }
}
