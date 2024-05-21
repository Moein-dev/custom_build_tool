#!/bin/bash

# Navigate to the project root directory
script_dir=$(dirname "$0")
cd "$script_dir/.."

# Import the core logic from the lib directory
source lib/build_manager.dart

# Parse arguments using the imported function
arguments=("$@")
parse_arguments "${arguments[@]}"

# Execute the build process with the parsed arguments
build_apk "$no_version" "$build_type"

exit 0
