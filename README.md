## custom_build_tool: Streamline Version Updates and APK Builds in Flutter Projects

This package empowers you to automate version updates and build APKs for your Flutter projects with ease. It provides a user-friendly command-line interface (CLI) that simplifies these tasks, saving you time and effort.

Key Features:

- Automatically increments the build number and patch version.
- Supports `release`, `debug`, and `profile` build types.
- Optionally skips version incrementing with the `--no-version` flag.
- Renames the output APK file based on the app name, version, and build type.

## Usage

```sh
flutter pub run custom_build_tool [--no-version] [release|debug|profile]
