import 'dart:io';
import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('no-version', negatable: false, defaultsTo: false)
    ..addOption('type', defaultsTo: 'release');

  final argResults = parser.parse(arguments);
  final noUpdate = argResults['no-version'] as bool;
  final buildType = argResults['type'] as String;

  runShellScript(noUpdate: noUpdate, buildType: buildType);
}

void runShellScript({required bool noUpdate, required String buildType}) async {
  final scriptPath = 'increment_version.sh'; // Update with the actual path

  final arguments = [
    if (noUpdate) '--no-version',
    buildType,
  ];

  final result = await Process.run('bash', [scriptPath, ...arguments]);

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
