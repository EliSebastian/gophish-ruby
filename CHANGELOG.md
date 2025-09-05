# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.2] - 2025-09-05

### Added

- **Enhanced Target Management for Groups**
  - New `#add_target(target)` method to add individual targets to existing groups
  - New `#remove_target(target)` method to remove specific targets from groups
  - New `#remove_target_by_email(email)` method to remove targets by email address
  - Improved target manipulation workflow for dynamic group management
  - Support for programmatic target list modifications without full replacement

### Changed

- Updated gem version to 1.1.2
- Enhanced Group class with additional target management capabilities
- Improved README.md with comprehensive examples of new target management methods
- Updated API reference documentation to include new Group instance methods

### Technical Details

- All new methods work with existing target array structure
- Methods maintain data integrity by working with copies of target arrays
- Email-based removal supports both symbol and string keys for flexible target structures
- Backward compatibility maintained with existing target management approaches

### Documentation Updates

- Added practical examples for add_target, remove_target, and remove_target_by_email methods
- Updated "Managing Group Targets" section in README with new workflow examples
- Enhanced API reference documentation with detailed method descriptions
- Included tested code examples for all new target management functionality

## [1.0.0] - 2025-09-01

### Added

- **Campaign Management System** 🎯
  - `Gophish::Campaign` class for creating, managing, and monitoring phishing campaigns
  - Full CRUD operations for campaigns (create, read, update, delete)
  - Campaign scheduling with `launch_date` and `send_by_date` attributes
  - Comprehensive campaign result tracking and analysis
  - Timeline monitoring for detailed campaign progression
  - Campaign status management with `#in_progress?`, `#completed?`, `#launched?` methods
  - Campaign completion functionality with `#complete!` method
  - Class methods for efficient data retrieval: `.get_results()`, `.get_summary()`, `.complete()`
  - Support for referencing existing templates, pages, groups, and SMTP profiles
  - Automatic validation of all campaign components and dependencies

- **Campaign Result Analysis**
  - `Campaign::Result` nested class for individual target interaction tracking
  - Detailed result status methods: `#clicked?`, `#opened?`, `#sent?`, `#submitted_data?`, `#reported?`
  - Geographic tracking with latitude/longitude coordinates
  - IP address tracking for security analysis
  - Comprehensive result validation and error handling

- **Campaign Timeline Tracking**
  - `Campaign::Event` nested class for timeline event management
  - Detailed event tracking with timestamps, messages, and JSON details
  - Event analysis methods: `#has_details?`, `#parsed_details`
  - Complete campaign progression monitoring

- **Enhanced Template Management**
  - Added `envelope_sender` attribute to Template class for advanced email delivery control
  - New `#has_envelope_sender?` method to check envelope sender configuration
  - Improved email header management capabilities
  - Enhanced template validation with envelope sender support

### Changed

- Updated gem version to 1.0.0 (major release with full campaign management)
- Added `require_relative 'gophish/campaign'` to main library file
- Enhanced Template class with envelope sender functionality
- Improved documentation with comprehensive campaign examples
- Updated API documentation to include all campaign-related classes and methods

### Technical Enhancements

- **Advanced Object Conversion System**
  - Intelligent conversion between hash references and object instances
  - Automatic handling of nested object relationships (templates, pages, groups, SMTP)
  - Graceful error handling for unknown attributes during object creation
  - Support for both string names and full object references

- **Comprehensive Validation Framework**
  - Multi-level validation for campaign components
  - Detailed error messages for campaign structure validation
  - Group structure validation with index-specific error reporting
  - Result and timeline data structure validation
  - Enhanced error handling with descriptive failure messages

- **Robust API Integration**
  - Campaign-specific API endpoints for results, summary, and completion
  - Optimized payload building for campaign creation and updates
  - Proper serialization of nested objects and references
  - Enhanced error handling for API communication

### Breaking Changes

- This is a major version release (1.0.0) indicating API stability
- No breaking changes from 0.4.0, fully backward compatible
- Campaign functionality is additive and does not affect existing code

### Documentation Updates

- Complete campaign management examples in README.md
- Enhanced API reference documentation for all campaign-related classes
- Updated getting started guide with campaign examples
- Comprehensive validation and error handling examples
- Production-ready code examples with proper error handling

## [0.4.0] - 2025-09-01

### Added

- **SMTP Management System**
  - `Gophish::Smtp` class for managing SMTP sending profiles in phishing campaigns
  - Full CRUD operations for SMTP profiles (create, read, update, delete)
  - Support for SMTP server configuration with host, from_address, and authentication
  - Comprehensive validations requiring name, host, and valid from_address email format
  - Authentication support with username and password credentials
  - SSL certificate error handling with `ignore_cert_errors` option
  - Custom header management with add/remove functionality
  - Built-in methods for checking SMTP configuration: `#has_authentication?`, `#ignores_cert_errors?`, `#has_headers?`, `#header_count`

### Changed

- Updated gem version to 0.4.0
- Added `require_relative 'gophish/smtp'` to main library file for SMTP class availability

## [0.3.0] - 2025-09-01

### Added

- **Page Management System**
  - `Gophish::Page` class for managing landing pages in phishing campaigns
  - Full CRUD operations for pages (create, read, update, delete)
  - Support for HTML content with credential capture capabilities
  - Comprehensive validations requiring page name and HTML content
  - Site import functionality with `Page.import_site` class method
  - Option to include resources (CSS, JS, images) during site import
  - Built-in methods for checking page configuration: `#captures_credentials?`, `#captures_passwords?`, `#has_redirect?`

- **Template Management System**
  - `Gophish::Template` class for managing email templates
  - Full CRUD operations for templates (create, read, update, delete)
  - Support for HTML and plain text email content
  - Comprehensive validations requiring template name and content
  - Email import functionality with `Template.import_email` class method
  - Option to convert links during email import for tracking

- **Attachment Management**
  - Add attachments to templates with `#add_attachment` method
  - Remove attachments by name with `#remove_attachment` method
  - Query attachment status with `#has_attachments?` and `#attachment_count`
  - Automatic Base64 encoding of attachment content
  - Validation of attachment structure (content, type, name required)

- **Enhanced Change Tracking**
  - Migrated from custom change tracking to ActiveModel::Dirty
  - Improved change detection with `#changed?` and `#clear_changes_information`
  - Better integration with Rails-style attribute tracking

- Comprehensive documentation with getting started guide, API reference, and examples
- Enhanced README with detailed usage instructions and configuration examples

### Changed

- **Breaking Change**: Replaced custom `@changed_attributes` system with ActiveModel::Dirty
- Updated Base class to use `define_attribute_methods` for proper dirty tracking
- Modified `#update_record` to include `id` in update payload for proper API calls
- Improved error messages for validation failures
- Enhanced CSV import validation with better error reporting

### Fixed

- Console script requiring wrong file name (`gophish_ruby` → `gophish-ruby`)
- Spec helper requiring wrong file name for consistent naming
- Corrected require statement in main library file for Template class

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
