# Getting Started Guide

This guide will help you get up and running with the Gophish Ruby SDK quickly.

## Prerequisites

- Ruby >= 3.1.0
- A running Gophish server
- API access credentials for your Gophish instance

## Installation

Add the gem to your project:

```bash
# Add to Gemfile
echo 'gem "gophish-ruby"' >> Gemfile
bundle install

# Or install directly
gem install gophish-ruby
```

## Quick Start

### 1. Configure the SDK

First, configure the SDK with your Gophish server details:

```ruby
require 'gophish-ruby'

Gophish.configure do |config|
  config.url = "https://your-gophish-server.com"
  config.api_key = "your-api-key-here"
  config.verify_ssl = true
  config.debug_output = false
end
```

**Getting Your API Key:**

1. Log into your Gophish admin panel
2. Navigate to Settings → Users
3. Click on your user account
4. Copy the API Key from the user details

### 2. Test the Connection

Verify your configuration works:

```ruby
# Try to fetch existing groups (should return empty array if none exist)
begin
  groups = Gophish::Group.all
  puts "✓ Connected successfully! Found #{groups.length} groups."
rescue StandardError => e
  puts "✗ Connection failed: #{e.message}"
  puts "Please check your configuration."
end
```

### 3. Create Your First Group

```ruby
# Create a simple group with one target
group = Gophish::Group.new(
  name: "My First Group",
  targets: [
    {
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      position: "Tester"
    }
  ]
)

if group.save
  puts "✓ Group created successfully with ID: #{group.id}"
else
  puts "✗ Failed to create group:"
  group.errors.full_messages.each { |error| puts "  - #{error}" }
end
```

## Common Workflows

### Importing Targets from CSV

The most common use case is importing a list of targets from a CSV file:

```ruby
# Prepare your CSV file with headers: First Name,Last Name,Email,Position
csv_content = <<~CSV
  First Name,Last Name,Email,Position
  John,Doe,john@company.com,Manager
  Jane,Smith,jane@company.com,Developer
  Bob,Wilson,bob@company.com,Analyst
CSV

# Create and import
group = Gophish::Group.new(name: "Company Employees")
group.import_csv(csv_content)

puts "Imported #{group.targets.length} targets"
group.save
```

### Reading from a File

```ruby
# Read CSV from file
csv_content = File.read("employees.csv")

group = Gophish::Group.new(name: "Employees")
group.import_csv(csv_content)

if group.valid?
  group.save
  puts "Imported #{group.targets.length} employees"
else
  puts "Validation errors:"
  group.errors.full_messages.each { |error| puts "  - #{error}" }
end
```

### Managing Existing Groups

```ruby
# List all groups
puts "Existing groups:"
Gophish::Group.all.each do |group|
  puts "  #{group.id}: #{group.name} (#{group.targets.length} targets)"
end

# Find and update a specific group
group = Gophish::Group.find(1)
group.name = "Updated Group Name"

# Add new targets
group.targets << {
  first_name: "New",
  last_name: "Employee",
  email: "new.employee@company.com",
  position: "Intern"
}

group.save
```

### Deleting Groups

```ruby
# Find and delete a group
group = Gophish::Group.find(1)
if group.destroy
  puts "Group deleted successfully"
else
  puts "Failed to delete group"
end
```

## Error Handling

Always handle errors gracefully in production code:

```ruby
def create_group_safely(name, csv_file_path)
  # Read CSV file
  begin
    csv_content = File.read(csv_file_path)
  rescue Errno::ENOENT
    puts "Error: CSV file not found at #{csv_file_path}"
    return false
  end

  # Create group
  group = Gophish::Group.new(name: name)

  # Import CSV
  begin
    group.import_csv(csv_content)
  rescue CSV::MalformedCSVError => e
    puts "Error: Invalid CSV format - #{e.message}"
    return false
  end

  # Validate
  unless group.valid?
    puts "Validation errors:"
    group.errors.full_messages.each { |error| puts "  - #{error}" }
    return false
  end

  # Save
  unless group.save
    puts "Save failed:"
    group.errors.full_messages.each { |error| puts "  - #{error}" }
    return false
  end

  puts "✓ Group '#{name}' created successfully with #{group.targets.length} targets"
  true
end

# Usage
create_group_safely("Sales Team", "sales_team.csv")
```

## Development Setup

For development and testing, you might want to use different settings:

```ruby
# Development configuration
if ENV['RAILS_ENV'] == 'development' || ENV['RUBY_ENV'] == 'development'
  Gophish.configure do |config|
    config.url = "https://localhost:3333"
    config.api_key = "dev-api-key"
    config.verify_ssl = false  # For self-signed certificates
    config.debug_output = true  # See HTTP requests
  end
else
  # Production configuration
  Gophish.configure do |config|
    config.url = ENV['GOPHISH_URL']
    config.api_key = ENV['GOPHISH_API_KEY']
    config.verify_ssl = true
    config.debug_output = false
  end
end
```

## Validation and Data Quality

The SDK provides comprehensive validation:

### Required Fields

All these fields are required for each target:

- `first_name`
- `last_name`
- `email` (must be valid format)
- `position`

### Email Validation

The SDK validates email format using a regex pattern:

```ruby
# Valid emails
"user@example.com"
"first.last@company.co.uk"
"user+tag@domain.org"

# Invalid emails (will cause validation errors)
"invalid-email"
"@domain.com"
"user@"
""
```

### Custom Validation

You can check validation before saving:

```ruby
group = Gophish::Group.new(name: "Test", targets: [...])

if group.valid?
  puts "✓ All validations passed"
  group.save
else
  puts "✗ Validation failed:"

  # Show all errors
  group.errors.full_messages.each { |error| puts "  - #{error}" }

  # Check specific field errors
  if group.errors[:name].any?
    puts "Name issues: #{group.errors[:name].join(', ')}"
  end

  if group.errors[:targets].any?
    puts "Target issues: #{group.errors[:targets].join(', ')}"
  end
end
```

## Next Steps

Now that you have the basics:

1. **Read the [API Reference](API_REFERENCE.md)** for detailed method documentation
2. **Check out [Examples](EXAMPLES.md)** for more complex scenarios
3. **Set up proper error handling** for production use
4. **Consider security** - never log API keys or sensitive data

## Troubleshooting

### Common Issues

**"Connection refused" errors:**

- Check that your Gophish server is running
- Verify the URL is correct (include protocol: https://)
- Ensure the port is correct

**"SSL certificate verify failed" errors:**

- Set `config.verify_ssl = false` for self-signed certificates
- Or properly configure SSL certificates on your Gophish server

**"Invalid API key" errors:**

- Double-check your API key in the Gophish admin panel
- Ensure there are no extra spaces or characters

**CSV import fails:**

- Verify CSV headers exactly match: "First Name", "Last Name", "Email", "Position"
- Check for malformed CSV data (unescaped quotes, etc.)
- Ensure all required fields are present for each row

**Validation errors:**

- Check that all required fields are present
- Verify email addresses have valid format
- Ensure group name is not empty

### Getting Help

If you encounter issues:

1. Check the [API Reference](API_REFERENCE.md) for detailed documentation
2. Look at [Examples](EXAMPLES.md) for working code samples
3. Open an issue on [GitHub](https://github.com/EliSebastian/gophish-ruby/issues)
4. Consult the [Gophish documentation](https://docs.getgophish.com/) for server-side issues
