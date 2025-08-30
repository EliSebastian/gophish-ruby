# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation with getting started guide, API reference, and examples
- Enhanced README with detailed usage instructions and configuration examples

### Changed
- Improved error messages for validation failures
- Enhanced CSV import validation with better error reporting

### Fixed
- Console script requiring wrong file name (`gophish_ruby` → `gophish-ruby`)
- Spec helper requiring wrong file name for consistent naming

## [0.1.0] - 2025-08-29

### Added
- **Core SDK Foundation**
  - `Gophish::Configuration` class for managing API credentials and settings
  - `Gophish::Base` abstract class providing common CRUD operations
  - HTTParty integration for API communication with automatic authentication
  - ActiveModel integration for attributes, validations, and callbacks

- **Group Management**
  - `Gophish::Group` class for managing target groups
  - Full CRUD operations (create, read, update, delete)
  - Comprehensive validations for group name and target data
  - Support for target attributes: first_name, last_name, email, position

- **CSV Import Functionality**
  - `#import_csv` method for bulk target import
  - Automatic parsing of CSV with standard headers (First Name, Last Name, Email, Position)
  - Data validation during import process

- **Change Tracking**
  - Automatic tracking of attribute changes using ActiveModel
  - `#changed_attributes`, `#attribute_changed?`, and `#attribute_was` methods
  - Support for detecting modifications before saving

- **Configuration Management**
  - Block-style configuration with `Gophish.configure`
  - Support for API URL, API key, SSL verification, and debug output
  - Environment-friendly configuration options

- **Validation System**
  - Required field validations for groups and targets
  - Email format validation using regex pattern
  - Comprehensive error reporting with detailed messages
  - Integration with ActiveModel validations

- **API Integration**
  - RESTful API endpoint mapping with automatic pluralization
  - JSON request/response handling
  - Error handling for API failures
  - Support for SSL configuration including development environments

- **Development Tools**
  - Interactive console (`bin/console`) for testing and exploration
  - RSpec test framework integration
  - RuboCop linting configuration
  - Rake tasks for testing and quality checks

### Technical Details
- **Dependencies**: HTTParty 0.23.1, ActiveSupport/ActiveModel/ActiveRecord 8.0+
- **Ruby Version**: Requires Ruby >= 3.1.0
- **Architecture**: Modular design with inheritance-based API resources
- **Security**: Built-in API key authentication for all requests

### Development Infrastructure
- Bundler gem management with proper gemspec configuration
- GitHub integration with proper repository URLs and metadata
- MIT license for open source distribution
- Code of conduct and contributing guidelines
- Comprehensive test suite foundation with RSpec

This initial release provides a solid foundation for interacting with the Gophish API, focusing on group management as the primary use case while establishing patterns for future resource implementations.