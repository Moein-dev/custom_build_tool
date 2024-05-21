#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [--no-version] [release|debug|profile]"
  exit 1
}

# Check for --no-version flag
no-version=false
if [ "$1" == "--no-version" ]; then
  no-version=true
  shift
fi

# Set default build type to 'release' if not provided
build_type=${1:-release}

if [ "$no-version" == false ]; then
  # Read the current version from pubspec.yaml
  current_version=$(grep -E '^version: ' pubspec.yaml | cut -d ' ' -f 2)
  IFS='+' read -r semver build_number <<< "$current_version"

  # Increment the build number
  new_build_number=$((build_number + 1))

  # Split the semantic version into parts
  IFS='.' read -r major minor patch <<< "$semver"

  # Increment the patch version
  patch=$((patch + 1))

  # If patch reaches 10, reset to 0 and increment minor version
  if [ $patch -ge 10 ]; then
    patch=0
    minor=$((minor + 1))
  fi

  # If minor reaches 10, reset to 0 and increment major version
  if [ $minor -ge 10 ]; then
    minor=0
    major=$((major + 1))
  fi

  # Create the new version
  new_version="$major.$minor.$patch+$new_build_number"

  # Write the new version back to pubspec.yaml
  sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml

  echo "Version updated to $new_version"
else
  # Read the current version without updating
  current_version=$(grep -E '^version: ' pubspec.yaml | cut -d ' ' -f 2)
  IFS='+' read -r semver build_number <<< "$current_version"
  new_version="$semver+$build_number"
  echo "Using existing version $new_version"
fi

# Run flutter build apk based on the build type
flutter build apk


# Get the app name from pubspec.yaml
app_name=$(grep -E '^name: ' pubspec.yaml | cut -d ' ' -f 2)

# Extract the semantic version part (without build number)
IFS='+' read -r semantic_version build_number <<< "$new_version"

# Define the new APK file name
new_apk_name="${app_name}_v${semantic_version}_${build_type}.apk"

# Determine the output APK path based on build type
apk_path="build/app/outputs/flutter-apk/app-release.apk"


# Rename the APK file
new_apk_path="build/app/outputs/flutter-apk/${new_apk_name}"
mv "$apk_path" "$new_apk_path"

# Print the clickable path to the APK file
echo "APK renamed to ${new_apk_name}"
echo "You can find the APK at:"
echo -e "\033[1;34mfile://$(pwd)/${new_apk_path}\033[0m"
