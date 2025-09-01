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
  envelope_sender: "noreply@company.com",  # Separate envelope sender for delivery
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

### 5. Create Your First SMTP Profile

SMTP profiles define how emails are sent in your campaigns:

```ruby
# Create a basic SMTP profile
smtp = Gophish::Smtp.new(
  name: "Company Mail Server",
  host: "smtp.company.com",
  from_address: "security@company.com"
)

if smtp.save
  puts "✓ SMTP profile created successfully with ID: #{smtp.id}"
else
  puts "✗ Failed to create SMTP profile:"
  smtp.errors.full_messages.each { |error| puts "  - #{error}" }
end
```

### 6. Create Your First Landing Page

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

### 7. Create Your First Campaign

Now that you have all the components, you can create a complete phishing campaign:

```ruby
# Create a campaign using the components you've created
campaign = Gophish::Campaign.new(
  name: "Security Awareness Test Campaign",
  template: { name: "Security Awareness Test" },      # Reference the template by name
  page: { name: "Microsoft Login Page" },             # Reference the landing page by name
  groups: [{ name: "My First Group" }],               # Reference the group by name
  smtp: { name: "Company Mail Server" },              # Reference the SMTP profile by name
  url: "https://your-phishing-domain.com"             # Your campaign tracking URL
)

if campaign.save
  puts "✓ Campaign created successfully with ID: #{campaign.id}"
  puts "  Status: #{campaign.status}"
  puts "  Campaign URL: #{campaign.url}"
else
  puts "✗ Failed to create campaign:"
  campaign.errors.full_messages.each { |error| puts "  - #{error}" }
end
```

### 8. Monitor Your Campaign

Once your campaign is created, you can monitor its progress:

```ruby
# Find your campaign
campaign = Gophish::Campaign.find(1)  # Replace with your campaign ID

puts "Campaign: #{campaign.name}"
puts "Status: #{campaign.status}"
puts "In progress? #{campaign.in_progress?}"
puts "Completed? #{campaign.completed?}"

# Get campaign results
if campaign.results.any?
  puts "\nResults Summary:"
  puts "  Total targets: #{campaign.results.length}"
  
  # Count interactions
  clicked_count = campaign.results.count(&:clicked?)
  opened_count = campaign.results.count(&:opened?)
  reported_count = campaign.results.count(&:reported?)
  
  puts "  Emails opened: #{opened_count}"
  puts "  Links clicked: #{clicked_count}"
  puts "  Phishing reported: #{reported_count}"
  puts "  Click rate: #{(clicked_count.to_f / campaign.results.length * 100).round(1)}%"
else
  puts "\nNo results yet - campaign may still be starting"
end
```

### Working with SMTP Profiles

#### Creating SMTP Profiles with Authentication

```ruby
# SMTP profile with username/password authentication
smtp_auth = Gophish::Smtp.new(
  name: "Gmail SMTP",
  host: "smtp.gmail.com",
  from_address: "phishing@company.com",
  username: "smtp_user@company.com",
  password: "app_specific_password",
  ignore_cert_errors: false
)

puts "Uses authentication: #{smtp_auth.has_authentication?}"
smtp_auth.save
```

#### Adding Custom Headers to SMTP Profiles

```ruby
# SMTP profile with custom headers for better deliverability
smtp = Gophish::Smtp.new(
  name: "Custom Headers SMTP",
  host: "mail.company.com",
  from_address: "security@company.com"
)

# Add headers for email routing and identification
smtp.add_header("X-Mailer", "Company Security Training")
smtp.add_header("X-Campaign-Type", "Phishing Simulation")
smtp.add_header("Return-Path", "bounces@company.com")

puts "Header count: #{smtp.header_count}"
smtp.save
```

#### Managing Existing SMTP Profiles

