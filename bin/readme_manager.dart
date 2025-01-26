import 'dart:io';
import 'utils/input_handler.dart';

class ReadmeManager {
  static void promptForReadmeUpdate(String version) async {
    print("\nDo you want to add details in README.md for this version?\n");
    print("1. Yes");
    print("2. No");
    stdout.write("\n => ");
    final input = await InputHandler.readKey();

    if (input == '1') {
      print(
          "\nEnter the details for this version (end input with an empty line):");

      StringBuffer detailsBuffer = StringBuffer();
      while (true) {
        String? line = stdin.readLineSync();
        if (line == null || line.isEmpty) {
          break;
        }
        detailsBuffer.writeln(line);
      }

      String details = detailsBuffer.toString().trim();
      _updateReadme(version, details);
    }
  }

  static void _updateReadme(String version, String details) {
    String readmePath = 'README.md';
    File readmeFile = File(readmePath);

    if (!readmeFile.existsSync()) {
      readmeFile.createSync();
    }

    String readmeContent = readmeFile.readAsStringSync();

    String newContent = '''
### Updates

version: $version
$details

$readmeContent
  '''
        .trim();

    readmeFile.writeAsStringSync(newContent);

    print("\nREADME.md updated with the new version details.");
  }
}
