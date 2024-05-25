# custom_build_tool

`custom_build_tool` is a Dart/Flutter package designed to help manage and automate custom build processes for Flutter applications. This tool includes features for version incrementing, build type selection, and more.

## Installation

To add `custom_build_tool` to your project, include it in your `dev_dependencies` in the `pubspec.yaml` file:

```yaml
dev_dependencies:
  custom_build_tool:
    git:
      url: https://github.com/Moein-dev/custom_build_tool.git

Then, run the following command to get the package:

```sh
flutter pub get

Usage
Running the Tool
To run the custom_build_tool, use the following command:

```sh
flutter pub run custom_build_tool

Command-Line Options
--reset
Use the --reset option to reset user preferences:

```sh
flutter pub run custom_build_tool --reset

--help
Use the --help option to display help information:

```sh
flutter pub run custom_build_tool --help


Example
Here's a step-by-step example of how to use the custom_build_tool in your Flutter project:

1. Add the package to pubspec.yaml:

dev_dependencies:
  custom_build_tool:
    git:
      url: https://github.com/Moein-dev/custom_build_tool.git

2. Get the package:

```sh
flutter pub get

3. run the tool:

```sh
flutter pub run custom_build_tool

4. Reset preferences if needed:

```sh
flutter pub run custom_build_tool --reset

5. Display help information:

```sh
flutter pub run custom_build_tool --help

Features
. Version Incrementing: Automatically increments the version number in pubspec.yaml.
. Build Type Selection: Allows users to select the build type (release, debug, profile) interactively.
. Customizable Preferences: Preferences can be saved and reset as needed.


Contributing
If you want to contribute to this project, please feel free to submit issues, fork the repository, and send pull requests.


License
This project is licensed under the MIT License - see the LICENSE file for details.