```ruby
# List all SMTP profiles
puts "Existing SMTP profiles:"
Gophish::Smtp.all.each do |smtp|
  auth_info = smtp.has_authentication? ? " [Auth]" : ""
  header_info = smtp.has_headers? ? " (#{smtp.header_count} headers)" : ""
  puts "  #{smtp.id}: #{smtp.name} (#{smtp.host})#{auth_info}#{header_info}"
end

# Update an SMTP profile
smtp = Gophish::Smtp.find(1)
smtp.name = "Updated Mail Server"
smtp.ignore_cert_errors = true  # For testing environments

# Add new header
smtp.add_header("X-Priority", "High")

# Remove old header
smtp.remove_header("X-Campaign-Type")

if smtp.save
  puts "✓ SMTP profile updated"
  puts "  Headers: #{smtp.header_count}"
end
```

## Common Workflows

### Complete Campaign Workflow

Here's a complete workflow showing how to create all components and run a campaign:

```ruby
# Step 1: Create target group
group = Gophish::Group.new(name: "Security Training Q1")
csv_data = <<~CSV
  First Name,Last Name,Email,Position
  Alice,Johnson,alice@company.com,Developer
  Bob,Smith,bob@company.com,Manager
  Carol,Wilson,carol@company.com,Analyst
CSV
group.import_csv(csv_data)
group.save

# Step 2: Create email template with envelope sender
template = Gophish::Template.new(
  name: "IT Security Update",
  envelope_sender: "noreply@company.com",
  subject: "Mandatory Security Update - Action Required",
  html: <<~HTML
    <html>
    <body style="font-family: Arial, sans-serif;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #d32f2f;">🔒 Security Alert</h2>
        <p>Dear {{.FirstName}},</p>
        <p>Our IT security team has detected unusual activity that requires immediate attention.</p>
        <div style="background: #f5f5f5; padding: 15px; margin: 20px 0; border-left: 4px solid #d32f2f;">
          <strong>Action Required:</strong> Please verify your account credentials immediately.
        </div>
        <p style="text-align: center;">
          <a href="{{.URL}}" style="background: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">
            Verify Account Now
          </a>
        </p>
        <p><small>This is a security training exercise. Report suspicious emails to IT.</small></p>
      </div>
    </body>
    </html>
  HTML
)
template.save

# Step 3: Create landing page
page = Gophish::Page.new(
  name: "Corporate Login Portal",
  html: <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Secure Login - Company Portal</title>
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 40px 0; min-height: 100vh; }
        .container { max-width: 400px; margin: 0 auto; background: white; border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); overflow: hidden; }
        .header { background: #1976d2; color: white; padding: 30px; text-align: center; }
        .form { padding: 30px; }
        .input-group { margin-bottom: 20px; }
        input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #1976d2; color: white; border: none; border-radius: 5px; font-size: 16px; cursor: pointer; }
        button:hover { background: #1565c0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>🏢 Company Portal</h2>
          <p>Secure Employee Login</p>
        </div>
        <div class="form">
          <form method="post">
            <div class="input-group">
              <input type="email" name="username" placeholder="Email Address" required>
            </div>
            <div class="input-group">
              <input type="password" name="password" placeholder="Password" required>
            </div>
            <button type="submit">Sign In</button>
          </form>
        </div>
        <div class="footer">
          Protected by advanced security protocols
        </div>
      </div>
    </body>
    </html>
  HTML,
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://company.com/portal"
)
page.save

# Step 4: Create SMTP profile
smtp = Gophish::Smtp.new(
  name: "Training SMTP Server",
  host: "smtp.company.com",
  from_address: "security@company.com"
)
smtp.add_header("X-Mailer", "Company Security Training")
smtp.add_header("X-Training-Campaign", "Q1-2024")
smtp.save

# Step 5: Create and launch campaign
campaign = Gophish::Campaign.new(
  name: "Q1 2024 Security Awareness Training",
  template: template,
  page: page,
  groups: [group],
  smtp: smtp,
  url: "https://training-portal.company.com"
)

if campaign.save
  puts "🚀 Campaign launched successfully!"
  puts "   Campaign ID: #{campaign.id}"
  puts "   Template: #{campaign.template.name}"
  puts "   Landing Page: #{campaign.page.name}"
  puts "   Target Groups: #{campaign.groups.map(&:name).join(', ')}"
  puts "   SMTP Profile: #{campaign.smtp.name}"
  puts "   Total Targets: #{group.targets.length}"
end
```

