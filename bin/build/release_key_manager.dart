import 'dart:io';

class ReleaseKeyManager {
  static bool promptForReleaseKeyCreation() {
    print("Do you want to create a release key?\n");
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

  static void configureReleaseKeyInGradle() {
    print("\nConfiguring release key in build.gradle...");

    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();

      // Ensure keystoreProperties are loaded
      if (!content.contains('def keystoreProperties')) {
        content = content.replaceFirst(
          'android {',
          '''def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {'''
        );
      }

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
        'signingConfig signingConfigs.debug',
        'signingConfig signingConfigs.release'
      );
      buildGradle.writeAsStringSync(content);
    }
  }

  static bool checkReleaseKeyExists() {
    File buildGradle = File('android${Platform.pathSeparator}app${Platform.pathSeparator}build.gradle');
    if (buildGradle.existsSync()) {
      String content = buildGradle.readAsStringSync();
      return content.contains('signingConfig signingConfigs.release');
    }
    return false;
  }
}
