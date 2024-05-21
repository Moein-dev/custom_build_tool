import 'dart:developer';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/services.dart'; // For pubspec.yaml manipulation

void main(List<String> arguments) async {
  final parser = ArgParser();
  parser.addFlag('no-version', abbr: 'n', help: 'Skip automatic version update');
  parser.addOption('build-type', abbr: 't', help: 'Build type (release, debug, profile)', defaultsTo: 'release');

  final results = parser.parse(arguments);

  // Get app name and current version from pubspec.yaml
  final String appName = await _getAppNameFromPubspec();
  final String currentVersion = await _getVersionFromPubspec();

  if (!results['no-version']) {
    // Update version (similar logic from Bash script)
    final List<String> versionParts = currentVersion.split('+');
    final String semanticVersion = versionParts[0];
    int buildNumber = int.parse(versionParts.length > 1 ? versionParts[1] : '0');

    buildNumber++;

    final List<int> versionNumbers = semanticVersion.split('.').map(int.parse).toList();
    if (versionNumbers[2] >= 10) {
      versionNumbers[2] = 0;
      versionNumbers[1]++;
    }
    if (versionNumbers[1] >= 10) {
      versionNumbers[1] = 0;
      versionNumbers[0]++;
    }

    final String newVersion = '${versionNumbers[0]}.${versionNumbers[1]}.${versionNumbers[2]}+$buildNumber';

    await _updateVersionInPubspec(newVersion);

    log('Version updated to $newVersion');
  } else {
    log('Using existing version $currentVersion');
  }

  // Build the APK
  final exitCode = await Process.run('flutter', ['build', 'apk']);
  if (exitCode != 0) {
    throw Exception('Failed to build APK. Exit code: $exitCode');
  }

  // Get the default output path based on build type (adjust if needed)
  final String apkPath = 'build/app/outputs/flutter-apk/app-${results['build-type']}.apk';

  // Construct the new APK filename
  final String newApkName = '${appName}_v${currentVersion.split('+')[0]}_${results['build-type']}.apk';

  // Rename the APK
  await File(apkPath).rename('build/app/outputs/flutter-apk/$newApkName');

  log('APK renamed to $newApkName');
  log('You can find the APK at:');
  log('file://${Directory.current.path}/build/app/outputs/flutter-apk/$newApkName');
}

Future<String> _getAppNameFromPubspec() async {
  final String content = await rootBundle.loadString('pubspec.yaml');
  final match = RegExp(r'^name: (.+)$', multiLine: true).firstMatch(content);
  if (match != null) {
    return match.group(1)!.trim();
  } else {
    throw Exception('Failed to find app name in pubspec.yaml');
  }
}

Future<String> _getVersionFromPubspec() async {
  final String content = await rootBundle.loadString('pubspec.yaml');
  final match = RegExp(r'^version: (.+)$', multiLine: true).firstMatch(content);
  if (match != null) {
    return match.group(1)!.trim();
  } else {
    throw Exception('Failed to find version in pubspec.yaml');
  }
}

Future<void> _updateVersionInPubspec(String newVersion) async {
  final String content = await rootBundle.loadString('pubspec.yaml');
  final String updatedContent = content.replaceAll(RegExp(r'^version: .+$', multiLine: true), 'version: $newVersion');
  await File('pubspec.yaml').writeAsString(updatedContent);
}
