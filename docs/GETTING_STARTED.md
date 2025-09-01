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

### 4. Create Your First Template

Templates define the email content for your phishing campaigns:

```ruby
# Create a basic email template
template = Gophish::Template.new(
  name: "Security Awareness Test",
  subject: "Important Security Update Required",
  html: "<h1>Security Update</h1><p>Please click <a href='{{.URL}}'>here</a> to update your password.</p>",
  text: "Security Update\n\nPlease visit {{.URL}} to update your password."
)

if template.save
  puts "✓ Template created successfully with ID: #{template.id}"
else
  puts "✗ Failed to create template:"
  template.errors.full_messages.each { |error| puts "  - #{error}" }
end
```

### 5. Create Your First Landing Page

Landing pages are what users see when they click phishing links:

```ruby
# Create a basic landing page
page = Gophish::Page.new(
  name: "Microsoft Login Page",
  html: <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Microsoft Account</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 400px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; }
        input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ccc; border-radius: 4px; }
        button { width: 100%; padding: 12px; background: #0078d4; color: white; border: none; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Sign in to your account</h2>
        <form method="post">
          <input type="email" name="username" placeholder="Email" required>
          <input type="password" name="password" placeholder="Password" required>
          <button type="submit">Sign in</button>
        </form>
      </div>
    </body>
    </html>
  HTML,
  capture_credentials: true,
  redirect_url: "https://www.microsoft.com"
)

if page.save
  puts "✓ Landing page created successfully with ID: #{page.id}"
  puts "  Captures credentials: #{page.captures_credentials?}"
else
  puts "✗ Failed to create page:"
  page.errors.full_messages.each { |error| puts "  - #{error}" }
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

### Working with Templates

#### Creating Templates with Attachments

```ruby
# Create template with file attachments
template = Gophish::Template.new(
  name: "Invoice Template",
  subject: "Your Invoice #{{.RId}}",
  html: "<p>Dear {{.FirstName}},</p><p>Please find your invoice attached.</p>"
)

# Add PDF attachment
pdf_content = File.read("sample_invoice.pdf")
template.add_attachment(pdf_content, "application/pdf", "invoice.pdf")

# Check attachments
puts "Template has #{template.attachment_count} attachments" if template.has_attachments?

template.save
```

#### Importing Email Templates

```ruby
# Import an existing email (.eml file)
email_content = File.read("phishing_template.eml")

imported_data = Gophish::Template.import_email(
  email_content, 
  convert_links: true  # Convert links for Gophish tracking
)

template = Gophish::Template.new(imported_data)
template.name = "Imported Email Template"
template.save

puts "Imported template: #{template.name}"
```

#### Managing Existing Templates

```ruby
# List all templates
puts "Existing templates:"
Gophish::Template.all.each do |template|
  attachment_info = template.has_attachments? ? " (#{template.attachment_count} attachments)" : ""
  puts "  #{template.id}: #{template.name}#{attachment_info}"
end

# Update a template
template = Gophish::Template.find(1)
template.subject = "Updated Subject Line"
template.html = "<h1>Updated Content</h1><p>New message content here.</p>"

# Add or remove attachments
template.add_attachment(File.read("new_file.pdf"), "application/pdf", "new_file.pdf")
template.remove_attachment("old_file.pdf")

template.save
```

### Working with Landing Pages

#### Creating Pages with Different Features

```ruby
# Simple page without credential capture
basic_page = Gophish::Page.new(
  name: "Generic Landing Page",
  html: "<html><body><h1>Thank you!</h1><p>Your action has been completed.</p></body></html>"
)

# Page with credential capture and redirect
login_page = Gophish::Page.new(
  name: "Banking Login Clone",
  html: <<~HTML
    <html>
    <head>
      <title>Secure Banking</title>
      <style>
        body { font-family: Arial, sans-serif; background: #003366; color: white; padding: 50px; }
        .form-container { max-width: 350px; margin: 0 auto; background: white; color: black; padding: 30px; border-radius: 8px; }
        input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; }
        button { width: 100%; padding: 12px; background: #003366; color: white; border: none; cursor: pointer; }
      </style>
    </head>
    <body>
      <div class="form-container">
        <h2>Online Banking Login</h2>
        <form method="post">
          <input type="text" name="username" placeholder="Username" required>
          <input type="password" name="password" placeholder="Password" required>
          <button type="submit">Login</button>
        </form>
      </div>
    </body>
    </html>
  HTML,
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://www.realbank.com/login"
)

# Save both pages
[basic_page, login_page].each do |page|
  if page.save
    puts "✓ Created page: #{page.name} (ID: #{page.id})"
    puts "  Captures credentials: #{page.captures_credentials?}"
  end
end
```

#### Importing Pages from Existing Websites

```ruby
# Import a real website as a landing page template
begin
  imported_data = Gophish::Page.import_site(
    "https://login.live.com",
    include_resources: true  # Include CSS, JS, and images
  )
  
  page = Gophish::Page.new(imported_data)
  page.name = "Microsoft Live Login Clone"
  page.capture_credentials = true
  
  if page.save
    puts "✓ Successfully imported website as landing page"
    puts "  Page ID: #{page.id}"
    puts "  HTML size: #{page.html.length} characters"
  end
  
rescue StandardError => e
  puts "✗ Failed to import website: #{e.message}"
  puts "  Falling back to manual page creation"
  
  # Create a manual fallback page
  fallback_page = Gophish::Page.new(
    name: "Manual Microsoft Login Clone",
    html: "<html><body><h1>Microsoft</h1><form method='post'><input name='email' type='email' placeholder='Email'><input name='password' type='password' placeholder='Password'><button type='submit'>Sign in</button></form></body></html>",
    capture_credentials: true
  )
  fallback_page.save
end
```

#### Managing Existing Pages

```ruby
# List all pages
puts "Existing pages:"
Gophish::Page.all.each do |page|
  credential_info = page.captures_credentials? ? " [Captures Credentials]" : ""
  redirect_info = page.has_redirect? ? " → #{page.redirect_url}" : ""
  puts "  #{page.id}: #{page.name}#{credential_info}#{redirect_info}"
end

# Update a page
page = Gophish::Page.find(1)
page.name = "Updated Page Name"
page.capture_credentials = true
page.redirect_url = "https://example.com/success"

# Modify the HTML content
page.html = page.html.gsub("Sign in", "Login")

if page.save
  puts "✓ Page updated successfully"
  puts "  Now captures credentials: #{page.captures_credentials?}"
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
