import 'dart:io';

void main(List<String> arguments) {
  List<String> values = [];
  values.addAll(arguments.toList());

  if (values.contains("--help")) {
    print("Usage: flutter pub run custom_build_tool [--no-version] [release|debug|profile]");
    exit(1);
  } else {
    // Check for --no-version flag
    bool noVersion = false;
    if (values.contains("--no-version")) {
      noVersion = true;
      values.remove("--no-version");
    }

    // Get the app name from pubspec.yaml
    String appName =
        File('pubspec.yaml').readAsStringSync().split('\n').firstWhere(
              (line) => line.startsWith('name:'),
              orElse: () => '',
            );

    // Set default build type to 'release' if not provided
    String buildType = values.isNotEmpty ? values.first : "release";
    String currentVersion =
        File('pubspec.yaml').readAsStringSync().split('\n').firstWhere(
              (line) => line.startsWith('version:'),
              orElse: () => '',
            );
    String version = currentVersion.substring(8);
    String semanticVersion = version.trim().split('+').first;

    if (!noVersion) {
      // Read the current version from pubspec.yaml

      String semver = version.split(' ').last.split('+').first;
      int buildNumber = int.parse(version.split('+').last);

      // Increment the build number
      int newBuildNumber = buildNumber + 1;

      List<String> parts = semver.split('.');
      int major = int.parse(parts[0]);
      int minor = int.parse(parts[1]);
      int patch = int.parse(parts[2]);

      // Increment the patch version
      patch++;

      // If patch reaches 10, reset to 0 and increment minor version
      if (patch >= 10) {
        patch = 0;
        minor++;
      }

      // If minor reaches 10, reset to 0 and increment major version
      if (minor >= 10) {
        minor = 0;
        major++;
      }

      // Create the new version
      String newVersion = "version: $major.$minor.$patch+$newBuildNumber";

      // Write the new version back to pubspec.yaml
      String pubspecContent = File('pubspec.yaml')
          .readAsStringSync()
          .replaceFirst(currentVersion, newVersion);
      File('pubspec.yaml').writeAsStringSync(pubspecContent);

      print("Version updated to $newVersion");
    } else {
      print("Using existing version $version");
    }

    // Run flutter build apk based on the build type
    Process.runSync('flutter', ['build', 'apk']);

    appName = appName.split(' ').last;

    // Define the new APK file name
    String newApkName = "${appName}_v${semanticVersion}_$buildType.apk";

    // Determine the output APK path based on build type
    String apkPath = "build/app/outputs/flutter-apk/app-release.apk";

    // Rename the APK file
    String newApkPath = "build/app/outputs/flutter-apk/$newApkName";
    File(apkPath).renameSync(newApkPath);

    // Print the clickable path to the APK file
    print("APK renamed to $newApkName");
    print("You can find the APK at:");
    print("\x1B[34mfile://${Directory.current.path}/$newApkPath\x1B[0m");
  }
}
