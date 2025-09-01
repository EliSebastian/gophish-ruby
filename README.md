# Gophish Ruby SDK

A Ruby SDK for the [Gophish](https://getgophish.com/) phishing simulation platform. This gem provides a comprehensive interface to interact with the Gophish API, enabling security professionals to programmatically manage phishing campaigns for security awareness training.

[![Gem Version](https://badge.fury.io/rb/gophish-ruby.svg)](https://badge.fury.io/rb/gophish-ruby)
[![Ruby](https://img.shields.io/badge/ruby->=3.1.0-ruby.svg)](https://www.ruby-lang.org)

## Features

- **Full API Coverage**: Complete implementation of Gophish API endpoints
- **ActiveModel Integration**: Familiar Rails-like attributes, validations, and callbacks
- **Automatic Authentication**: Built-in API key authentication for all requests
- **CSV Import Support**: Easy bulk import of targets from CSV files
- **Email Template Management**: Create, modify, and manage email templates with attachment support
- **Email Import**: Import existing emails and convert them to templates
- **SSL Configuration**: Configurable SSL verification for development environments
- **Debug Support**: Built-in debugging capabilities for API interactions
- **Change Tracking**: Automatic tracking of attribute changes with ActiveModel::Dirty
- **Comprehensive Validation**: Built-in validations for all data models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gophish-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install gophish-ruby
```

## Configuration

Before using the SDK, you need to configure it with your Gophish API credentials:

```ruby
require 'gophish-ruby'

Gophish.configure do |config|
  config.url = "https://your-gophish-server.com"
  config.api_key = "your-api-key-here"
  config.verify_ssl = true  # Set to false for development/self-signed certificates
  config.debug_output = false  # Set to true to see HTTP debug information
end
```

### Configuration Options

- **`url`**: The base URL of your Gophish server (e.g., `https://gophish.example.com`)
- **`api_key`**: Your Gophish API key (found in the Gophish admin panel)
- **`verify_ssl`**: Whether to verify SSL certificates (default: `true`)
- **`debug_output`**: Enable HTTP debugging output (default: `false`)

## Usage

### Groups Management

Groups represent collections of targets for your phishing campaigns.

#### Creating a Group

```ruby
# Create a new group with targets
group = Gophish::Group.new(
  name: "Marketing Department",
  targets: [
    {
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@company.com",
      position: "Marketing Manager"
    },
    {
      first_name: "Jane",
      last_name: "Smith",
      email: "jane.smith@company.com",
      position: "Marketing Coordinator"
    }
  ]
)

# Save the group to Gophish
if group.save
  puts "Group created successfully with ID: #{group.id}"
else
  puts "Failed to create group: #{group.errors.full_messages}"
end
```

#### Importing from CSV

```ruby
# CSV format: First Name,Last Name,Email,Position
csv_data = <<~CSV
  First Name,Last Name,Email,Position
  Alice,Johnson,alice@company.com,Developer
  Bob,Wilson,bob@company.com,Designer
  Carol,Brown,carol@company.com,Manager
CSV

group = Gophish::Group.new(name: "Development Team")
group.import_csv(csv_data)

if group.save
  puts "Group created with #{group.targets.length} targets"
end
```

#### Retrieving Groups

```ruby
# Get all groups
groups = Gophish::Group.all
puts "Found #{groups.length} groups"

# Find a specific group by ID
group = Gophish::Group.find(1)
puts "Group: #{group.name} with #{group.targets.length} targets"
```

#### Updating a Group

```ruby
# Update group attributes
group = Gophish::Group.find(1)
group.name = "Updated Group Name"

# Add new targets
group.targets << {
  first_name: "New",
  last_name: "User",
  email: "new.user@company.com",
  position: "Intern"
}

if group.save
  puts "Group updated successfully"
end
```

#### Deleting a Group

```ruby
group = Gophish::Group.find(1)
if group.destroy
  puts "Group deleted successfully"
end
```

### Validation and Error Handling

The SDK provides comprehensive validation:

```ruby
# Invalid group (missing required fields)
group = Gophish::Group.new(name: "")

unless group.valid?
  puts "Validation errors:"
  group.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

# Invalid email format
group = Gophish::Group.new(
  name: "Test Group",
  targets: [{
    first_name: "John",
    last_name: "Doe",
    email: "invalid-email",  # Invalid email format
    position: "Manager"
  }]
)

unless group.valid?
  puts group.errors.full_messages
  # => ["Targets item at index 0 must have a valid email format"]
end
```

### Templates Management

Templates define the email content for your phishing campaigns, including HTML/text content and attachments.

#### Creating a Template

```ruby
# Create a new email template
template = Gophish::Template.new(
  name: "Phishing Awareness Test",
  subject: "Security Update Required",
  html: "<h1>Important Security Update</h1><p>Please click <a href='{{.URL}}'>here</a> to update your password.</p>",
  text: "Important Security Update\n\nPlease visit {{.URL}} to update your password."
)

if template.save
  puts "Template created successfully with ID: #{template.id}"
else
  puts "Failed to create template: #{template.errors.full_messages}"
end
```

#### Adding Attachments

```ruby
template = Gophish::Template.new(
  name: "Invoice Template",
  subject: "Invoice #12345",
  html: "<p>Please find your invoice attached.</p>"
)

# Add an attachment
file_content = File.read("path/to/invoice.pdf")
template.add_attachment(file_content, "application/pdf", "invoice.pdf")

puts "Template has #{template.attachment_count} attachments"
```

#### Managing Attachments

```ruby
# Check if template has attachments
if template.has_attachments?
  puts "Template has attachments"
end

# Remove an attachment by name
template.remove_attachment("invoice.pdf")
puts "Attachments remaining: #{template.attachment_count}"
```

#### Importing Email Content

```ruby
# Import an existing email (.eml file content)
email_content = File.read("path/to/email.eml")

imported_data = Gophish::Template.import_email(
  email_content, 
  convert_links: true  # Convert links to Gophish tracking format
)

# Create template from imported data
template = Gophish::Template.new(imported_data)
template.name = "Imported Email Template"
template.save
```

#### Retrieving Templates

```ruby
# Get all templates
templates = Gophish::Template.all
puts "Found #{templates.length} templates"

# Find a specific template by ID
template = Gophish::Template.find(1)
puts "Template: #{template.name}"
```

#### Updating a Template

```ruby
template = Gophish::Template.find(1)
template.subject = "Updated Subject Line"
template.html = "<h1>Updated Content</h1>"

if template.save
  puts "Template updated successfully"
end
```

#### Deleting a Template

```ruby
template = Gophish::Template.find(1)
if template.destroy
  puts "Template deleted successfully"
end
```

### Change Tracking

The SDK automatically tracks changes to attributes using ActiveModel::Dirty:

```ruby
group = Gophish::Group.find(1)
group.name = "New Name"

# Check if attributes have changed
puts group.changed_attributes  # => ["name"]
puts group.attribute_changed?(:name)  # => true
puts group.attribute_was(:name)  # => "Original Name"
```

## API Documentation

### Core Classes

#### `Gophish::Configuration`

Manages SDK configuration including API credentials and connection settings.

**Attributes:**

- `url` (String) - Gophish server URL
- `api_key` (String) - API authentication key
- `verify_ssl` (Boolean) - SSL certificate verification
- `debug_output` (Boolean) - HTTP debug output

#### `Gophish::Base`

Abstract base class providing common functionality for all API resources.

**Class Methods:**

- `.all` - Retrieve all resources
- `.find(id)` - Find resource by ID
- `.resource_name` - Get the resource name for API endpoints
- `.resource_path` - Get the API path for the resource

**Instance Methods:**

- `#save` - Create or update the resource
- `#destroy` - Delete the resource
- `#valid?` - Check if the resource is valid
- `#persisted?` - Check if the resource is saved to the server
- `#new_record?` - Check if the resource is new (not yet saved)
- `#changed_attributes` - Get array of changed attribute names
- `#attribute_changed?(attr)` - Check if specific attribute changed
- `#attribute_was(attr)` - Get previous value of changed attribute

#### `Gophish::Group`

Represents a Gophish target group.

**Attributes:**

- `id` (Integer) - Unique group identifier
- `name` (String) - Group name (required)
- `modified_date` (String) - Last modification timestamp
- `targets` (Array) - Array of target hashes (required)

**Target Structure:**
Each target in the `targets` array should have:

- `first_name` (String) - Target's first name (required)
- `last_name` (String) - Target's last name (required)
- `email` (String) - Target's email address (required, must be valid format)
- `position` (String) - Target's job position (required)

**Instance Methods:**

- `#import_csv(csv_data)` - Import targets from CSV data

#### `Gophish::Template`

Represents a Gophish email template.

**Attributes:**

- `id` (Integer) - Unique template identifier
- `name` (String) - Template name (required)
- `subject` (String) - Email subject line
- `text` (String) - Plain text email content
- `html` (String) - HTML email content
- `modified_date` (String) - Last modification timestamp
- `attachments` (Array) - Array of attachment hashes

**Attachment Structure:**
Each attachment in the `attachments` array should have:

- `content` (String) - Base64 encoded file content (required)
- `type` (String) - MIME type of the attachment (required)
- `name` (String) - Filename of the attachment (required)

**Class Methods:**

- `.import_email(content, convert_links: false)` - Import email content and return template data

**Instance Methods:**

- `#add_attachment(content, type, name)` - Add an attachment to the template
- `#remove_attachment(name)` - Remove an attachment by filename
- `#has_attachments?` - Check if template has any attachments
- `#attachment_count` - Get the number of attachments

**Validations:**

- Template must have a name
- Template must have either text or HTML content (or both)
- All attachments must have content, type, and name

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
# Run all tests
rake spec

# Run specific test file
bundle exec rspec spec/path/to/file_spec.rb

# Run with coverage
COVERAGE=true rake spec
```

### Code Quality

```bash
# Run RuboCop linter
rake rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a

# Run all quality checks
rake  # Equivalent to: rake spec rubocop
```

### Local Installation

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

### Releasing

To release a new version:

1. Update the version number in `lib/gophish/version.rb`
2. Update the `CHANGELOG.md` with the new changes
3. Run `bundle exec rake release` to create a git tag, push commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org)

## Requirements

- Ruby >= 3.1.0
- HTTParty >= 0.23.1
- ActiveSupport >= 8.0
- ActiveModel >= 8.0
- ActiveRecord >= 8.0

## Security Considerations

This gem is designed as a **defensive security tool** for authorized phishing simulations and security awareness training. Users are responsible for:

- Ensuring proper authorization before conducting phishing simulations
- Complying with applicable laws and organizational policies
- Securing API credentials and configuration data
- Using the tool only for legitimate security purposes

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/EliSebastian/gophish-ruby>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/EliSebastian/gophish-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Gophish::Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/EliSebastian/gophish-ruby/blob/main/CODE_OF_CONDUCT.md).

## Support

- [GitHub Issues](https://github.com/EliSebastian/gophish-ruby/issues) - Bug reports and feature requests
- [Gophish Documentation](https://docs.getgophish.com/) - Official Gophish API documentation
- [Ruby Documentation](https://ruby-doc.org/) - Ruby language documentation
