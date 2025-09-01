# Gophish Ruby SDK

A Ruby SDK for the [Gophish](https://getgophish.com/) phishing simulation platform. This gem provides a comprehensive interface to interact with the Gophish API, enabling security professionals to programmatically manage phishing campaigns for security awareness training.

[![Gem Version](https://badge.fury.io/rb/gophish-ruby.svg)](https://badge.fury.io/rb/gophish-ruby)
[![Ruby](https://img.shields.io/badge/ruby->=3.1.0-ruby.svg)](https://www.ruby-lang.org)

## Features

- **Full API Coverage**: Complete implementation of Gophish API endpoints
- **ActiveModel Integration**: Familiar Rails-like attributes, validations, and callbacks
- **Automatic Authentication**: Built-in API key authentication for all requests
- **Campaign Management**: Create, launch, monitor, and manage phishing campaigns with comprehensive result tracking
- **CSV Import Support**: Easy bulk import of targets from CSV files
- **Email Template Management**: Create, modify, and manage email templates with attachment support and envelope sender configuration
- **Email Import**: Import existing emails and convert them to templates
- **Site Import**: Import landing pages directly from existing websites
- **Page Management**: Create, modify, and manage landing pages with credential capture
- **SMTP Configuration**: Create, modify, and manage SMTP sending profiles with authentication and header support
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

### Pages Management

Pages represent landing pages that targets will see when they click on phishing links in your campaigns.

#### Creating a Page

```ruby
# Create a simple landing page
page = Gophish::Page.new(
  name: "Microsoft Login Page",
  html: <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Microsoft Account Login</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background-color: #f5f5f5; }
        .login-container { max-width: 400px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; }
        .form-group { margin-bottom: 20px; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; }
        button { width: 100%; padding: 12px; background: #0078d4; color: white; border: none; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="login-container">
        <h2>Sign in to your account</h2>
        <form method="post">
          <div class="form-group">
            <input type="email" name="email" placeholder="Email" required>
          </div>
          <div class="form-group">
            <input type="password" name="password" placeholder="Password" required>
          </div>
          <button type="submit">Sign in</button>
        </form>
      </div>
    </body>
    </html>
  HTML
)

# Save the page to Gophish
if page.save
  puts "Page created successfully with ID: #{page.id}"
else
  puts "Failed to create page: #{page.errors.full_messages}"
end
```

#### Creating a Page with Credential Capture

```ruby
# Create a page that captures login credentials
page = Gophish::Page.new(
  name: "Banking Login - Credential Capture",
  html: <<~HTML
    <html>
    <body>
      <h1>Online Banking</h1>
      <form method="post">
        <input type="text" name="username" placeholder="Username" required>
        <input type="password" name="password" placeholder="Password" required>
        <button type="submit">Login</button>
      </form>
    </body>
    </html>
  HTML,
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://www.realbank.com/login"
)

if page.save
  puts "Page created with credential capture enabled"
  puts "Captures credentials: #{page.captures_credentials?}"
  puts "Captures passwords: #{page.captures_passwords?}"
  puts "Has redirect: #{page.has_redirect?}"
end
```

#### Importing a Website as a Landing Page

```ruby
# Import an existing website as a landing page template
begin
  imported_data = Gophish::Page.import_site(
    "https://login.microsoft.com", 
    include_resources: true  # Include CSS, JS, and images
  )
  
  # Create a page from the imported data
  page = Gophish::Page.new(imported_data)
  page.name = "Imported Microsoft Login Page"
  page.capture_credentials = true
  
  if page.save
    puts "Successfully imported and created page from website"
  end
rescue StandardError => e
  puts "Failed to import site: #{e.message}"
end
```

#### Retrieving Pages

```ruby
# Get all pages
pages = Gophish::Page.all
puts "Found #{pages.length} pages"

# Find a specific page by ID
page = Gophish::Page.find(1)
puts "Page: #{page.name}"
puts "HTML length: #{page.html.length} characters"
```

#### Updating a Page

```ruby
# Update page content and settings
page = Gophish::Page.find(1)
page.name = "Updated Page Name"
page.capture_credentials = true
page.redirect_url = "https://example.com/success"

# Update HTML content
page.html = page.html.gsub("Sign in", "Login")

if page.save
  puts "Page updated successfully"
end
```

#### Deleting a Page

```ruby
page = Gophish::Page.find(1)
if page.destroy
  puts "Page deleted successfully"
end
```

### Validation and Error Handling

The SDK provides comprehensive validation for pages:

```ruby
# Invalid page (missing required fields)
page = Gophish::Page.new(name: "", html: "")

unless page.valid?
  puts "Validation errors:"
  page.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Name can't be blank", "Html can't be blank"]
end

# Check page configuration
page = Gophish::Page.new(
  name: "Test Page",
  html: "<html><body>Test</body></html>",
  capture_credentials: true
)

if page.captures_credentials?
  puts "This page will capture submitted credentials"
end
```

### SMTP Management

SMTP sending profiles define the mail server configuration for sending phishing emails in your campaigns.

#### Creating an SMTP Profile

```ruby
# Create a basic SMTP profile
smtp = Gophish::Smtp.new(
  name: "Company Mail Server",
  host: "smtp.company.com",
  from_address: "security@company.com"
)

# Save the SMTP profile to Gophish
if smtp.save
  puts "SMTP profile created successfully with ID: #{smtp.id}"
else
  puts "Failed to create SMTP profile: #{smtp.errors.full_messages}"
end
```

#### Creating an SMTP Profile with Authentication

```ruby
# Create an SMTP profile with username/password authentication
smtp = Gophish::Smtp.new(
  name: "Gmail SMTP",
  host: "smtp.gmail.com",
  from_address: "phishing@company.com",
  username: "smtp_username",
  password: "smtp_password",
  ignore_cert_errors: false
)

if smtp.save
  puts "SMTP profile created with authentication"
  puts "Has authentication: #{smtp.has_authentication?}"
  puts "Ignores cert errors: #{smtp.ignores_cert_errors?}"
end
```

#### Managing Custom Headers

```ruby
# Add custom headers to the SMTP profile
smtp = Gophish::Smtp.new(
  name: "Custom Headers SMTP",
  host: "mail.company.com",
  from_address: "security@company.com"
)

# Add headers for email routing and identification
smtp.add_header("X-Mailer", "Company Security Tool")
smtp.add_header("X-Campaign-Type", "Phishing Simulation")
smtp.add_header("Return-Path", "bounces@company.com")

puts "Header count: #{smtp.header_count}"
puts "Has headers: #{smtp.has_headers?}"

# Remove a specific header
smtp.remove_header("X-Campaign-Type")
puts "Headers after removal: #{smtp.header_count}"
```

#### Retrieving SMTP Profiles

```ruby
# Get all SMTP profiles
smtp_profiles = Gophish::Smtp.all
puts "Found #{smtp_profiles.length} SMTP profiles"

# Find a specific SMTP profile by ID
smtp = Gophish::Smtp.find(1)
puts "SMTP Profile: #{smtp.name} (#{smtp.host})"
```

#### Updating an SMTP Profile

```ruby
# Update SMTP profile settings
smtp = Gophish::Smtp.find(1)
smtp.name = "Updated SMTP Server"
smtp.ignore_cert_errors = true

# Add new headers
smtp.add_header("X-Priority", "1")

if smtp.save
  puts "SMTP profile updated successfully"
end
```

#### Deleting an SMTP Profile

```ruby
smtp = Gophish::Smtp.find(1)
if smtp.destroy
  puts "SMTP profile deleted successfully"
end
```

### SMTP Validation and Error Handling

The SDK provides comprehensive validation for SMTP profiles:

```ruby
# Invalid SMTP profile (missing required fields)
smtp = Gophish::Smtp.new(name: "", host: "", from_address: "")

unless smtp.valid?
  puts "Validation errors:"
  smtp.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Name can't be blank", "Host can't be blank", "From address can't be blank"]
end

# Invalid email format
smtp = Gophish::Smtp.new(
  name: "Test SMTP",
  host: "smtp.test.com",
  from_address: "invalid-email-format"
)

unless smtp.valid?
  puts smtp.errors.full_messages
  # => ["From address must be a valid email format (email@domain.com)"]
end

# Check SMTP configuration
if smtp.has_authentication?
  puts "SMTP uses authentication"
end

if smtp.ignores_cert_errors?
  puts "SMTP ignores certificate errors (not recommended for production)"
end
```

### Campaign Management

Campaigns are the core of Gophish phishing simulations, orchestrating the sending of phishing emails to target groups using templates, landing pages, and SMTP profiles.

#### Creating a Campaign

```ruby
# Create a basic phishing campaign
campaign = Gophish::Campaign.new(
  name: "Q1 Security Awareness Training",
  template: { name: "Phishing Template" },  # Reference existing template
  page: { name: "Login Page" },             # Reference existing landing page
  groups: [{ name: "Marketing Team" }],     # Reference existing groups
  smtp: { name: "Company SMTP" },           # Reference existing SMTP profile
  url: "https://phishing.company.com"       # Base URL for campaign
)

# Save the campaign to Gophish
if campaign.save
  puts "Campaign created successfully with ID: #{campaign.id}"
  puts "Campaign status: #{campaign.status}"
else
  puts "Failed to create campaign: #{campaign.errors.full_messages}"
end
```

#### Creating a Campaign with Scheduling

```ruby
# Create a campaign with launch and send-by dates
campaign = Gophish::Campaign.new(
  name: "Scheduled Phishing Test",
  template: { name: "Email Template" },
  page: { name: "Landing Page" },
  groups: [{ name: "HR Department" }],
  smtp: { name: "SMTP Profile" },
  url: "https://training.company.com",
  launch_date: "2024-01-15T09:00:00Z",      # When to start sending
  send_by_date: "2024-01-15T17:00:00Z"      # Deadline for sending all emails
)

if campaign.save
  puts "Scheduled campaign created"
  puts "Launched? #{campaign.launched?}"
  puts "Has send by date? #{campaign.has_send_by_date?}"
end
```

#### Monitoring Campaign Status

```ruby
# Check campaign status and progress
campaign = Gophish::Campaign.find(1)

puts "Campaign: #{campaign.name}"
puts "Status: #{campaign.status}"
puts "In progress? #{campaign.in_progress?}"
puts "Completed? #{campaign.completed?}"

# Get campaign results
results = campaign.get_results
puts "Total results: #{results.length}"

# Get campaign summary
summary = campaign.get_summary
puts "Campaign summary: #{summary}"
```

#### Managing Campaign Results

```ruby
# Access detailed campaign results
campaign = Gophish::Campaign.find(1)

campaign.results.each do |result|
  puts "Target: #{result.email}"
  puts "  Status: #{result.status}"
  puts "  Clicked: #{result.clicked?}"
  puts "  Opened: #{result.opened?}"
  puts "  Submitted data: #{result.submitted_data?}"
  puts "  Reported: #{result.reported?}"
  puts "  IP: #{result.ip}" if result.ip
  puts ""
end

# Filter results by status
clicked_results = campaign.results.select(&:clicked?)
puts "#{clicked_results.length} users clicked the link"

reported_results = campaign.results.select(&:reported?)
puts "#{reported_results.length} users reported the email"
```

#### Monitoring Campaign Timeline

```ruby
# Access campaign timeline events
campaign = Gophish::Campaign.find(1)

campaign.timeline.each do |event|
  puts "#{event.time}: #{event.message}"
  puts "  Email: #{event.email}"
  
  # Check for additional details (JSON data)
  if event.has_details?
    details = event.parsed_details
    puts "  Details: #{details}"
  end
  puts ""
end
```

#### Completing a Campaign

```ruby
# Manually complete a running campaign
campaign = Gophish::Campaign.find(1)

if campaign.in_progress?
  result = campaign.complete!
  
  if result['success']
    puts "Campaign completed successfully"
    puts "Final status: #{campaign.status}"
  else
    puts "Failed to complete campaign: #{result['message']}"
  end
else
  puts "Campaign is not in progress"
end
```

#### Retrieving Campaigns

```ruby
# Get all campaigns
campaigns = Gophish::Campaign.all
puts "Found #{campaigns.length} campaigns"

campaigns.each do |campaign|
  puts "#{campaign.name}: #{campaign.status}"
end

# Find a specific campaign by ID
campaign = Gophish::Campaign.find(1)
puts "Campaign: #{campaign.name}"
puts "Groups: #{campaign.groups.map(&:name).join(', ')}"
```

#### Using Class Methods for Results

```ruby
# Get results without loading full campaign
results = Gophish::Campaign.get_results(1)
puts "Campaign has #{results.length} results"

# Get summary without loading full campaign
summary = Gophish::Campaign.get_summary(1)
puts "Campaign summary stats: #{summary['stats']}"

# Complete campaign without loading it
Gophish::Campaign.complete(1)
```

#### Campaign Validation and Error Handling

```ruby
# Invalid campaign (missing required components)
campaign = Gophish::Campaign.new(name: "Incomplete Campaign")

unless campaign.valid?
  puts "Validation errors:"
  campaign.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Template can't be blank", "Page can't be blank", "Groups can't be blank", 
  #     "Smtp can't be blank", "Url can't be blank"]
end

# Campaign with invalid group structure
campaign = Gophish::Campaign.new(
  name: "Test Campaign",
  template: { name: "Template" },
  page: { name: "Page" },
  groups: [{}],  # Invalid: group missing name
  smtp: { name: "SMTP" },
  url: "https://test.com"
)

unless campaign.valid?
  puts campaign.errors.full_messages
  # => ["Groups item at index 0 must have a name"]
end
```

### Template Enhancement - Envelope Sender

Templates now support envelope sender configuration for better email delivery control.

#### Using Envelope Sender

```ruby
# Create a template with envelope sender
template = Gophish::Template.new(
  name: "Corporate Phishing Test",
  envelope_sender: "noreply@company.com",  # Envelope sender address
  subject: "IT Security Update Required",
  html: "<h1>Please update your credentials</h1><p>Click <a href='{{.URL}}'>here</a></p>"
)

if template.save
  puts "Template created with envelope sender"
  puts "Has envelope sender: #{template.has_envelope_sender?}"
  puts "Envelope sender: #{template.envelope_sender}"
end
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
- `envelope_sender` (String) - Envelope sender email address
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
- `#has_envelope_sender?` - Check if template has an envelope sender configured

**Validations:**

- Template must have a name
- Template must have either text or HTML content (or both)
- All attachments must have content, type, and name

#### `Gophish::Page`

Represents a Gophish landing page for phishing campaigns.

**Attributes:**

- `id` (Integer) - Unique page identifier
- `name` (String) - Page name (required)
- `html` (String) - HTML content of the page (required)
- `capture_credentials` (Boolean) - Whether to capture credentials (default: false)
- `capture_passwords` (Boolean) - Whether to capture passwords (default: false)
- `redirect_url` (String) - URL to redirect users after form submission
- `modified_date` (String) - Last modification timestamp

**Class Methods:**

- `.import_site(url, include_resources: false)` - Import a website as a landing page template

**Instance Methods:**

- `#captures_credentials?` - Check if page is configured to capture credentials
- `#captures_passwords?` - Check if page is configured to capture passwords
- `#has_redirect?` - Check if page has a redirect URL configured

**Validations:**

- Page must have a name
- Page must have HTML content

#### `Gophish::Smtp`

Represents a Gophish SMTP sending profile for email campaigns.

**Attributes:**

- `id` (Integer) - Unique SMTP profile identifier
- `name` (String) - SMTP profile name (required)
- `username` (String) - SMTP authentication username
- `password` (String) - SMTP authentication password
- `host` (String) - SMTP server hostname (required)
- `interface_type` (String) - Interface type (default: "SMTP")
- `from_address` (String) - From email address (required, must be valid email format)
- `ignore_cert_errors` (Boolean) - Whether to ignore SSL certificate errors (default: false)
- `modified_date` (String) - Last modification timestamp
- `headers` (Array) - Array of custom header hashes

**Header Structure:**
Each header in the `headers` array should have:

- `key` (String) - Header name (required)
- `value` (String) - Header value (required)

**Instance Methods:**

- `#add_header(key, value)` - Add a custom header to the SMTP profile
- `#remove_header(key)` - Remove a header by key name
- `#has_headers?` - Check if SMTP profile has any custom headers
- `#header_count` - Get the number of custom headers
- `#has_authentication?` - Check if SMTP profile uses authentication (username/password)
- `#ignores_cert_errors?` - Check if SMTP profile ignores SSL certificate errors

**Validations:**

- SMTP profile must have a name
- SMTP profile must have a host
- SMTP profile must have a from_address in valid email format
- All headers must have both key and value

#### `Gophish::Campaign`

Represents a Gophish phishing campaign that orchestrates email sending to target groups.

**Attributes:**

- `id` (Integer) - Unique campaign identifier
- `name` (String) - Campaign name (required)
- `created_date` (String) - Campaign creation timestamp
- `launch_date` (String) - When the campaign should start sending emails
- `send_by_date` (String) - Deadline for sending all campaign emails
- `completed_date` (String) - When the campaign was completed
- `template` - Reference to email template (required, can be hash or Template instance)
- `page` - Reference to landing page (required, can be hash or Page instance)
- `status` (String) - Current campaign status (e.g., "In progress", "Completed")
- `results` (Array) - Array of Result instances showing target interactions
- `groups` (Array) - Array of target groups (required, can be hashes or Group instances)
- `timeline` (Array) - Array of Event instances showing campaign timeline
- `smtp` - Reference to SMTP profile (required, can be hash or Smtp instance)
- `url` (String) - Base URL for the campaign (required)

**Class Methods:**

- `.get_results(id)` - Get campaign results by campaign ID
- `.get_summary(id)` - Get campaign summary statistics by ID
- `.complete(id)` - Complete a campaign by ID

**Instance Methods:**

- `#get_results` - Get detailed campaign results
- `#get_summary` - Get campaign summary statistics
- `#complete!` - Complete the campaign and update status
- `#in_progress?` - Check if campaign is currently running
- `#completed?` - Check if campaign has been completed
- `#launched?` - Check if campaign has a launch date set
- `#has_send_by_date?` - Check if campaign has a send-by deadline

**Validations:**

- Campaign must have a name
- Campaign must reference a template
- Campaign must reference a page
- Campaign must have at least one group
- Campaign must reference an SMTP profile
- Campaign must have a URL
- All groups must have names
- All results must have email addresses
- All timeline events must have time and message

**Nested Classes:**

##### `Gophish::Campaign::Result`

Represents individual target results within a campaign.

**Attributes:**

- `id` (String) - Result identifier
- `first_name` (String) - Target's first name
- `last_name` (String) - Target's last name
- `position` (String) - Target's position
- `email` (String) - Target's email address
- `status` (String) - Current result status
- `ip` (String) - IP address of target interactions
- `latitude` (Float) - Geographic latitude
- `longitude` (Float) - Geographic longitude
- `send_date` (String) - When email was sent
- `reported` (Boolean) - Whether target reported the email
- `modified_date` (String) - Last modification timestamp

**Instance Methods:**

- `#reported?` - Check if target reported the phishing email
- `#clicked?` - Check if target clicked the phishing link
- `#opened?` - Check if target opened the email
- `#sent?` - Check if email was sent to target
- `#submitted_data?` - Check if target submitted data on landing page

##### `Gophish::Campaign::Event`

Represents timeline events within a campaign.

**Attributes:**

- `email` (String) - Target email associated with event
- `time` (String) - Event timestamp
- `message` (String) - Event description
- `details` (String) - Additional event details (JSON string)

**Instance Methods:**

- `#has_details?` - Check if event has additional details
- `#parsed_details` - Parse details JSON into hash

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
