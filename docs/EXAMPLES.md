# Examples

This document contains practical examples for common use cases with the Gophish Ruby SDK.

## Table of Contents

- [Basic Operations](#basic-operations)
- [CSV Operations](#csv-operations)
- [Template Operations](#template-operations)
- [Page Operations](#page-operations)
- [SMTP Operations](#smtp-operations)
- [Campaign Operations](#campaign-operations)
- [Error Handling](#error-handling)
- [Advanced Scenarios](#advanced-scenarios)
- [Production Examples](#production-examples)

## Basic Operations

### Configuration Setup

```ruby
require 'gophish-ruby'

# Standard configuration
Gophish.configure do |config|
  config.url = "https://gophish.company.com"
  config.api_key = "your-api-key"
  config.verify_ssl = true
  config.debug_output = false
end

# Development configuration with debugging
Gophish.configure do |config|
  config.url = "https://localhost:3333"
  config.api_key = "dev-api-key"
  config.verify_ssl = false
  config.debug_output = true
end
```

### Creating Groups

```ruby
# Simple group creation
group = Gophish::Group.new(
  name: "Engineering Team",
  targets: [
    {
      first_name: "Alice",
      last_name: "Developer",
      email: "alice@company.com",
      position: "Senior Developer"
    },
    {
      first_name: "Bob",
      last_name: "Engineer",
      email: "bob@company.com",
      position: "Software Engineer"
    }
  ]
)

puts group.save ? "✓ Group created" : "✗ Failed: #{group.errors.full_messages}"
```

### Retrieving Groups

```ruby
# Get all groups
all_groups = Gophish::Group.all
puts "Total groups: #{all_groups.length}"

all_groups.each do |group|
  puts "#{group.id}: #{group.name} (#{group.targets.length} targets)"
end

# Find specific group
begin
  group = Gophish::Group.find(1)
  puts "Found: #{group.name}"
rescue StandardError => e
  puts "Group not found: #{e.message}"
end
```

### Updating Groups

```ruby
# Load and update existing group
group = Gophish::Group.find(1)
original_name = group.name

group.name = "Updated Engineering Team"
group.targets << {
  first_name: "Charlie",
  last_name: "New",
  email: "charlie@company.com",
  position: "Junior Developer"
}

if group.save
  puts "✓ Updated group from '#{original_name}' to '#{group.name}'"
  puts "  Now has #{group.targets.length} targets"
else
  puts "✗ Update failed: #{group.errors.full_messages}"
end
```

### Deleting Groups

```ruby
# Safe deletion with confirmation
group = Gophish::Group.find(1)
puts "About to delete group: #{group.name} (#{group.targets.length} targets)"

if group.destroy
  puts "✓ Group deleted successfully"
else
  puts "✗ Failed to delete group"
end
```

## CSV Operations

### Basic CSV Import

```ruby
# CSV data with proper headers
csv_data = <<~CSV
  First Name,Last Name,Email,Position
  John,Smith,john.smith@company.com,Manager
  Sarah,Johnson,sarah.johnson@company.com,Developer
  Mike,Brown,mike.brown@company.com,Analyst
  Lisa,Wilson,lisa.wilson@company.com,Designer
CSV

group = Gophish::Group.new(name: "Marketing Department")
group.import_csv(csv_data)

puts "Imported #{group.targets.length} targets"
puts "First target: #{group.targets.first[:first_name]} #{group.targets.first[:last_name]}"

group.save
```

### Reading CSV from File

```ruby
# Read from external CSV file
def import_from_file(file_path, group_name)
  unless File.exist?(file_path)
    puts "Error: File not found - #{file_path}"
    return nil
  end

  csv_content = File.read(file_path)

  group = Gophish::Group.new(name: group_name)
  group.import_csv(csv_content)

  if group.valid?
    if group.save
      puts "✓ Imported #{group.targets.length} targets from #{file_path}"
      return group
    else
      puts "✗ Save failed: #{group.errors.full_messages}"
    end
  else
    puts "✗ Validation failed: #{group.errors.full_messages}"
  end

  nil
end

# Usage
group = import_from_file("employees.csv", "All Employees")
```

### CSV with Different Encodings

```ruby
# Handle different file encodings
def import_csv_with_encoding(file_path, group_name, encoding = 'UTF-8')
  begin
    csv_content = File.read(file_path, encoding: encoding)

    # Convert to UTF-8 if needed
    csv_content = csv_content.encode('UTF-8') unless encoding == 'UTF-8'

    group = Gophish::Group.new(name: group_name)
    group.import_csv(csv_content)
    group.save

    puts "✓ Imported #{group.targets.length} targets with #{encoding} encoding"
  rescue Encoding::UndefinedConversionError => e
    puts "✗ Encoding error: #{e.message}"
    puts "Try a different encoding (e.g., 'ISO-8859-1', 'Windows-1252')"
  end
end

# Usage for different encodings
import_csv_with_encoding("employees_utf8.csv", "UTF-8 Group", 'UTF-8')
import_csv_with_encoding("employees_latin1.csv", "Latin-1 Group", 'ISO-8859-1')
```

### Large CSV Processing

```ruby
require 'csv'

# Process large CSV files in chunks
def import_large_csv(file_path, group_name, chunk_size = 1000)
  puts "Processing large CSV file: #{file_path}"

  all_targets = []
  row_count = 0

  CSV.foreach(file_path, headers: true) do |row|
    target = {
      first_name: row['First Name'],
      last_name: row['Last Name'],
      email: row['Email'],
      position: row['Position']
    }

    all_targets << target
    row_count += 1

    # Process in chunks
    if all_targets.length >= chunk_size
      puts "  Processed #{row_count} rows..."
      # Could save intermediate groups here if needed
    end
  end

  puts "✓ Read #{row_count} rows total"

  # Create single group with all targets
  group = Gophish::Group.new(name: group_name, targets: all_targets)

  if group.valid?
    if group.save
      puts "✓ Successfully imported #{group.targets.length} targets"
      return group
    else
      puts "✗ Save failed: #{group.errors.full_messages}"
    end
  else
    puts "✗ Validation failed: #{group.errors.full_messages}"
  end

  nil
end

# Usage
group = import_large_csv("large_employee_list.csv", "All Company Employees")
```

## Template Operations

### Basic Template Creation

```ruby
# Simple text and HTML template
template = Gophish::Template.new(
  name: "Security Awareness Training",
  subject: "Important Security Update - Action Required",
  html: <<~HTML,
    <h1>Security Update Required</h1>
    <p>Dear {{.FirstName}},</p>
    <p>We have detected suspicious activity on your account. Please click <a href="{{.URL}}">here</a> to verify your account immediately.</p>
    <p>This link will expire in 24 hours.</p>
    <p>Best regards,<br>IT Security Team</p>
  HTML
  text: <<~TEXT
    Security Update Required

    Dear {{.FirstName}},

    We have detected suspicious activity on your account. Please visit {{.URL}} to verify your account immediately.

    This link will expire in 24 hours.

    Best regards,
    IT Security Team
  TEXT
)

if template.save
  puts "✓ Template '#{template.name}' created with ID: #{template.id}"
else
  puts "✗ Failed to create template: #{template.errors.full_messages}"
end
```

### Template with Attachments

```ruby
# Create template with multiple attachments
template = Gophish::Template.new(
  name: "Invoice Phishing Template",
  subject: "Invoice #{{.RId}} - Payment Due",
  html: "<h1>Invoice Attached</h1><p>Dear {{.FirstName}},</p><p>Please find your invoice attached for immediate payment.</p>"
)

# Add PDF invoice attachment
pdf_content = File.read("sample_invoice.pdf")
template.add_attachment(pdf_content, "application/pdf", "invoice_#{Time.now.strftime('%Y%m%d')}.pdf")

# Add company logo
logo_content = File.read("company_logo.png")
template.add_attachment(logo_content, "image/png", "logo.png")

# Add fake Excel spreadsheet
excel_content = File.read("expense_report.xlsx")
template.add_attachment(excel_content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Q4_expenses.xlsx")

puts "Template has #{template.attachment_count} attachments"

if template.save
  puts "✓ Template with attachments created successfully"
end
```

### Email Import from .EML Files

```ruby
# Import existing phishing email
def import_phishing_template(eml_file_path, template_name)
  unless File.exist?(eml_file_path)
    puts "✗ EML file not found: #{eml_file_path}"
    return nil
  end

  email_content = File.read(eml_file_path)

  # Import with link conversion for tracking
  begin
    imported_data = Gophish::Template.import_email(email_content, convert_links: true)
  rescue StandardError => e
    puts "✗ Email import failed: #{e.message}"
    return nil
  end

  # Create template from imported data
  template = Gophish::Template.new(imported_data)
  template.name = template_name

  if template.valid?
    if template.save
      puts "✓ Successfully imported template '#{template.name}'"
      puts "  Subject: #{template.subject}"
      puts "  Has HTML: #{!template.html.nil?}"
      puts "  Has Text: #{!template.text.nil?}"
      puts "  Attachments: #{template.attachment_count}"
      return template
    else
      puts "✗ Save failed: #{template.errors.full_messages}"
    end
  else
    puts "✗ Validation failed: #{template.errors.full_messages}"
  end

  nil
end

# Usage
template = import_phishing_template("phishing_email.eml", "Imported Phishing Template")
```

### Template Management Operations

```ruby
# List all existing templates
def list_templates
  templates = Gophish::Template.all
  puts "Found #{templates.length} templates:"

  templates.each do |template|
    attachment_info = template.has_attachments? ? " (#{template.attachment_count} attachments)" : ""
    puts "  #{template.id}: #{template.name}#{attachment_info}"
    puts "    Subject: #{template.subject}" if template.subject
    puts "    Modified: #{template.modified_date}" if template.modified_date
  end
end

# Update existing template
def update_template(template_id, new_subject = nil, new_html = nil)
  begin
    template = Gophish::Template.find(template_id)
  rescue StandardError
    puts "✗ Template #{template_id} not found"
    return false
  end

  puts "Updating template '#{template.name}'"

  template.subject = new_subject if new_subject
  template.html = new_html if new_html

  if template.save
    puts "✓ Template updated successfully"
    true
  else
    puts "✗ Update failed: #{template.errors.full_messages}"
    false
  end
end

# Clone template with modifications
def clone_template(original_id, new_name, modifications = {})
  begin
    original = Gophish::Template.find(original_id)
  rescue StandardError
    puts "✗ Original template #{original_id} not found"
    return nil
  end

  # Create new template with same content
  new_template = Gophish::Template.new(
    name: new_name,
    subject: original.subject,
    html: original.html,
    text: original.text
  )

  # Apply modifications
  modifications.each do |field, value|
    new_template.send("#{field}=", value) if new_template.respond_to?("#{field}=")
  end

  # Copy attachments
  if original.has_attachments?
    original.attachments.each do |attachment|
      new_template.attachments << attachment.dup
    end
  end

  if new_template.save
    puts "✓ Template cloned as '#{new_name}' (ID: #{new_template.id})"
    new_template
  else
    puts "✗ Clone failed: #{new_template.errors.full_messages}"
    nil
  end
end

# Usage examples
list_templates
update_template(1, "Updated Subject Line", "<h1>Updated HTML content</h1>")
clone_template(1, "Modified Version", { subject: "Modified Subject" })
```

### Template Validation and Error Handling

```ruby
# Comprehensive template validation
def validate_template_thoroughly(template)
  puts "Validating template '#{template.name}'"

  # Basic validation
  unless template.valid?
    puts "✗ Basic validation failed:"
    template.errors.full_messages.each { |error| puts "    - #{error}" }
    return false
  end

  # Content validation
  has_html = !template.html.nil? && !template.html.strip.empty?
  has_text = !template.text.nil? && !template.text.strip.empty?

  unless has_html || has_text
    puts "✗ Template has no content (neither HTML nor text)"
    return false
  end

  # Gophish template variable validation
  content = "#{template.html} #{template.text} #{template.subject}"
  
  # Check for common Gophish template variables
  variables_found = content.scan(/\{\{\.(\w+)\}\}/).flatten.uniq
  puts "  Found template variables: #{variables_found.join(', ')}" if variables_found.any?

  # Warn about missing tracking URL
  unless content.include?('{{.URL}}')
    puts "  ⚠ Warning: No {{.URL}} tracking variable found"
  end

  # Attachment validation
  if template.has_attachments?
    puts "  Validating #{template.attachment_count} attachments:"
    template.attachments.each_with_index do |attachment, index|
      name = attachment[:name] || attachment['name']
      type = attachment[:type] || attachment['type']
      content = attachment[:content] || attachment['content']

      puts "    #{index + 1}. #{name} (#{type})"

      if content.nil? || content.empty?
        puts "      ✗ Missing content"
        return false
      end

      # Validate Base64 encoding
      begin
        Base64.strict_decode64(content)
        puts "      ✓ Valid Base64 encoding"
      rescue ArgumentError
        puts "      ✗ Invalid Base64 encoding"
        return false
      end
    end
  end

  puts "✓ Template validation passed"
  true
end

# Test various template scenarios
def test_template_scenarios
  # Valid template
  valid_template = Gophish::Template.new(
    name: "Valid Template",
    subject: "Test {{.FirstName}}",
    html: "<p>Click {{.URL}} to continue</p>",
    text: "Visit {{.URL}} to continue"
  )
  validate_template_thoroughly(valid_template)

  # Invalid template (no content)
  invalid_template = Gophish::Template.new(
    name: "Invalid Template",
    subject: "Test"
  )
  validate_template_thoroughly(invalid_template)

  # Template with attachment
  template_with_attachment = Gophish::Template.new(
    name: "Attachment Template",
    html: "<p>See attachment</p>"
  )
  template_with_attachment.add_attachment("Hello World", "text/plain", "test.txt")
  validate_template_thoroughly(template_with_attachment)
end

test_template_scenarios
```

### Bulk Template Operations

```ruby
# Create multiple templates from a configuration
def create_template_suite(campaign_name)
  templates = [
    {
      name: "#{campaign_name} - Initial Email",
      subject: "Important Account Update Required",
      html: "<h1>Account Update</h1><p>Dear {{.FirstName}}, please update your account by clicking <a href='{{.URL}}'>here</a>.</p>",
      text: "Dear {{.FirstName}}, please update your account by visiting {{.URL}}"
    },
    {
      name: "#{campaign_name} - Follow-up",
      subject: "URGENT: Account Suspension Notice",
      html: "<h1 style='color: red;'>URGENT</h1><p>Your account will be suspended in 24 hours. Verify immediately: {{.URL}}</p>",
      text: "URGENT: Your account will be suspended in 24 hours. Verify at {{.URL}}"
    },
    {
      name: "#{campaign_name} - Final Warning",
      subject: "Final Warning - Account Closure",
      html: "<h1>Final Warning</h1><p>This is your last chance to save your account: {{.URL}}</p>",
      text: "Final Warning: Last chance to save your account at {{.URL}}"
    }
  ]

  created_templates = []

  templates.each_with_index do |template_data, index|
    puts "Creating template #{index + 1}/#{templates.length}: #{template_data[:name]}"

    template = Gophish::Template.new(template_data)

    if template.save
      puts "  ✓ Created with ID: #{template.id}"
      created_templates << template
    else
      puts "  ✗ Failed: #{template.errors.full_messages}"
    end
  end

  puts "\nTemplate suite '#{campaign_name}' creation completed"
  puts "Successfully created: #{created_templates.length}/#{templates.length} templates"

  created_templates
end

# Usage
suite = create_template_suite("Q4 Security Training")
```

## Page Operations

### Basic Landing Page Creation

```ruby
# Simple landing page without credential capture
simple_page = Gophish::Page.new(
  name: "Generic Thank You Page",
  html: <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Thank You</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          text-align: center; 
          background: #f0f0f0; 
          padding: 50px; 
        }
        .container { 
          max-width: 500px; 
          margin: 0 auto; 
          background: white; 
          padding: 40px; 
          border-radius: 10px; 
          box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Thank You!</h1>
        <p>Your request has been processed successfully.</p>
        <p>You will receive a confirmation email shortly.</p>
      </div>
    </body>
    </html>
  HTML
)

if simple_page.save
  puts "✓ Simple page created: #{simple_page.id}"
end
```

### Landing Page with Credential Capture

```ruby
# Microsoft-style login page with credential capture
microsoft_page = Gophish::Page.new(
  name: "Microsoft Office 365 Login Clone",
  html: <<~HTML,
    <!DOCTYPE html>
    <html>
    <head>
      <title>Microsoft Office</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
          background: #f5f5f5; 
          display: flex; 
          justify-content: center; 
          align-items: center; 
          min-height: 100vh; 
        }
        .login-container {
          background: white;
          padding: 40px;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          max-width: 400px;
          width: 100%;
        }
        .logo {
          text-align: center;
          margin-bottom: 30px;
          color: #737373;
          font-size: 24px;
          font-weight: 300;
        }
        h1 {
          color: #1B1B1B;
          font-size: 24px;
          font-weight: 600;
          margin-bottom: 20px;
        }
        .form-group {
          margin-bottom: 20px;
        }
        input[type="email"], input[type="password"] {
          width: 100%;
          padding: 12px;
          border: 1px solid #CCCCCC;
          border-radius: 4px;
          font-size: 14px;
          transition: border-color 0.3s;
        }
        input[type="email"]:focus, input[type="password"]:focus {
          outline: none;
          border-color: #0078D4;
        }
        .signin-button {
          width: 100%;
          padding: 12px;
          background: #0078D4;
          color: white;
          border: none;
          border-radius: 4px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: background-color 0.3s;
        }
        .signin-button:hover {
          background: #106EBE;
        }
        .footer-links {
          text-align: center;
          margin-top: 20px;
          font-size: 12px;
        }
        .footer-links a {
          color: #0078D4;
          text-decoration: none;
          margin: 0 10px;
        }
      </style>
    </head>
    <body>
      <div class="login-container">
        <div class="logo">Microsoft</div>
        <h1>Sign in</h1>
        <form method="post" action="">
          <div class="form-group">
            <input type="email" name="username" placeholder="Email, phone, or Skype" required>
          </div>
          <div class="form-group">
            <input type="password" name="password" placeholder="Password" required>
          </div>
          <button type="submit" class="signin-button">Sign in</button>
        </form>
        <div class="footer-links">
          <a href="#">Can't access your account?</a>
          <a href="#">Sign-in options</a>
        </div>
      </div>
    </body>
    </html>
  HTML
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://office.com"
)

if microsoft_page.save
  puts "✓ Microsoft login page created: #{microsoft_page.id}"
  puts "  Captures credentials: #{microsoft_page.captures_credentials?}"
  puts "  Captures passwords: #{microsoft_page.captures_passwords?}"
  puts "  Redirects to: #{microsoft_page.redirect_url}"
end
```

### Banking Login Page with Enhanced Security Theater

```ruby
# Realistic banking login page
banking_page = Gophish::Page.new(
  name: "SecureBank Online Banking Portal",
  html: <<~HTML,
    <!DOCTYPE html>
    <html>
    <head>
      <title>SecureBank - Online Banking</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { 
          font-family: Arial, sans-serif; 
          margin: 0; 
          background: linear-gradient(135deg, #003366, #004499); 
          min-height: 100vh; 
        }
        .header {
          background: white;
          padding: 15px 0;
          border-bottom: 3px solid #003366;
          box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .header-content {
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 20px;
          display: flex;
          align-items: center;
        }
        .logo {
          font-size: 24px;
          font-weight: bold;
          color: #003366;
        }
        .security-badge {
          margin-left: auto;
          color: #28a745;
          font-size: 12px;
          display: flex;
          align-items: center;
        }
        .security-badge::before {
          content: "🔒";
          margin-right: 5px;
        }
        .main-content {
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: calc(100vh - 80px);
          padding: 40px 20px;
        }
        .login-form {
          background: white;
          padding: 40px;
          border-radius: 12px;
          box-shadow: 0 10px 30px rgba(0,0,0,0.3);
          max-width: 400px;
          width: 100%;
        }
        .form-title {
          text-align: center;
          color: #003366;
          font-size: 28px;
          margin-bottom: 30px;
          font-weight: bold;
        }
        .security-notice {
          background: #E8F4FD;
          border: 1px solid #B8DAFF;
          padding: 15px;
          border-radius: 6px;
          margin-bottom: 25px;
          font-size: 14px;
          color: #0C5460;
        }
        .form-group {
          margin-bottom: 20px;
        }
        label {
          display: block;
          margin-bottom: 8px;
          font-weight: bold;
          color: #003366;
        }
        input[type="text"], input[type="password"] {
          width: 100%;
          padding: 15px;
          border: 2px solid #CCC;
          border-radius: 6px;
          font-size: 16px;
          transition: border-color 0.3s;
        }
        input[type="text"]:focus, input[type="password"]:focus {
          outline: none;
          border-color: #003366;
        }
        .login-button {
          width: 100%;
          padding: 15px;
          background: #003366;
          color: white;
          border: none;
          border-radius: 6px;
          font-size: 18px;
          font-weight: bold;
          cursor: pointer;
          transition: background-color 0.3s;
        }
        .login-button:hover {
          background: #004499;
        }
        .footer-text {
          text-align: center;
          margin-top: 20px;
          font-size: 12px;
          color: #666;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="header-content">
          <div class="logo">🏛️ SecureBank</div>
          <div class="security-badge">256-bit SSL Encryption</div>
        </div>
      </div>
      
      <div class="main-content">
        <div class="login-form">
          <h1 class="form-title">Secure Login</h1>
          
          <div class="security-notice">
            <strong>🔐 Security Notice:</strong> For your protection, please ensure you are on our secure website before entering your credentials.
          </div>
          
          <form method="post" action="">
            <div class="form-group">
              <label for="username">User ID:</label>
              <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            
            <div class="form-group">
              <label for="password">Password:</label>
              <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            
            <button type="submit" class="login-button">Access My Account</button>
          </form>
          
          <div class="footer-text">
            Your connection is secured with 256-bit encryption<br>
            © 2024 SecureBank. All rights reserved.
          </div>
        </div>
      </div>
    </body>
    </html>
  HTML
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://www.securebank.com/login-success"
)

if banking_page.save
  puts "✓ Banking page created: #{banking_page.id}"
end
```

### Website Import Examples

```ruby
# Import real websites as landing pages
def import_website_examples
  websites_to_import = [
    {
      url: "https://accounts.google.com/signin",
      name: "Google Login Clone",
      include_resources: true
    },
    {
      url: "https://login.microsoftonline.com",
      name: "Microsoft Azure Login Clone", 
      include_resources: false  # Faster import, basic styling only
    },
    {
      url: "https://www.paypal.com/signin",
      name: "PayPal Login Clone",
      include_resources: true
    }
  ]

  websites_to_import.each do |site_config|
    puts "Importing #{site_config[:url]}"
    
    begin
      # Import the website
      imported_data = Gophish::Page.import_site(
        site_config[:url], 
        include_resources: site_config[:include_resources]
      )
      
      # Create page from imported data
      page = Gophish::Page.new(imported_data)
      page.name = site_config[:name]
      page.capture_credentials = true
      
      if page.save
        puts "  ✓ Successfully imported: #{page.name} (ID: #{page.id})"
        puts "    HTML size: #{page.html.length} characters"
        puts "    Captures credentials: #{page.captures_credentials?}"
      else
        puts "  ✗ Failed to save: #{page.errors.full_messages.join(', ')}"
      end
      
    rescue StandardError => e
      puts "  ✗ Import failed: #{e.message}"
      
      # Create fallback manual page
      fallback_page = create_fallback_page(site_config[:name], site_config[:url])
      if fallback_page
        puts "  ✓ Created fallback page: #{fallback_page.id}"
      end
    end
    
    puts
  end
end

def create_fallback_page(name, original_url)
  # Extract domain name for styling
  domain = URI.parse(original_url).host.gsub('www.', '')
  
  fallback_page = Gophish::Page.new(
    name: "#{name} (Manual Fallback)",
    html: <<~HTML,
      <html>
      <head>
        <title>#{domain.capitalize}</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 400px; margin: 100px auto; padding: 40px; }
          .logo { font-size: 24px; margin-bottom: 30px; text-align: center; color: #333; }
          input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
          button { width: 100%; padding: 12px; background: #1a73e8; color: white; border: none; border-radius: 4px; cursor: pointer; }
          button:hover { background: #1557b0; }
        </style>
      </head>
      <body>
        <div class="logo">#{domain.capitalize}</div>
        <form method="post">
          <input type="email" name="username" placeholder="Email" required>
          <input type="password" name="password" placeholder="Password" required>
          <button type="submit">Sign in</button>
        </form>
      </body>
      </html>
    HTML
    capture_credentials: true
  )
  
  fallback_page.save ? fallback_page : nil
end

# Run the import
import_website_examples
```

### Page Management and Updates

```ruby
# Comprehensive page management
class PageManager
  def self.list_all_pages
    pages = Gophish::Page.all
    puts "Found #{pages.length} landing pages:"
    
    pages.each do |page|
      features = []
      features << "🔑 Captures Credentials" if page.captures_credentials?
      features << "🔒 Captures Passwords" if page.captures_passwords?
      features << "🔄 Has Redirect" if page.has_redirect?
      
      feature_text = features.any? ? " [#{features.join(', ')}]" : ""
      puts "  #{page.id}: #{page.name}#{feature_text}"
      
      if page.has_redirect?
        puts "    → Redirects to: #{page.redirect_url}"
      end
      
      puts "    HTML size: #{page.html.length} characters"
      puts
    end
  end

  def self.update_page_security(page_id, enable_credential_capture: false, redirect_to: nil)
    begin
      page = Gophish::Page.find(page_id)
    rescue StandardError
      puts "✗ Page #{page_id} not found"
      return false
    end

    puts "Updating security settings for '#{page.name}'"

    # Update credential capture settings
    if enable_credential_capture
      page.capture_credentials = true
      page.capture_passwords = true
      puts "  ✓ Enabled credential capture"
    else
      page.capture_credentials = false
      page.capture_passwords = false
      puts "  ✓ Disabled credential capture"
    end

    # Update redirect URL
    if redirect_to
      page.redirect_url = redirect_to
      puts "  ✓ Set redirect URL: #{redirect_to}"
    end

    if page.save
      puts "  ✓ Page updated successfully"
      true
    else
      puts "  ✗ Update failed: #{page.errors.full_messages.join(', ')}"
      false
    end
  end

  def self.clone_page(original_id, new_name, modifications = {})
    begin
      original = Gophish::Page.find(original_id)
    rescue StandardError
      puts "✗ Original page #{original_id} not found"
      return nil
    end

    # Create clone
    cloned_page = Gophish::Page.new(
      name: new_name,
      html: original.html,
      capture_credentials: original.capture_credentials,
      capture_passwords: original.capture_passwords,
      redirect_url: original.redirect_url
    )

    # Apply modifications
    modifications.each do |field, value|
      cloned_page.send("#{field}=", value) if cloned_page.respond_to?("#{field}=")
    end

    if cloned_page.save
      puts "✓ Page cloned successfully: '#{new_name}' (ID: #{cloned_page.id})"
      cloned_page
    else
      puts "✗ Clone failed: #{cloned_page.errors.full_messages.join(', ')}"
      nil
    end
  end
end

# Usage examples
PageManager.list_all_pages

# Enable security features on an existing page
PageManager.update_page_security(
  1, 
  enable_credential_capture: true, 
  redirect_to: "https://legitimate-site.com"
)

# Clone a page with modifications
PageManager.clone_page(
  1, 
  "Modified Banking Page", 
  { 
    capture_passwords: false,
    redirect_url: "https://different-redirect.com" 
  }
)
```

### A/B Testing with Multiple Page Variants

```ruby
# Create multiple variants of the same phishing page for testing
def create_page_variants(base_name, base_html, variants)
  created_pages = []
  
  variants.each_with_index do |variant, index|
    variant_name = "#{base_name} - #{variant[:name]}"
    
    # Start with base HTML
    modified_html = base_html.dup
    
    # Apply modifications
    variant[:modifications].each do |search, replace|
      modified_html.gsub!(search, replace)
    end
    
    page = Gophish::Page.new(
      name: variant_name,
      html: modified_html,
      capture_credentials: variant[:capture_credentials] || true,
      capture_passwords: variant[:capture_passwords] || true,
      redirect_url: variant[:redirect_url]
    )
    
    if page.save
      puts "✓ Created variant #{index + 1}: #{variant_name} (ID: #{page.id})"
      created_pages << page
    else
      puts "✗ Failed to create variant #{index + 1}: #{page.errors.full_messages.join(', ')}"
    end
  end
  
  created_pages
end

# Example: Create different urgency levels for the same login page
base_html = <<~HTML
  <html>
  <head><title>Account Security</title></head>
  <body>
    <h1>URGENCY_LEVEL</h1>
    <p>MESSAGE_TEXT</p>
    <form method="post">
      <input type="email" name="username" placeholder="Email" required>
      <input type="password" name="password" placeholder="Password" required>
      <button type="submit" style="background: BUTTON_COLOR;">BUTTON_TEXT</button>
    </form>
  </body>
  </html>
HTML

variants = [
  {
    name: "Low Urgency",
    modifications: {
      "URGENCY_LEVEL" => "Account Update Available",
      "MESSAGE_TEXT" => "Please update your account information at your convenience.",
      "BUTTON_COLOR" => "#0078d4",
      "BUTTON_TEXT" => "Update Account"
    },
    redirect_url: "https://microsoft.com"
  },
  {
    name: "Medium Urgency", 
    modifications: {
      "URGENCY_LEVEL" => "Security Alert",
      "MESSAGE_TEXT" => "We detected unusual activity. Please verify your account.",
      "BUTTON_COLOR" => "#ff8c00",
      "BUTTON_TEXT" => "Verify Now"
    },
    redirect_url: "https://microsoft.com/security"
  },
  {
    name: "High Urgency",
    modifications: {
      "URGENCY_LEVEL" => "IMMEDIATE ACTION REQUIRED",
      "MESSAGE_TEXT" => "Your account will be suspended in 24 hours! Login immediately.",
      "BUTTON_COLOR" => "#dc3545", 
      "BUTTON_TEXT" => "SAVE MY ACCOUNT"
    },
    redirect_url: "https://microsoft.com/urgent"
  }
]

pages = create_page_variants("Microsoft Security Alert", base_html, variants)
puts "\nCreated #{pages.length} page variants for A/B testing"
```

## SMTP Operations

### Basic SMTP Profile Creation

```ruby
# Simple SMTP profile without authentication
basic_smtp = Gophish::Smtp.new(
  name: "Company Mail Server",
  host: "smtp.company.com",
  from_address: "security@company.com"
)

if basic_smtp.save
  puts "✓ Basic SMTP profile created: #{basic_smtp.id}"
  puts "  Host: #{basic_smtp.host}"
  puts "  From: #{basic_smtp.from_address}"
else
  puts "✗ Failed to create SMTP profile: #{basic_smtp.errors.full_messages}"
end
```

### SMTP Profile with Authentication

```ruby
# SMTP with username/password authentication
auth_smtp = Gophish::Smtp.new(
  name: "Gmail SMTP with Authentication",
  host: "smtp.gmail.com",
  from_address: "phishing.test@company.com",
  username: "smtp_service@company.com",
  password: "app_specific_password",
  ignore_cert_errors: false
)

puts "SMTP Configuration:"
puts "  Name: #{auth_smtp.name}"
puts "  Host: #{auth_smtp.host}"
puts "  From: #{auth_smtp.from_address}"
puts "  Uses Authentication: #{auth_smtp.has_authentication?}"
puts "  Ignores SSL Errors: #{auth_smtp.ignores_cert_errors?}"

if auth_smtp.save
  puts "✓ Authenticated SMTP profile created: #{auth_smtp.id}"
end
```

### SMTP Profile with Custom Headers

```ruby
# SMTP profile with multiple custom headers
header_smtp = Gophish::Smtp.new(
  name: "Custom Headers Mail Server",
  host: "mail.company.com", 
  from_address: "security-team@company.com"
)

# Add headers for better deliverability and tracking
header_smtp.add_header("X-Mailer", "Gophish Security Training Platform v2.0")
header_smtp.add_header("X-Department", "Information Security")
header_smtp.add_header("X-Campaign-ID", "Q4-2024-PHISH-001")
header_smtp.add_header("Return-Path", "bounces+security@company.com")
header_smtp.add_header("Reply-To", "security-team@company.com")
header_smtp.add_header("X-Priority", "1")
header_smtp.add_header("X-MSMail-Priority", "High")

puts "SMTP Profile with Headers:"
puts "  Name: #{header_smtp.name}"
puts "  Headers: #{header_smtp.header_count}"
puts "  Has Headers: #{header_smtp.has_headers?}"

header_smtp.headers.each_with_index do |header, index|
  key = header[:key] || header['key']
  value = header[:value] || header['value']
  puts "    #{index + 1}. #{key}: #{value}"
end

if header_smtp.save
  puts "✓ SMTP profile with headers created: #{header_smtp.id}"
end
```

### Production-Ready SMTP Configuration

```ruby
# Comprehensive SMTP setup for production use
def create_production_smtp(name, host, from_address, username = nil, password = nil)
  puts "Creating production SMTP profile: #{name}"
  
  smtp = Gophish::Smtp.new(
    name: name,
    host: host,
    from_address: from_address,
    username: username,
    password: password,
    ignore_cert_errors: false,  # Always verify SSL in production
    interface_type: "SMTP"
  )

  # Add production-grade headers
  smtp.add_header("X-Mailer", "Corporate Security Training System")
  smtp.add_header("X-Environment", "Production")
  smtp.add_header("X-Security-Classification", "Internal")
  smtp.add_header("Return-Path", "bounces+security@#{extract_domain(from_address)}")
  smtp.add_header("List-Unsubscribe", "<mailto:security-opt-out@#{extract_domain(from_address)}>")
  
  # Validate configuration
  unless smtp.valid?
    puts "  ✗ Configuration invalid:"
    smtp.errors.full_messages.each { |error| puts "      - #{error}" }
    return nil
  end

  # Security checks
  puts "  Security Assessment:"
  puts "    SSL Verification: #{smtp.ignore_cert_errors? ? '✗ DISABLED' : '✓ ENABLED'}"
  puts "    Authentication: #{smtp.has_authentication? ? '✓ ENABLED' : '⚠ DISABLED'}"
  puts "    Custom Headers: #{smtp.header_count}"
  puts "    From Domain: #{extract_domain(smtp.from_address)}"

  if smtp.save
    puts "  ✓ Production SMTP profile created (ID: #{smtp.id})"
    return smtp
  else
    puts "  ✗ Failed to save SMTP profile:"
    smtp.errors.full_messages.each { |error| puts "      - #{error}" }
    return nil
  end
end

def extract_domain(email)
  email.split('@').last
end

# Usage examples
prod_smtp = create_production_smtp(
  "Production Mail Server",
  "smtp.company.com", 
  "security-training@company.com",
  "smtp_service_account",
  ENV['SMTP_PASSWORD']  # Use environment variables for passwords
)

gmail_smtp = create_production_smtp(
  "Gmail SMTP for Testing",
  "smtp.gmail.com",
  "test-campaigns@company.com", 
  "test-account@company.com",
  ENV['GMAIL_APP_PASSWORD']
)
```

### SMTP Profile Management Operations

```ruby
# List all SMTP profiles with details
def list_smtp_profiles
  smtp_profiles = Gophish::Smtp.all
  puts "Found #{smtp_profiles.length} SMTP profiles:"
  
  smtp_profiles.each do |smtp|
    features = []
    features << "🔐 Auth" if smtp.has_authentication?
    features << "📧 Headers(#{smtp.header_count})" if smtp.has_headers?
    features << "⚠️ No SSL" if smtp.ignores_cert_errors?
    
    feature_text = features.any? ? " [#{features.join(', ')}]" : ""
    
    puts "  #{smtp.id}: #{smtp.name}#{feature_text}"
    puts "    Host: #{smtp.host}"
    puts "    From: #{smtp.from_address}"
    puts "    Interface: #{smtp.interface_type}"
    puts "    Modified: #{smtp.modified_date}" if smtp.modified_date
    puts
  end
end

# Update existing SMTP profile
def update_smtp_profile(smtp_id, updates = {})
  begin
    smtp = Gophish::Smtp.find(smtp_id)
  rescue StandardError
    puts "✗ SMTP profile #{smtp_id} not found"
    return false
  end

  puts "Updating SMTP profile '#{smtp.name}'"
  original_values = {}

  # Apply updates and track changes
  updates.each do |field, value|
    if smtp.respond_to?("#{field}=")
      original_values[field] = smtp.send(field)
      smtp.send("#{field}=", value)
      puts "  #{field}: '#{original_values[field]}' → '#{value}'"
    else
      puts "  ⚠️ Unknown field: #{field}"
    end
  end

  if smtp.save
    puts "  ✓ SMTP profile updated successfully"
    true
  else
    puts "  ✗ Update failed:"
    smtp.errors.full_messages.each { |error| puts "      - #{error}" }
    false
  end
end

# Clone SMTP profile with modifications
def clone_smtp_profile(original_id, new_name, modifications = {})
  begin
    original = Gophish::Smtp.find(original_id)
  rescue StandardError
    puts "✗ Original SMTP profile #{original_id} not found"
    return nil
  end

  puts "Cloning SMTP profile '#{original.name}' as '#{new_name}'"

  # Create clone with same settings
  cloned_smtp = Gophish::Smtp.new(
    name: new_name,
    host: original.host,
    from_address: original.from_address,
    username: original.username,
    password: original.password,
    interface_type: original.interface_type,
    ignore_cert_errors: original.ignore_cert_errors
  )

  # Copy headers
  if original.has_headers?
    original.headers.each do |header|
      key = header[:key] || header['key']
      value = header[:value] || header['value']
      cloned_smtp.add_header(key, value)
    end
  end

  # Apply modifications
  modifications.each do |field, value|
    case field
    when :headers
      # Clear existing headers and add new ones
      cloned_smtp.headers.clear
      value.each { |key, val| cloned_smtp.add_header(key, val) }
    else
      cloned_smtp.send("#{field}=", value) if cloned_smtp.respond_to?("#{field}=")
    end
  end

  if cloned_smtp.save
    puts "  ✓ SMTP profile cloned successfully (ID: #{cloned_smtp.id})"
    puts "  Features:"
    puts "    Authentication: #{cloned_smtp.has_authentication?}"
    puts "    Headers: #{cloned_smtp.header_count}"
    puts "    SSL Verification: #{cloned_smtp.ignore_cert_errors? ? 'Disabled' : 'Enabled'}"
    return cloned_smtp
  else
    puts "  ✗ Clone failed:"
    cloned_smtp.errors.full_messages.each { |error| puts "      - #{error}" }
    return nil
  end
end

# Usage examples
list_smtp_profiles

# Update an existing profile
update_smtp_profile(1, {
  name: "Updated Company SMTP",
  ignore_cert_errors: true
})

# Clone with modifications
cloned = clone_smtp_profile(1, "Test Environment SMTP", {
  from_address: "test@company.com",
  ignore_cert_errors: true,
  headers: {
    "X-Environment" => "Testing",
    "X-Test-Campaign" => "true"
  }
})
```

### Header Management Examples

```ruby
# Advanced header management
def manage_smtp_headers(smtp_id)
  begin
    smtp = Gophish::Smtp.find(smtp_id)
  rescue StandardError
    puts "✗ SMTP profile #{smtp_id} not found"
    return
  end

  puts "Managing headers for '#{smtp.name}'"
  puts "Current headers: #{smtp.header_count}"

  # Display current headers
  if smtp.has_headers?
    puts "  Current headers:"
    smtp.headers.each_with_index do |header, index|
      key = header[:key] || header['key']
      value = header[:value] || header['value']
      puts "    #{index + 1}. #{key}: #{value}"
    end
  end

  # Add standard deliverability headers
  standard_headers = {
    "X-Mailer" => "Gophish Security Training v4.0",
    "X-Campaign-Type" => "Security Awareness", 
    "X-Department" => "IT Security",
    "Return-Path" => "bounces@#{smtp.from_address.split('@').last}",
    "List-Unsubscribe" => "<mailto:unsubscribe@#{smtp.from_address.split('@').last}>",
    "X-Priority" => "Normal",
    "X-Auto-Response-Suppress" => "All"
  }

  puts "\nAdding standard headers:"
  standard_headers.each do |key, value|
    smtp.add_header(key, value)
    puts "  + #{key}: #{value}"
  end

  # Remove any problematic headers
  problematic_headers = ["X-Spam", "X-Test", "X-Debug"]
  removed_count = 0

  problematic_headers.each do |header_key|
    if smtp.headers.any? { |h| (h[:key] || h['key']) == header_key }
      smtp.remove_header(header_key)
      removed_count += 1
      puts "  - Removed: #{header_key}"
    end
  end

  puts "\nHeader management summary:"
  puts "  Total headers: #{smtp.header_count}"
  puts "  Added: #{standard_headers.length}"
  puts "  Removed: #{removed_count}"

  if smtp.save
    puts "  ✓ Headers updated successfully"
  else
    puts "  ✗ Failed to save header changes"
  end
end

# Bulk header operations
def standardize_all_smtp_headers
  smtp_profiles = Gophish::Smtp.all
  puts "Standardizing headers for #{smtp_profiles.length} SMTP profiles"

  standard_headers = {
    "X-Mailer" => "Corporate Security Training Platform",
    "X-Campaign-Source" => "Internal Security Team",
    "Return-Path" => nil,  # Will be set per profile
    "List-Unsubscribe" => nil  # Will be set per profile
  }

  smtp_profiles.each_with_index do |smtp, index|
    puts "[#{index + 1}/#{smtp_profiles.length}] Processing '#{smtp.name}'"
    
    # Set dynamic headers based on from_address
    domain = smtp.from_address.split('@').last
    standard_headers["Return-Path"] = "bounces@#{domain}"
    standard_headers["List-Unsubscribe"] = "<mailto:unsubscribe@#{domain}>"

    # Add missing standard headers
    added_count = 0
    standard_headers.each do |key, value|
      unless smtp.headers.any? { |h| (h[:key] || h['key']) == key }
        smtp.add_header(key, value)
        added_count += 1
      end
    end

    if added_count > 0
      if smtp.save
        puts "  ✓ Added #{added_count} standard headers"
      else
        puts "  ✗ Failed to save headers"
      end
    else
      puts "  - Already has standard headers"
    end
  end
end

# Usage
manage_smtp_headers(1)
standardize_all_smtp_headers
```

### SMTP Configuration Templates

```ruby
# Pre-configured SMTP templates for common providers
class SMTPTemplates
  TEMPLATES = {
    gmail: {
      host: "smtp.gmail.com",
      port: 587,
      interface_type: "SMTP",
      ignore_cert_errors: false,
      headers: {
        "X-Mailer" => "Gmail SMTP Integration",
        "X-Provider" => "Gmail"
      }
    },
    
    office365: {
      host: "smtp.office365.com", 
      port: 587,
      interface_type: "SMTP",
      ignore_cert_errors: false,
      headers: {
        "X-Mailer" => "Office 365 SMTP Integration",
        "X-Provider" => "Microsoft Office 365"
      }
    },
    
    sendgrid: {
      host: "smtp.sendgrid.net",
      port: 587,
      interface_type: "SMTP",
      ignore_cert_errors: false,
      headers: {
        "X-Mailer" => "SendGrid SMTP Integration",
        "X-Provider" => "SendGrid"
      }
    },

    mailgun: {
      host: "smtp.mailgun.org",
      port: 587, 
      interface_type: "SMTP",
      ignore_cert_errors: false,
      headers: {
        "X-Mailer" => "Mailgun SMTP Integration",
        "X-Provider" => "Mailgun"
      }
    },
    
    ses: {
      host: "email-smtp.us-east-1.amazonaws.com",
      port: 587,
      interface_type: "SMTP", 
      ignore_cert_errors: false,
      headers: {
        "X-Mailer" => "Amazon SES SMTP Integration",
        "X-Provider" => "Amazon SES"
      }
    }
  }.freeze

  def self.create_from_template(template_name, name, from_address, username, password)
    template = TEMPLATES[template_name.to_sym]
    unless template
      puts "✗ Unknown template: #{template_name}"
      puts "Available templates: #{TEMPLATES.keys.join(', ')}"
      return nil
    end

    puts "Creating SMTP profile from #{template_name} template"
    
    smtp = Gophish::Smtp.new(
      name: name,
      host: template[:host],
      from_address: from_address,
      username: username,
      password: password,
      interface_type: template[:interface_type],
      ignore_cert_errors: template[:ignore_cert_errors]
    )

    # Add template headers
    template[:headers].each do |key, value|
      smtp.add_header(key, value)
    end

    # Add common headers
    smtp.add_header("Return-Path", "bounces@#{from_address.split('@').last}")
    smtp.add_header("List-Unsubscribe", "<mailto:unsubscribe@#{from_address.split('@').last}>")

    puts "Template configuration:"
    puts "  Host: #{smtp.host}"
    puts "  From: #{smtp.from_address}"
    puts "  Headers: #{smtp.header_count}"
    puts "  SSL Verification: #{smtp.ignore_cert_errors? ? 'Disabled' : 'Enabled'}"

    if smtp.valid?
      if smtp.save
        puts "  ✓ SMTP profile created successfully (ID: #{smtp.id})"
        return smtp
      else
        puts "  ✗ Save failed: #{smtp.errors.full_messages.join(', ')}"
      end
    else
      puts "  ✗ Validation failed: #{smtp.errors.full_messages.join(', ')}"
    end

    nil
  end

  def self.list_templates
    puts "Available SMTP templates:"
    TEMPLATES.each do |name, config|
      puts "  #{name}:"
      puts "    Host: #{config[:host]}"
      puts "    Provider: #{config[:headers]['X-Provider']}"
      puts "    SSL: #{config[:ignore_cert_errors] ? 'Optional' : 'Required'}"
    end
  end
end

# Usage examples
SMTPTemplates.list_templates

# Create Gmail SMTP
gmail = SMTPTemplates.create_from_template(
  :gmail,
  "Corporate Gmail SMTP",
  "security@company.com",
  "security@company.com", 
  ENV['GMAIL_APP_PASSWORD']
)

# Create Office 365 SMTP
office365 = SMTPTemplates.create_from_template(
  :office365,
  "Office 365 Mail Server",
  "training@company.com",
  "smtp_service@company.onmicrosoft.com",
  ENV['O365_PASSWORD']
)

# Create SendGrid SMTP
sendgrid = SMTPTemplates.create_from_template(
  :sendgrid,
  "SendGrid Transactional Mail",
  "no-reply@company.com",
  "apikey",
  ENV['SENDGRID_API_KEY']
)
```

### SMTP Testing and Validation

```ruby
# Comprehensive SMTP testing
class SMTPTester
  def self.validate_smtp_profile(smtp_id)
    begin
      smtp = Gophish::Smtp.find(smtp_id)
    rescue StandardError
      puts "✗ SMTP profile #{smtp_id} not found"
      return false
    end

    puts "Validating SMTP profile: #{smtp.name}"
    puts "=" * 50

    # Basic validation
    unless smtp.valid?
      puts "✗ Basic validation failed:"
      smtp.errors.full_messages.each { |error| puts "  - #{error}" }
      return false
    end
    puts "✓ Basic validation passed"

    # Configuration check
    puts "\nConfiguration Details:"
    puts "  Name: #{smtp.name}"
    puts "  Host: #{smtp.host}"
    puts "  From Address: #{smtp.from_address}"
    puts "  Interface Type: #{smtp.interface_type}"
    puts "  Username: #{smtp.username || 'Not configured'}"
    puts "  Password: #{smtp.password ? '[SET]' : '[NOT SET]'}"
    puts "  SSL Verification: #{smtp.ignore_cert_errors? ? 'Disabled' : 'Enabled'}"

    # Authentication check
    if smtp.has_authentication?
      puts "✓ Authentication configured"
    else
      puts "⚠ No authentication configured - ensure your SMTP server allows it"
    end

    # SSL/Security check
    if smtp.ignore_cert_errors?
      puts "⚠ SSL certificate verification disabled"
      puts "  This may be acceptable for development but not for production"
    else
      puts "✓ SSL certificate verification enabled"
    end

    # Header analysis
    puts "\nHeader Analysis:"
    if smtp.has_headers?
      puts "  Custom headers: #{smtp.header_count}"
      
      required_headers = ['Return-Path', 'List-Unsubscribe']
      recommended_headers = ['X-Mailer', 'X-Campaign-Type', 'Reply-To']
      
      required_headers.each do |header|
        has_header = smtp.headers.any? { |h| (h[:key] || h['key']) == header }
        puts "  #{has_header ? '✓' : '✗'} #{header}: #{has_header ? 'Present' : 'Missing'}"
      end

      recommended_headers.each do |header|
        has_header = smtp.headers.any? { |h| (h[:key] || h['key']) == header }
        puts "  #{has_header ? '✓' : '⚠'} #{header}: #{has_header ? 'Present' : 'Recommended'}"
      end
      
      # List all headers
      puts "\n  All headers:"
      smtp.headers.each_with_index do |header, index|
        key = header[:key] || header['key']
        value = header[:value] || header['value']
        puts "    #{index + 1}. #{key}: #{value}"
      end
    else
      puts "  ⚠ No custom headers configured"
      puts "  Consider adding headers for better deliverability"
    end

    # Domain analysis
    domain = smtp.from_address.split('@').last
    puts "\nDomain Analysis:"
    puts "  From domain: #{domain}"
    puts "  SMTP host: #{smtp.host}"
    
    # Check if domain matches SMTP host
    if smtp.host.include?(domain) || domain.include?(smtp.host.split('.').last(2).join('.'))
      puts "✓ Domain and SMTP host appear to match"
    else
      puts "⚠ Domain and SMTP host don't obviously match"
      puts "  Ensure your SMTP provider is authorized to send for #{domain}"
    end

    puts "\n" + "=" * 50
    puts "✓ SMTP profile validation completed"
    true
  end

  def self.security_audit_all_smtp
    smtp_profiles = Gophish::Smtp.all
    puts "Security Audit: #{smtp_profiles.length} SMTP Profiles"
    puts "=" * 60

    issues = []

    smtp_profiles.each_with_index do |smtp, index|
      puts "\n[#{index + 1}/#{smtp_profiles.length}] #{smtp.name}"
      
      # Check for insecure settings
      if smtp.ignore_cert_errors?
        issues << "#{smtp.name}: SSL verification disabled"
        puts "  ⚠️ SSL certificate verification disabled"
      end

      unless smtp.has_authentication?
        issues << "#{smtp.name}: No authentication configured"
        puts "  ⚠️ No authentication configured"
      end

      # Check for test/debug indicators
      test_indicators = ['test', 'debug', 'dev', 'staging']
      if test_indicators.any? { |indicator| smtp.name.downcase.include?(indicator) }
        puts "  ℹ️ Appears to be a test/development profile"
      end

      # Check headers for security info
      if smtp.has_headers?
        smtp.headers.each do |header|
          key = header[:key] || header['key']
          value = header[:value] || header['value']
          
          if key.downcase.include?('test') || value.downcase.include?('test')
            puts "  ℹ️ Contains test-related headers"
          end
        end
      end

      puts "  ✓ Basic security check completed"
    end

    puts "\n" + "=" * 60
    puts "Security Audit Summary:"
    if issues.any?
      puts "Issues found:"
      issues.each { |issue| puts "  - #{issue}" }
    else
      puts "✓ No security issues detected"
    end
  end
end

# Usage
SMTPTester.validate_smtp_profile(1)
SMTPTester.security_audit_all_smtp
```

## Campaign Operations

### Basic Campaign Creation

```ruby
# Create a simple campaign using existing components
campaign = Gophish::Campaign.new(
  name: "Q1 Security Awareness Campaign",
  template: { name: "Security Awareness Training" },  # Reference by name
  page: { name: "Microsoft Office 365 Login Clone" }, # Reference by name
  groups: [{ name: "Engineering Team" }],             # Reference by name
  smtp: { name: "Company Mail Server" },              # Reference by name
  url: "https://training.company.com"
)

if campaign.save
  puts "✓ Campaign created successfully!"
  puts "  ID: #{campaign.id}"
  puts "  Name: #{campaign.name}"
  puts "  Status: #{campaign.status}"
else
  puts "✗ Failed to create campaign:"
  campaign.errors.full_messages.each { |msg| puts "  - #{msg}" }
end
```

### Campaign Creation with Object References

```ruby
# Create campaign using actual object instances
template = Gophish::Template.find(1)
page = Gophish::Page.find(2)
group = Gophish::Group.find(3)
smtp = Gophish::Smtp.find(4)

campaign = Gophish::Campaign.new(
  name: "Advanced Security Training",
  template: template,    # Full template object
  page: page,           # Full page object
  groups: [group],      # Array of group objects
  smtp: smtp,           # Full SMTP object
  url: "https://secure-training.company.com"
)

if campaign.save
  puts "✓ Campaign created with object references"
  puts "  Template: #{campaign.template.name}"
  puts "  Page: #{campaign.page.name}"
  puts "  Groups: #{campaign.groups.map(&:name).join(', ')}"
end
```

### Scheduled Campaign Creation

```ruby
# Create a campaign with specific launch timing
scheduled_campaign = Gophish::Campaign.new(
  name: "Monday Morning Phishing Test",
  template: { name: "IT Security Alert" },
  page: { name: "Corporate Portal Login" },
  groups: [
    { name: "Sales Team" },
    { name: "Marketing Department" }
  ],
  smtp: { name: "Gmail SMTP with Authentication" },
  url: "https://training-portal.company.com",
  launch_date: (Time.now + 2.days).beginning_of_day.iso8601,  # Launch in 2 days at midnight
  send_by_date: (Time.now + 2.days).noon.iso8601             # Complete by noon
)

if scheduled_campaign.save
  puts "✓ Scheduled campaign created"
  puts "  Launch: #{scheduled_campaign.launch_date}"
  puts "  Send by: #{scheduled_campaign.send_by_date}"
  puts "  Launched? #{scheduled_campaign.launched?}"
  puts "  Has deadline? #{scheduled_campaign.has_send_by_date?}"
end
```

### Campaign Monitoring and Analysis

```ruby
# Monitor campaign progress
def monitor_campaign(campaign_id)
  begin
    campaign = Gophish::Campaign.find(campaign_id)
  rescue StandardError => e
    puts "✗ Campaign not found: #{e.message}"
    return
  end

  puts "Campaign Status Report"
  puts "=" * 50
  puts "Name: #{campaign.name}"
  puts "Status: #{campaign.status}"
  puts "Created: #{campaign.created_date}"
  puts "Launched: #{campaign.launch_date || 'Not launched'}"
  puts "Completed: #{campaign.completed_date || 'Not completed'}"
  puts

  # Status checks
  puts "Status Checks:"
  puts "  In progress? #{campaign.in_progress?}"
  puts "  Completed? #{campaign.completed?}"
  puts "  Has launch date? #{campaign.launched?}"
  puts "  Has deadline? #{campaign.has_send_by_date?}"
  puts

  # Results analysis
  if campaign.results.any?
    puts "Results Summary:"
    puts "  Total targets: #{campaign.results.length}"
    
    # Count by status
    status_counts = Hash.new(0)
    campaign.results.each { |result| status_counts[result.status] += 1 }
    
    status_counts.each do |status, count|
      percentage = (count.to_f / campaign.results.length * 100).round(1)
      puts "  #{status}: #{count} (#{percentage}%)"
    end
    
    # Behavior analysis
    clicked_count = campaign.results.count(&:clicked?)
    opened_count = campaign.results.count(&:opened?)
    reported_count = campaign.results.count(&:reported?)
    submitted_count = campaign.results.count(&:submitted_data?)
    
    puts "\nBehavior Analysis:"
    puts "  📧 Opened emails: #{opened_count}"
    puts "  🔗 Clicked links: #{clicked_count}"
    puts "  📝 Submitted data: #{submitted_count}"
    puts "  🚨 Reported phishing: #{reported_count}"
    puts "  📊 Click rate: #{(clicked_count.to_f / campaign.results.length * 100).round(1)}%"
    puts "  🛡️ Report rate: #{(reported_count.to_f / campaign.results.length * 100).round(1)}%"
    
    # Individual results
    if campaign.results.length <= 10
      puts "\nIndividual Results:"
      campaign.results.each do |result|
        icon = result.clicked? ? "🔗" : result.opened? ? "📧" : result.reported? ? "🚨" : "📬"
        puts "  #{icon} #{result.email} - #{result.status}"
      end
    end
  else
    puts "No results available yet"
  end

  # Timeline events
  if campaign.timeline.any?
    puts "\nRecent Timeline Events (last 5):"
    campaign.timeline.last(5).each do |event|
      puts "  #{event.time}: #{event.message}"
      puts "    Email: #{event.email}" if event.email
    end
  end
end

# Usage
monitor_campaign(1)
```

### Campaign Management Operations

```ruby
# List all campaigns with status
def list_all_campaigns
  campaigns = Gophish::Campaign.all
  puts "Found #{campaigns.length} campaigns:"
  puts

  campaigns.each do |campaign|
    status_icon = case campaign.status
                  when "In progress" then "🔄"
                  when "Completed" then "✅"
                  else "⏸️"
                  end
    
    puts "#{status_icon} #{campaign.id}: #{campaign.name}"
    puts "    Status: #{campaign.status}"
    puts "    Created: #{campaign.created_date}"
    puts "    Launched: #{campaign.launch_date || 'Not scheduled'}"
    
    if campaign.results.any?
      total = campaign.results.length
      clicked = campaign.results.count(&:clicked?)
      puts "    Results: #{clicked}/#{total} clicked (#{(clicked.to_f/total*100).round(1)}%)"
    end
    puts
  end
end

# Complete a running campaign
def complete_campaign(campaign_id)
  begin
    campaign = Gophish::Campaign.find(campaign_id)
  rescue StandardError => e
    puts "✗ Campaign not found: #{e.message}"
    return false
  end

  unless campaign.in_progress?
    puts "✗ Campaign '#{campaign.name}' is not in progress (status: #{campaign.status})"
    return false
  end

  puts "Completing campaign '#{campaign.name}'..."
  
  begin
    result = campaign.complete!
    
    if result['success']
      puts "✓ Campaign completed successfully"
      puts "  New status: #{campaign.status}"
      puts "  Completed date: #{campaign.completed_date}"
      return true
    else
      puts "✗ Failed to complete campaign: #{result['message'] || 'Unknown error'}"
      return false
    end
  rescue StandardError => e
    puts "✗ Error completing campaign: #{e.message}"
    return false
  end
end

# Clone campaign with modifications
def clone_campaign(original_id, new_name, modifications = {})
  begin
    original = Gophish::Campaign.find(original_id)
  rescue StandardError => e
    puts "✗ Original campaign not found: #{e.message}"
    return nil
  end

  puts "Cloning campaign '#{original.name}' as '#{new_name}'"
  
  # Create clone with same settings
  cloned_campaign = Gophish::Campaign.new(
    name: new_name,
    template: original.template,
    page: original.page,
    groups: original.groups,
    smtp: original.smtp,
    url: original.url,
    launch_date: original.launch_date,
    send_by_date: original.send_by_date
  )

  # Apply modifications
  modifications.each do |field, value|
    if cloned_campaign.respond_to?("#{field}=")
      cloned_campaign.send("#{field}=", value)
      puts "  Modified #{field}: #{value}"
    else
      puts "  ⚠️ Unknown field: #{field}"
    end
  end

  if cloned_campaign.save
    puts "✓ Campaign cloned successfully (ID: #{cloned_campaign.id})"
    return cloned_campaign
  else
    puts "✗ Clone failed:"
    cloned_campaign.errors.full_messages.each { |msg| puts "  - #{msg}" }
    return nil
  end
end

# Usage examples
list_all_campaigns
complete_campaign(1)

# Clone with new launch date
cloned = clone_campaign(1, "Cloned Security Training", {
  launch_date: (Time.now + 1.week).iso8601,
  url: "https://testing.company.com"
})
```

### Complete Campaign Workflow

```ruby
# End-to-end campaign creation and management
class CampaignManager
  def initialize
    @logger = Logger.new(STDOUT)
  end

  def create_complete_campaign(config)
    @logger.info "Creating complete campaign: #{config[:name]}"
    
    # Step 1: Create target group
    group = create_or_find_group(config[:group_name], config[:csv_file])
    return nil unless group

    # Step 2: Create template
    template = create_template(config[:template])
    return nil unless template

    # Step 3: Create landing page
    page = create_page(config[:page])
    return nil unless page

    # Step 4: Create SMTP profile
    smtp = create_or_find_smtp(config[:smtp])
    return nil unless smtp

    # Step 5: Create campaign
    campaign = create_campaign(config, template, page, group, smtp)
    return nil unless campaign

    @logger.info "Campaign creation completed successfully"
    campaign
  end

  private

  def create_or_find_group(name, csv_file)
    @logger.info "Creating group: #{name}"
    
    # Check if group already exists
    existing_groups = Gophish::Group.all
    existing = existing_groups.find { |g| g.name == name }
    
    if existing
      @logger.info "Using existing group: #{name} (#{existing.targets.length} targets)"
      return existing
    end

    # Create new group
    group = Gophish::Group.new(name: name)
    
    if csv_file && File.exist?(csv_file)
      csv_content = File.read(csv_file)
      group.import_csv(csv_content)
      @logger.info "Imported #{group.targets.length} targets from #{csv_file}"
    else
      @logger.warn "No CSV file provided or file not found: #{csv_file}"
      return nil
    end

    if group.save
      @logger.info "Group created successfully (ID: #{group.id})"
      return group
    else
      @logger.error "Failed to create group: #{group.errors.full_messages.join(', ')}"
      return nil
    end
  end

  def create_template(config)
    @logger.info "Creating template: #{config[:name]}"
    
    template = Gophish::Template.new(
      name: config[:name],
      envelope_sender: config[:envelope_sender],
      subject: config[:subject],
      html: config[:html],
      text: config[:text]
    )

    # Add attachments if specified
    if config[:attachments]
      config[:attachments].each do |attachment_config|
        file_content = File.read(attachment_config[:file_path])
        template.add_attachment(
          file_content, 
          attachment_config[:content_type], 
          attachment_config[:filename]
        )
        @logger.info "Added attachment: #{attachment_config[:filename]}"
      end
    end

    if template.save
      @logger.info "Template created successfully (ID: #{template.id})"
      return template
    else
      @logger.error "Failed to create template: #{template.errors.full_messages.join(', ')}"
      return nil
    end
  end

  def create_page(config)
    @logger.info "Creating page: #{config[:name]}"
    
    page = Gophish::Page.new(
      name: config[:name],
      html: config[:html],
      capture_credentials: config[:capture_credentials] || false,
      capture_passwords: config[:capture_passwords] || false,
      redirect_url: config[:redirect_url]
    )

    if page.save
      @logger.info "Page created successfully (ID: #{page.id})"
      return page
    else
      @logger.error "Failed to create page: #{page.errors.full_messages.join(', ')}"
      return nil
    end
  end

  def create_or_find_smtp(config)
    @logger.info "Creating SMTP profile: #{config[:name]}"
    
    # Check if SMTP profile already exists
    existing_smtps = Gophish::Smtp.all
    existing = existing_smtps.find { |s| s.name == config[:name] }
    
    if existing
      @logger.info "Using existing SMTP profile: #{config[:name]}"
      return existing
    end

    smtp = Gophish::Smtp.new(
      name: config[:name],
      host: config[:host],
      from_address: config[:from_address],
      username: config[:username],
      password: config[:password],
      ignore_cert_errors: config[:ignore_cert_errors] || false
    )

    # Add headers if specified
    if config[:headers]
      config[:headers].each do |key, value|
        smtp.add_header(key, value)
      end
      @logger.info "Added #{config[:headers].length} custom headers"
    end

    if smtp.save
      @logger.info "SMTP profile created successfully (ID: #{smtp.id})"
      return smtp
    else
      @logger.error "Failed to create SMTP profile: #{smtp.errors.full_messages.join(', ')}"
      return nil
    end
  end

  def create_campaign(config, template, page, group, smtp)
    @logger.info "Creating campaign: #{config[:name]}"
    
    campaign = Gophish::Campaign.new(
      name: config[:name],
      template: template,
      page: page,
      groups: [group],
      smtp: smtp,
      url: config[:url],
      launch_date: config[:launch_date],
      send_by_date: config[:send_by_date]
    )

    if campaign.save
      @logger.info "Campaign created successfully (ID: #{campaign.id})"
      @logger.info "Campaign components:"
      @logger.info "  Template: #{template.name} (ID: #{template.id})"
      @logger.info "  Page: #{page.name} (ID: #{page.id})"
      @logger.info "  Group: #{group.name} (#{group.targets.length} targets)"
      @logger.info "  SMTP: #{smtp.name} (#{smtp.host})"
      return campaign
    else
      @logger.error "Failed to create campaign: #{campaign.errors.full_messages.join(', ')}"
      return nil
    end
  end
end

# Usage example with complete configuration
manager = CampaignManager.new

campaign_config = {
  name: "Q2 2024 Security Awareness Campaign",
  group_name: "All Employees Q2",
  csv_file: "employees_q2.csv",
  template: {
    name: "IT Security Alert - Q2 2024",
    envelope_sender: "noreply@company.com",
    subject: "URGENT: Security Update Required",
    html: <<~HTML,
      <html>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #f8f9fa; padding: 20px; border-radius: 10px;">
          <h2 style="color: #dc3545;">🔒 Security Alert</h2>
          <p>Dear {{.FirstName}} {{.LastName}},</p>
          <p>We have detected suspicious activity on your account and need you to verify your credentials immediately.</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="{{.URL}}" style="background: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">
              Verify Account Now
            </a>
          </div>
          <p><small>This verification link will expire in 24 hours.</small></p>
          <p>Best regards,<br>IT Security Team</p>
        </div>
      </body>
      </html>
    HTML
    text: "Security Alert: Please verify your account at {{.URL}}"
  },
  page: {
    name: "Corporate Security Portal",
    html: File.read("templates/security_portal.html"),  # Load from file
    capture_credentials: true,
    capture_passwords: true,
    redirect_url: "https://company.com/security-confirmed"
  },
  smtp: {
    name: "Corporate SMTP Server",
    host: "smtp.company.com",
    from_address: "security@company.com",
    username: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    headers: {
      "X-Mailer" => "Corporate Security Training Platform",
      "X-Campaign-Type" => "Security Awareness",
      "Return-Path" => "bounces@company.com"
    }
  },
  url: "https://security-portal.company.com",
  launch_date: (Time.now + 1.day).iso8601,
  send_by_date: (Time.now + 2.days).iso8601
}

campaign = manager.create_complete_campaign(campaign_config)

if campaign
  puts "\n🎉 Complete campaign created successfully!"
  puts "Campaign ID: #{campaign.id}"
  puts "Launch Date: #{campaign.launch_date}"
  puts "Monitor progress at: https://your-gophish-server.com/campaigns/#{campaign.id}"
else
  puts "\n❌ Campaign creation failed. Check logs for details."
end
```

### Campaign Results Export and Reporting

```ruby
# Advanced campaign reporting and data export
class CampaignReporter
  def self.generate_detailed_report(campaign_id, output_file = nil)
    begin
      campaign = Gophish::Campaign.find(campaign_id)
    rescue StandardError => e
      puts "✗ Campaign not found: #{e.message}"
      return nil
    end

    report = build_campaign_report(campaign)
    
    if output_file
      File.write(output_file, report)
      puts "✓ Report saved to #{output_file}"
    else
      puts report
    end
    
    report
  end

  def self.export_results_csv(campaign_id, output_file)
    begin
      campaign = Gophish::Campaign.find(campaign_id)
    rescue StandardError => e
      puts "✗ Campaign not found: #{e.message}"
      return false
    end

    require 'csv'
    
    CSV.open(output_file, 'w') do |csv|
      # Headers
      csv << [
        'First Name', 'Last Name', 'Email', 'Position', 'Status', 
        'Sent Date', 'IP Address', 'Latitude', 'Longitude', 
        'Clicked', 'Opened', 'Submitted Data', 'Reported'
      ]
      
      # Data rows
      campaign.results.each do |result|
        csv << [
          result.first_name,
          result.last_name,
          result.email,
          result.position,
          result.status,
          result.send_date,
          result.ip,
          result.latitude,
          result.longitude,
          result.clicked?,
          result.opened?,
          result.submitted_data?,
          result.reported?
        ]
      end
    end
    
    puts "✓ Results exported to #{output_file}"
    true
  end

  private

  def self.build_campaign_report(campaign)
    report = []
    report << "=" * 80
    report << "CAMPAIGN REPORT: #{campaign.name}"
    report << "=" * 80
    report << ""
    
    # Basic information
    report << "📋 Basic Information:"
    report << "  Campaign ID: #{campaign.id}"
    report << "  Status: #{campaign.status}"
    report << "  Created: #{campaign.created_date}"
    report << "  Launched: #{campaign.launch_date || 'Not launched'}"
    report << "  Completed: #{campaign.completed_date || 'Not completed'}"
    report << ""
    
    # Campaign components
    report << "🔧 Campaign Components:"
    report << "  Template: #{campaign.template&.name || 'Unknown'}"
    report << "  Landing Page: #{campaign.page&.name || 'Unknown'}"
    report << "  SMTP Profile: #{campaign.smtp&.name || 'Unknown'}"
    report << "  Target Groups: #{campaign.groups&.map(&:name)&.join(', ') || 'Unknown'}"
    report << "  Campaign URL: #{campaign.url}"
    report << ""
    
    if campaign.results.any?
      total_targets = campaign.results.length
      
      # Summary statistics
      report << "📊 Results Summary:"
      report << "  Total Targets: #{total_targets}"
      
      # Count by status
      status_counts = Hash.new(0)
      campaign.results.each { |result| status_counts[result.status] += 1 }
      
      status_counts.each do |status, count|
        percentage = (count.to_f / total_targets * 100).round(1)
        report << "  #{status}: #{count} (#{percentage}%)"
      end
      
      report << ""
      
      # Behavior analysis
      sent_count = campaign.results.count(&:sent?)
      opened_count = campaign.results.count(&:opened?)
      clicked_count = campaign.results.count(&:clicked?)
      submitted_count = campaign.results.count(&:submitted_data?)
      reported_count = campaign.results.count(&:reported?)
      
      report << "🎯 Behavior Analysis:"
      report << "  📧 Emails Sent: #{sent_count} (#{percentage_of(sent_count, total_targets)}%)"
      report << "  📖 Emails Opened: #{opened_count} (#{percentage_of(opened_count, total_targets)}%)"
      report << "  🔗 Links Clicked: #{clicked_count} (#{percentage_of(clicked_count, total_targets)}%)"
      report << "  📝 Data Submitted: #{submitted_count} (#{percentage_of(submitted_count, total_targets)}%)"
      report << "  🚨 Phishing Reported: #{reported_count} (#{percentage_of(reported_count, total_targets)}%)"
      report << ""
      
      # Risk assessment
      report << "⚖️ Security Risk Assessment:"
      click_rate = percentage_of(clicked_count, total_targets)
      report_rate = percentage_of(reported_count, total_targets)
      
      if click_rate >= 30
        risk_level = "HIGH"
        risk_icon = "🔴"
      elsif click_rate >= 15
        risk_level = "MEDIUM" 
        risk_icon = "🟡"
      else
        risk_level = "LOW"
        risk_icon = "🟢"
      end
      
      report << "  #{risk_icon} Overall Risk Level: #{risk_level}"
      report << "  Click Rate: #{click_rate}% (#{rate_assessment(click_rate, 'click')})"
      report << "  Report Rate: #{report_rate}% (#{rate_assessment(report_rate, 'report')})"
      report << ""
      
      # Geographic analysis
      if campaign.results.any? { |r| r.latitude && r.longitude }
        report << "🗺️ Geographic Distribution:"
        locations = campaign.results
          .select { |r| r.latitude && r.longitude }
          .group_by { |r| "#{r.latitude.round(2)}, #{r.longitude.round(2)}" }
        
        locations.each do |location, results|
          report << "  #{location}: #{results.length} interactions"
        end
        report << ""
      end
      
      # Timeline analysis
      if campaign.timeline.any?
        report << "⏰ Timeline Events (last 10):"
        campaign.timeline.last(10).each do |event|
          report << "  #{event.time}: #{event.message}"
        end
        report << ""
      end
      
      # Recommendations
      report << "💡 Recommendations:"
      recommendations = generate_recommendations(campaign, click_rate, report_rate)
      recommendations.each { |rec| report << "  • #{rec}" }
      
    else
      report << "📊 No results available yet"
    end
    
    report << ""
    report << "=" * 80
    report << "Report generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    report << "=" * 80
    
    report.join("\n")
  end

  def self.percentage_of(count, total)
    return 0 if total.zero?
    (count.to_f / total * 100).round(1)
  end

  def self.rate_assessment(rate, type)
    case type
    when 'click'
      case rate
      when 0..5 then "Excellent"
      when 6..10 then "Good" 
      when 11..20 then "Concerning"
      when 21..30 then "Poor"
      else "Critical"
      end
    when 'report'
      case rate
      when 0..5 then "Critical - Low Awareness"
      when 6..15 then "Poor - Needs Training"
      when 16..25 then "Fair - Some Awareness"
      when 26..40 then "Good - Decent Awareness"
      else "Excellent - High Awareness"
      end
    end
  end

  def self.generate_recommendations(campaign, click_rate, report_rate)
    recommendations = []
    
    if click_rate >= 20
      recommendations << "High click rate indicates need for immediate security awareness training"
      recommendations << "Consider conducting follow-up educational sessions for all targets"
    end
    
    if report_rate <= 10
      recommendations << "Low report rate suggests users don't know how to report phishing"
      recommendations << "Provide clear instructions on how to report suspicious emails"
    end
    
    if campaign.results.any? { |r| r.submitted_data? }
      recommendations << "Some users submitted credentials - implement additional password security training"
      recommendations << "Consider mandatory password changes for users who submitted data"
    end
    
    # Positive reinforcement
    if report_rate >= 25
      recommendations << "Good report rate - consider recognizing users who reported the phishing"
    end
    
    if click_rate <= 10
      recommendations << "Low click rate indicates good security awareness - maintain current training"
    end
    
    recommendations << "Schedule follow-up campaigns in 2-3 months to track improvement"
    recommendations
  end
end

# Usage
CampaignReporter.generate_detailed_report(1, "campaign_1_report.txt")
CampaignReporter.export_results_csv(1, "campaign_1_results.csv")
```

### Bulk Campaign Operations

```ruby
# Create multiple campaigns for different departments
def create_department_campaigns
  departments = [
    {
      name: "Sales Department",
      csv_file: "sales_team.csv",
      template_subject: "Q4 Sales Bonus Information",
      delay_hours: 0
    },
    {
      name: "HR Department", 
      csv_file: "hr_team.csv",
      template_subject: "Employee Benefits Update",
      delay_hours: 24
    },
    {
      name: "IT Department",
      csv_file: "it_team.csv",
      template_subject: "System Maintenance Notification",
      delay_hours: 48
    },
    {
      name: "Finance Department",
      csv_file: "finance_team.csv", 
      template_subject: "Budget Review Meeting",
      delay_hours: 72
    }
  ]

  created_campaigns = []

  departments.each_with_index do |dept, index|
    puts "[#{index + 1}/#{departments.length}] Creating campaign for #{dept[:name]}"
    
    # Create group
    group = Gophish::Group.new(name: dept[:name])
    if File.exist?(dept[:csv_file])
      csv_content = File.read(dept[:csv_file])
      group.import_csv(csv_content)
    else
      puts "  ⚠️ CSV file not found: #{dept[:csv_file]}"
      next
    end
    
    unless group.save
      puts "  ✗ Failed to create group: #{group.errors.full_messages.join(', ')}"
      next
    end

    # Create department-specific template
    template = Gophish::Template.new(
      name: "#{dept[:name]} - Security Test",
      envelope_sender: "noreply@company.com",
      subject: dept[:template_subject],
      html: generate_department_html(dept[:name], dept[:template_subject])
    )
    
    unless template.save
      puts "  ✗ Failed to create template: #{template.errors.full_messages.join(', ')}"
      next
    end

    # Create campaign with staggered launch
    launch_time = Time.now + dept[:delay_hours].hours
    
    campaign = Gophish::Campaign.new(
      name: "Security Awareness - #{dept[:name]}",
      template: template,
      page: { name: "Corporate Login Portal" },  # Assume this exists
      groups: [group],
      smtp: { name: "Corporate SMTP Server" },   # Assume this exists
      url: "https://security-test.company.com",
      launch_date: launch_time.iso8601
    )
    
    if campaign.save
      puts "  ✓ Campaign created (ID: #{campaign.id})"
      puts "    Targets: #{group.targets.length}"
      puts "    Launch: #{launch_time.strftime('%Y-%m-%d %H:%M')}"
      created_campaigns << campaign
    else
      puts "  ✗ Failed to create campaign: #{campaign.errors.full_messages.join(', ')}"
    end
    
    puts
  end

  puts "Bulk campaign creation completed"
  puts "Successfully created: #{created_campaigns.length}/#{departments.length} campaigns"
  
  created_campaigns
end

def generate_department_html(department, subject)
  <<~HTML
    <html>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="margin: 0; font-size: 28px;">🏢 #{department}</h1>
        <p style="margin: 10px 0 0 0; font-size: 18px;">Important Notice</p>
      </div>
      
      <div style="background: white; padding: 30px; border: 1px solid #ddd; border-radius: 0 0 10px 10px;">
        <h2 style="color: #333; margin-top: 0;">#{subject}</h2>
        
        <p>Dear {{.FirstName}} {{.LastName}},</p>
        
        <p>This message is specifically for members of the #{department}. Please review the information below and take the required action.</p>
        
        <div style="background: #f8f9fa; padding: 20px; border-left: 4px solid #667eea; margin: 20px 0;">
          <p style="margin: 0;"><strong>Action Required:</strong> Please verify your department credentials to access the updated information.</p>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="{{.URL}}" style="background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; display: inline-block;">
            Access #{department} Portal
          </a>
        </div>
        
        <p style="color: #666; font-size: 12px; margin-top: 30px;">
          This is a security awareness exercise. If you believe this email is suspicious, please report it to the IT Security team.
        </p>
        
        <p>Best regards,<br>
        Corporate Communications</p>
      </div>
    </body>
    </html>
  HTML
end

# Usage
campaigns = create_department_campaigns
```

## Error Handling

### Comprehensive Error Handling

```ruby
def robust_group_creation(name, csv_file_path)
  puts "Creating group '#{name}' from #{csv_file_path}"

  # Step 1: Verify file exists
  unless File.exist?(csv_file_path)
    puts "✗ Error: CSV file not found"
    return false
  end

  # Step 2: Read file safely
  begin
    csv_content = File.read(csv_file_path)
  rescue Errno::EACCES
    puts "✗ Error: Permission denied reading file"
    return false
  rescue StandardError => e
    puts "✗ Error reading file: #{e.message}"
    return false
  end

  # Step 3: Create group and import
  group = Gophish::Group.new(name: name)

  begin
    group.import_csv(csv_content)
  rescue CSV::MalformedCSVError => e
    puts "✗ CSV format error: #{e.message}"
    return false
  rescue StandardError => e
    puts "✗ Import error: #{e.message}"
    return false
  end

  # Step 4: Validate
  unless group.valid?
    puts "✗ Validation errors:"
    group.errors.full_messages.each { |error| puts "    - #{error}" }
    return false
  end

  # Step 5: Save with API error handling
  begin
    unless group.save
      puts "✗ Save failed (API errors):"
      group.errors.full_messages.each { |error| puts "    - #{error}" }
      return false
    end
  rescue StandardError => e
    puts "✗ Network/API error: #{e.message}"
    return false
  end

  puts "✓ Successfully created group '#{name}' with #{group.targets.length} targets"
  puts "    Group ID: #{group.id}"
  true
end

# Usage
success = robust_group_creation("Sales Team", "sales_team.csv")
puts success ? "Operation completed" : "Operation failed"
```

### Validation Error Details

```ruby
def diagnose_validation_errors(group)
  return true if group.valid?

  puts "Validation failed. Details:"

  # Check each error type
  group.errors.each do |attribute, messages|
    puts "  #{attribute.to_s.humanize}:"
    Array(messages).each { |msg| puts "    - #{msg}" }
  end

  # Special handling for targets errors
  if group.errors[:targets].any?
    puts "\nTarget validation details:"
    group.targets.each_with_index do |target, index|
      # Check each required field
      %i[first_name last_name email position].each do |field|
        value = target[field] || target[field.to_s]
        if value.nil? || value.to_s.strip.empty?
          puts "    Target #{index}: missing #{field}"
        end
      end

      # Check email format
      email = target[:email] || target['email']
      if email && !email.match?(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
        puts "    Target #{index}: invalid email format '#{email}'"
      end
    end
  end

  false
end

# Usage
group = Gophish::Group.new(name: "", targets: [
  { first_name: "John", last_name: "", email: "invalid-email", position: "Manager" }
])

diagnose_validation_errors(group)
```

## Advanced Scenarios

### Batch Operations

```ruby
# Create multiple groups from directory of CSV files
def create_groups_from_directory(csv_directory)
  Dir.glob("#{csv_directory}/*.csv").each do |csv_file|
    file_name = File.basename(csv_file, '.csv')
    group_name = file_name.gsub('_', ' ').split.map(&:capitalize).join(' ')

    puts "Processing #{csv_file} -> '#{group_name}'"

    csv_content = File.read(csv_file)
    group = Gophish::Group.new(name: group_name)
    group.import_csv(csv_content)

    if group.valid? && group.save
      puts "  ✓ Created group with #{group.targets.length} targets"
    else
      puts "  ✗ Failed: #{group.errors.full_messages.join(', ')}"
    end
  end
end

# Usage
create_groups_from_directory("./csv_files")
```

### Group Synchronization

```ruby
# Sync local CSV with existing Gophish group
def sync_group_with_csv(group_id, csv_file_path)
  # Load existing group
  begin
    group = Gophish::Group.find(group_id)
  rescue StandardError
    puts "Group #{group_id} not found"
    return false
  end

  puts "Syncing group '#{group.name}' with #{csv_file_path}"
  puts "  Current targets: #{group.targets.length}"

  # Import new targets from CSV
  csv_content = File.read(csv_file_path)
  temp_group = Gophish::Group.new(name: "temp")
  temp_group.import_csv(csv_content)

  # Compare and update
  old_emails = group.targets.map { |t| t[:email] || t['email'] }
  new_emails = temp_group.targets.map { |t| t[:email] || t['email'] }

  added = new_emails - old_emails
  removed = old_emails - new_emails

  puts "  Changes detected:"
  puts "    Adding: #{added.length} targets"
  puts "    Removing: #{removed.length} targets"

  # Update the group
  group.targets = temp_group.targets

  if group.save
    puts "  ✓ Sync completed"
    puts "    New target count: #{group.targets.length}"
  else
    puts "  ✗ Sync failed: #{group.errors.full_messages}"
  end
end

# Usage
sync_group_with_csv(1, "updated_employees.csv")
```

### Change Tracking Example

```ruby
# Monitor and log changes to groups
class GroupChangeTracker
  def self.track_changes(group)
    return unless group.persisted?

    changes = {}

    if group.attribute_changed?(:name)
      changes[:name] = {
        from: group.attribute_was(:name),
        to: group.name
      }
    end

    if group.attribute_changed?(:targets)
      old_targets = group.attribute_was(:targets) || []
      new_targets = group.targets || []

      changes[:targets] = {
        count_change: new_targets.length - old_targets.length,
        old_count: old_targets.length,
        new_count: new_targets.length
      }
    end

    changes
  end

  def self.log_and_save(group)
    changes = track_changes(group)

    if changes.any?
      puts "Saving changes to group '#{group.name}':"
      changes.each do |field, change|
        case field
        when :name
          puts "  Name: '#{change[:from]}' → '#{change[:to]}'"
        when :targets
          puts "  Targets: #{change[:old_count]} → #{change[:new_count]} (#{change[:count_change]:+d})"
        end
      end
    end

    result = group.save
    puts result ? "  ✓ Changes saved" : "  ✗ Save failed"
    result
  end
end

# Usage
group = Gophish::Group.find(1)
group.name = "Updated Team Name"
group.targets << { first_name: "New", last_name: "Person", email: "new@company.com", position: "Intern" }

GroupChangeTracker.log_and_save(group)
```

## Production Examples

### Configuration with Environment Variables

```ruby
# config/gophish.rb
class GophishConfig
  def self.setup
    Gophish.configure do |config|
      config.url = ENV.fetch('GOPHISH_URL') { raise "GOPHISH_URL environment variable required" }
      config.api_key = ENV.fetch('GOPHISH_API_KEY') { raise "GOPHISH_API_KEY environment variable required" }
      config.verify_ssl = ENV.fetch('GOPHISH_VERIFY_SSL', 'true') == 'true'
      config.debug_output = ENV.fetch('GOPHISH_DEBUG', 'false') == 'true'
    end

    # Test connection
    begin
      Gophish::Group.all
      puts "✓ Gophish connection configured successfully"
    rescue StandardError => e
      puts "✗ Gophish connection failed: #{e.message}"
      raise
    end
  end
end

# Initialize in your application
GophishConfig.setup
```

### Logging and Monitoring

```ruby
require 'logger'

class GophishManager
  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
  end

  def create_group_with_logging(name, csv_data)
    @logger.info "Starting group creation: '#{name}'"

    group = Gophish::Group.new(name: name)

    # Parse CSV with logging
    begin
      group.import_csv(csv_data)
      @logger.info "CSV parsed successfully: #{group.targets.length} targets"
    rescue CSV::MalformedCSVError => e
      @logger.error "CSV parsing failed: #{e.message}"
      return false
    end

    # Validate with detailed logging
    unless group.valid?
      @logger.error "Validation failed for group '#{name}'"
      group.errors.full_messages.each { |error| @logger.error "  - #{error}" }
      return false
    end

    # Save with timing
    start_time = Time.now
    success = group.save
    duration = Time.now - start_time

    if success
      @logger.info "Group '#{name}' created successfully in #{duration.round(2)}s (ID: #{group.id})"
    else
      @logger.error "Failed to save group '#{name}' after #{duration.round(2)}s"
      group.errors.full_messages.each { |error| @logger.error "  - #{error}" }
    end

    success
  end

  def bulk_import(csv_directory)
    @logger.info "Starting bulk import from #{csv_directory}"

    csv_files = Dir.glob("#{csv_directory}/*.csv")
    @logger.info "Found #{csv_files.length} CSV files to process"

    results = { success: 0, failed: 0 }

    csv_files.each_with_index do |csv_file, index|
      file_name = File.basename(csv_file, '.csv')
      group_name = file_name.gsub(/[_-]/, ' ').split.map(&:capitalize).join(' ')

      @logger.info "[#{index + 1}/#{csv_files.length}] Processing '#{group_name}'"

      csv_content = File.read(csv_file)
      if create_group_with_logging(group_name, csv_content)
        results[:success] += 1
      else
        results[:failed] += 1
      end
    end

    @logger.info "Bulk import completed: #{results[:success]} succeeded, #{results[:failed]} failed"
    results
  end
end

# Usage
logger = Logger.new('gophish_import.log')
manager = GophishManager.new(logger)
results = manager.bulk_import('./employee_csvs')
```

### Retry Logic for API Calls

```ruby
class RetryableGophishOperation
  MAX_RETRIES = 3
  RETRY_DELAY = 2

  def self.with_retry(operation_name)
    retries = 0

    begin
      yield
    rescue StandardError => e
      retries += 1

      if retries <= MAX_RETRIES
        puts "#{operation_name} failed (attempt #{retries}): #{e.message}"
        puts "Retrying in #{RETRY_DELAY} seconds..."
        sleep(RETRY_DELAY)
        retry
      else
        puts "#{operation_name} failed after #{MAX_RETRIES} attempts"
        raise
      end
    end
  end

  def self.create_group_with_retry(name, targets)
    with_retry("Group creation for '#{name}'") do
      group = Gophish::Group.new(name: name, targets: targets)

      unless group.valid?
        raise StandardError, "Validation failed: #{group.errors.full_messages.join(', ')}"
      end

      unless group.save
        raise StandardError, "Save failed: #{group.errors.full_messages.join(', ')}"
      end

      puts "✓ Group '#{name}' created successfully"
      group
    end
  end
end

# Usage
targets = [
  { first_name: "John", last_name: "Doe", email: "john@example.com", position: "Manager" }
]

group = RetryableGophishOperation.create_group_with_retry("Test Group", targets)
```

These examples demonstrate real-world usage patterns and robust error handling for production environments.