### Campaign Management and Monitoring

```ruby
# Monitor campaign progress
campaign = Gophish::Campaign.find(1)

# Check status
puts "Campaign Status: #{campaign.status}"
puts "In Progress? #{campaign.in_progress?}"

# Analyze results in detail
if campaign.results.any?
  puts "\n📊 Detailed Campaign Results:"
  
  # Group results by status
  status_counts = Hash.new(0)
  campaign.results.each { |result| status_counts[result.status] += 1 }
  
  status_counts.each do |status, count|
    percentage = (count.to_f / campaign.results.length * 100).round(1)
    puts "   #{status}: #{count} (#{percentage}%)"
  end
  
  # Show individual results
  puts "\n👤 Individual Results:"
  campaign.results.each do |result|
    status_icon = result.clicked? ? "🔗" : result.opened? ? "📧" : result.reported? ? "🚨" : "📬"
    puts "   #{status_icon} #{result.email} - #{result.status}"
  end
  
  # Timeline analysis
  if campaign.timeline.any?
    puts "\n📅 Recent Timeline Events:"
    campaign.timeline.last(5).each do |event|
      puts "   #{event.time}: #{event.message}"
    end
  end
end

# Complete campaign if needed
if campaign.in_progress?
  puts "\n⏹️  Completing campaign..."
  result = campaign.complete!
  puts result['success'] ? "✅ Campaign completed" : "❌ Failed to complete"
end
```

### Advanced Campaign Scheduling

```ruby
# Create a scheduled campaign with specific timing
future_campaign = Gophish::Campaign.new(
  name: "Scheduled Phishing Test - Monday Morning",
  template: { name: "IT Security Update" },
  page: { name: "Corporate Login Portal" },
  groups: [{ name: "Security Training Q1" }],
  smtp: { name: "Training SMTP Server" },
  url: "https://training-portal.company.com",
  launch_date: (Date.today + 7).beginning_of_day.iso8601,  # Next Monday at midnight
  send_by_date: (Date.today + 7).noon.iso8601             # Complete by noon
)

if future_campaign.save
  puts "📅 Scheduled campaign created for #{future_campaign.launch_date}"
  puts "   Will complete by: #{future_campaign.send_by_date}"
  puts "   Launched? #{future_campaign.launched?}"
  puts "   Has deadline? #{future_campaign.has_send_by_date?}"
end
```

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

#### Creating Templates with Envelope Sender

```ruby
# Create template with envelope sender for better email delivery control
template = Gophish::Template.new(
  name: "Corporate Update Template", 
  envelope_sender: "noreply@company.com",    # Envelope sender (bounce address)
  subject: "Important Corporate Update",
  html: <<~HTML
    <div style="font-family: Arial, sans-serif;">
      <h2>IT Security Department</h2>
      <p>Dear {{.FirstName}} {{.LastName}},</p>
      <p>We need to update your security credentials immediately.</p>
      <p><a href="{{.URL}}" style="background: #0066cc; color: white; padding: 10px 20px; text-decoration: none;">Update Now</a></p>
      <p>Best regards,<br>IT Security Team</p>
    </div>
  HTML
)

puts "Has envelope sender: #{template.has_envelope_sender?}"
template.save
```

#### Creating Templates with Attachments

```ruby
# Create template with file attachments
template = Gophish::Template.new(
  name: "Invoice Template",
  envelope_sender: "billing@company.com",
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
