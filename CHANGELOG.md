# Changelog

## [1.0.1] - 2024-08-14

### Fixed
- **Critical**: Fixed "Vimscript function must not be called in a fast event context" error
  - Wrapped command handling in `vim.schedule()` to move execution to main event loop
  - Added better error handling for client connections
  - Improved client connection management with proper error callbacks

### Changed
- Enhanced error handling in client communication
- Added connection state checks before writing responses
- Improved logging for debugging connection issues

## [1.0.0] - 2024-08-14

### Added
- Initial release of nvim-theme-ipc plugin
- IPC server for external theme control
- Bash and Python command-line clients
- Comprehensive documentation and examples
- Integration examples for system automation
- Test suite for plugin validation
