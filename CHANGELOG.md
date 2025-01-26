# Changes

## [1.2.16] - 2024-06-07

- Initial release of version 1.2.16.
- Added new features and fixed bugs.

## [1.2.17] - 2024-06-07

- Update README file

## [1.2.18] - 2024-06-07

- Set platforms in package

## [1.2.19] - 2024-07-22

- fix some bugs

## [1.2.20] - 2024-07-22

- fix some issues

## [1.2.21] - 2024-07-22

- fix some bugs about build types

## [1.2.22] - 2024-07-22

- update settings for default settings

## [1.2.23] - 2023-10-20

### Added

- **Non-blocking Input**: Users can now select options by pressing a single key (e.g., `1`, `2`, `q`) without needing to press `Enter`.
- **Password Input Masking**: Sensitive inputs (e.g., keystore passwords) are now masked during release key creation for improved security.

### Improved

- **User Experience**: The CLI interface is now more interactive and responsive, providing a smoother experience.
- **Terminal Settings Management**: Terminal settings (e.g., `echoMode` and `lineMode`) are now properly restored after input operations.

### Fixed

- **Input Handling**: Resolved issues with input validation and error handling during user interactions.
- **Edge Cases**: Improved handling of edge cases, such as invalid input or unexpected termination (e.g., `Ctrl+C`).

### Technical Changes

- **Refactored Input Handling**: Introduced a new utility function `_readKey()` for non-blocking input and `_readLineWithEcho()` for masked input.
- **Async/Await Integration**: Updated all input-related methods to use `async/await` for better readability and maintainability.
