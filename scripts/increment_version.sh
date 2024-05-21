#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [--no-version] [release|debug|profile]"
  exit 1
}

# Check for errors and handle them gracefully
check_error() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Check for --no-version flag
no_version=false
if [ "$1" == "--no-version" ]; then
  no_version=true
  shift
fi

# Set default build type to 'release' if not provided
build_type=${1:-release}

# Handle cases where pubspec.yaml is not found
if [ ! -f "pubspec.yaml" ]; then
  echo "Error: pubspec.yaml not found."
  exit 1
fi

if [ "$no_version" == false ]; then
  # Read the current version from pubspec.yaml
  current_version=$(grep -E '^version: ' pubspec.yaml | cut -d ' ' -f 2 || true)
  check_error "Failed to read version from pubspec.yaml"

  IFS='+' read -r semver build_number <<< "$current_version"

  # Increment the build number
  new_build_number=$((build_number + 1))

  # Split the semantic version into parts
  IFS='.' read -r major minor patch <<< "$semver"

  # Implement semantic versioning logic
  patch=$((patch + 1))
  if [ $patch -ge 10 ]; then
    patch=0
    minor=$((minor + 1))
  fi
  if [ $minor -ge 10 ]; then
    minor=0
    major=$((major + 1))
  fi

  # Create the new version
  new_version="$major.$minor.$patch+$new_build_number"

  # Write the new version back to pubspec.yaml
  sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml
  check_error "Failed to update version in pubspec.yaml"

  echo "Version updated to $new_version"
else
  # Read the current version without updating
  current_version=$(grep -E '^version: ' pubspec.yaml | cut -d ' ' -f 2 || true)
  check_error "Failed to read version from pubspec.yaml"

  IFS='+' read -r semver build_number <<< "$current_version"
  new_version="$semver+$build_number"
  echo "Using existing version $new_version"
fi

# Run flutter build apk based on the build type
flutter build apk
check_error "Failed to build APK"

# Get the app name from pubspec.yaml
app_name=$(grep -E '^name: ' pubspec.yaml | cut -d ' ' -f 2 || true)
check_error "Failed to read app name from pubspec.yaml"

# Extract the semantic version part (without build number)
IFS='+' read -r semantic_version build_number <<< "$new_version"

# Define the new APK file name
new_apk_name="${app_name}_v${semantic_version}_${build_type}.apk"

# Customize the output APK path if needed
apk_path="build/app/outputs/flutter-apk/app-${build_type}.apk"

# Rename the APK file
new_apk_path="build/app/outputs/flutter-apk/${new_apk_name}"
mv "$apk_path" "$new_apk_path"

# Consider alternative methods for a cross-platform clickable path
echo "APK renamed to ${new_apk_name}"
echo "You can find the APK at:"
echo "file://$(pwd)/${new_apk_path}"
