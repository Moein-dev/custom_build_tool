## custom_build_tool: Streamline Version Updates and APK Builds in Flutter Projects

This package empowers you to automate version updates and build APKs for your Flutter projects with ease. It provides a user-friendly command-line interface (CLI) that simplifies these tasks, saving you time and effort.

Key Features:

. Automatic Version Updates (Optional): Increment the version number in your pubspec.yaml file prior to building the APK. You can configure this behavior to suit your workflow.
. Build APKs: Seamlessly trigger Flutter's build command to generate an APK for your project.
. Custom Build Types (Optional): Support for various build types (e.g., release, debug, profile) allows for targeted builds based on your needs.
Installation:

There are two primary methods to integrate custom_build_tool into your Flutter project:

1. Local Usage:

Clone or Download the Package: Obtain the source code for custom_build_tool.
Link the Package:
Symlinking:
Navigate to the root directory of your Flutter project and run:

Bash
ln -s <path_to_package> packages/custom_build_tool
Use code with caution.
content_copy
Replace <path_to_package> with the absolute path to your custom_build_tool directory.

Path Dependency:

In your project's pubspec.yaml file, add the following under dev_dependencies:

YAML
dev_dependencies:
<custom_build_tool: ^1.0.0>

content_copy
2. Publishing on pub.dev (Optional):

Package Preparation:
Ensure your package adheres to pub.dev publishing guidelines (<https://dart.dev/tools/pub/publishing>).
This includes comprehensive documentation, thorough testing, and clear versioning.
Create a pub.dev Account: Register for a free pub.dev account if you haven't already.
Publish the Package: Use the pub publish command to make your package available on pub.dev.
This might require additional configuration and authentication steps. Refer to pub.dev documentation for detailed instructions.
Usage:

Once the package is linked (for local usage), navigate to your project's root directory and execute the following command:

Bash
flutter run --no-pub-cache --dart-define=FLUTTER_ROOT=PATH_TO_FLUTTER_SDK flutter:custom_build_tool [--no-version] [build-type]
Use code with caution.
content_copy
Replace PATH_TO_FLUTTER_SDK with the actual path to your Flutter SDK.
--no-version (optional): Skips automatic version update.
build-type (optional): Specify the build type (e.g., release, debug, profile).
Example Usage:

To build a release APK with automatic version update:

Bash
flutter run --no-pub-cache --dart-define=FLUTTER_ROOT=PATH_TO_FLUTTER_SDK flutter:custom_build_tool
Use code with caution.

We appreciate contributions to this package!

License:

This package is distributed under the permissive MIT License.

Additional Considerations:

This package is initially intended for local usage within your Flutter projects.
For publishing on pub.dev, ensure proper documentation, testing, and adherence to pub.dev guidelines.
Future Enhancements (Optional):

Explore advanced features like more granular version update control (e.g., patch/minor/major versions) or custom version update logic.
Consider implementing support for different output paths for APKs depending on the build type.
We hope this enhanced README.md provides a clear and comprehensive guide to using custom_build_tool. Feel free to provide feedback or suggestions for further improvements!
