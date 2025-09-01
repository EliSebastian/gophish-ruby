# API Reference

This document provides detailed API reference for the Gophish Ruby SDK.

## Table of Contents

- [Configuration](#configuration)
- [Base Class](#base-class)
- [Group Class](#group-class)
- [Template Class](#template-class)
- [Page Class](#page-class)
- [SMTP Class](#smtp-class)
- [Error Handling](#error-handling)
- [Examples](#examples)

## Configuration

The `Gophish::Configuration` class manages all SDK configuration settings.

### Class: `Gophish::Configuration`

#### Attributes

| Attribute | Type | Description | Default |
|-----------|------|-------------|---------|
| `url` | String | Base URL of the Gophish server | `nil` |
| `api_key` | String | API authentication key | `nil` |
| `verify_ssl` | Boolean | Enable SSL certificate verification | `true` |
| `debug_output` | Boolean | Enable HTTP debug output | `false` |

#### Usage

```ruby
# Block configuration (recommended)
Gophish.configure do |config|
  config.url = "https://gophish.example.com"
  config.api_key = "your-api-key"
  config.verify_ssl = true
  config.debug_output = false
end

# Direct configuration
Gophish.configuration.url = "https://gophish.example.com"
Gophish.configuration.api_key = "your-api-key"

# Access configuration
puts Gophish.configuration.url
```

## Base Class

The `Gophish::Base` class provides common functionality for all API resources.

### Class: `Gophish::Base`

#### Class Methods

##### `.all`

Retrieve all resources of this type.

**Returns:** Array of resource instances

**Raises:**

- `StandardError` if API request fails

**Example:**

```ruby
groups = Gophish::Group.all
puts "Found #{groups.length} groups"
```

##### `.find(id)`

Find a specific resource by ID.

**Parameters:**

- `id` (Integer) - The resource ID

**Returns:** Resource instance

**Raises:**

- `StandardError` if resource not found or API request fails

**Example:**

```ruby
group = Gophish::Group.find(1)
puts group.name
```

##### `.resource_name`

Get the resource name used for API endpoints.

**Returns:** String (snake_case, dasherized)

**Example:**

```ruby
Gophish::Group.resource_name  # => "group"
```

##### `.resource_path`

Get the API path for this resource.

**Returns:** String (pluralized resource path)

**Example:**

```ruby
Gophish::Group.resource_path  # => "/groups"
```

#### Instance Methods

##### `#save`

Create or update the resource on the server.

**Returns:** Boolean (true if successful, false otherwise)

**Side Effects:**

- Sets `@persisted` to true on success
- Clears change tracking information on success
- Adds errors to `#errors` on failure

**Example:**

```ruby
group = Gophish::Group.new(name: "Test", targets: [...])
if group.save
  puts "Saved with ID: #{group.id}"
else
  puts "Errors: #{group.errors.full_messages}"
end
```

##### `#destroy`

Delete the resource from the server.

**Returns:** Boolean (true if successful, false otherwise)

**Side Effects:**

- Sets `@persisted` to false on success
- Freezes the object on success

**Example:**

```ruby
group = Gophish::Group.find(1)
if group.destroy
  puts "Group deleted"
end
```

##### `#valid?`

Check if the resource passes all validations.

**Returns:** Boolean

**Side Effects:**

- Populates `#errors` with validation messages

**Example:**

```ruby
group = Gophish::Group.new
unless group.valid?
  puts group.errors.full_messages
end
```

##### `#persisted?`

Check if the resource is saved to the server.

**Returns:** Boolean (true if saved and has an ID)

**Example:**

```ruby
group = Gophish::Group.new
puts group.persisted?  # => false

group.save
puts group.persisted?  # => true (if save successful)
```

##### `#new_record?`

Check if the resource is new (not yet saved).

**Returns:** Boolean (opposite of `#persisted?`)

**Example:**

```ruby
group = Gophish::Group.new
puts group.new_record?  # => true
```

##### `#changed`

Get array of attribute names that have changed.

**Returns:** Array of Strings

**Example:**

```ruby
group = Gophish::Group.find(1)
group.name = "New Name"
puts group.changed  # => ["name"]
```

##### `#changed?`

Check if any attributes have changed.

**Returns:** Boolean

**Example:**

```ruby
group = Gophish::Group.find(1)
puts group.changed?  # => false

group.name = "New Name"
puts group.changed?  # => true
```

##### `#attribute_changed?(attr)`

Check if a specific attribute has changed.

**Parameters:**

- `attr` (String|Symbol) - Attribute name

**Returns:** Boolean

**Example:**

```ruby
group = Gophish::Group.find(1)
group.name = "New Name"
puts group.name_changed?  # => true (using dynamic method)
puts group.attribute_changed?(:name)  # => true
```

##### `#attribute_was(attr)`

Get the previous value of a changed attribute.

**Parameters:**

- `attr` (String|Symbol) - Attribute name

**Returns:** Previous value or nil

**Example:**

```ruby
group = Gophish::Group.find(1)
original_name = group.name
group.name = "New Name"
puts group.name_was  # => original_name (using dynamic method)
puts group.attribute_was(:name)  # => original_name
```

## Group Class

The `Gophish::Group` class represents a target group in Gophish.

### Class: `Gophish::Group < Gophish::Base`

#### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | No | Unique group identifier (set by server) |
| `name` | String | Yes | Group name |
| `modified_date` | String | No | Last modification timestamp (set by server) |
| `targets` | Array | Yes | Array of target hashes |

#### Target Structure

Each target in the `targets` array must have:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `first_name` | String | Yes | Target's first name |
| `last_name` | String | Yes | Target's last name |
| `email` | String | Yes | Valid email address |
| `position` | String | Yes | Job position/title |

#### Validations

- `name` must be present
- `targets` must be present and be an Array
- Each target must be a Hash with required fields
- Each target's email must have valid format

#### Instance Methods

##### `#import_csv(csv_data)`

Import targets from CSV data.

**Parameters:**

- `csv_data` (String) - CSV data with headers: "First Name", "Last Name", "Email", "Position"

**Returns:** Void

**Side Effects:**

- Replaces current `targets` array with imported data

**Example:**

```ruby
csv_data = <<~CSV
  First Name,Last Name,Email,Position
  John,Doe,john@example.com,Manager
  Jane,Smith,jane@example.com,Developer
CSV

group = Gophish::Group.new(name: "Team")
group.import_csv(csv_data)
puts group.targets.length  # => 2
```

#### Usage Examples

##### Create a Group

```ruby
group = Gophish::Group.new(
  name: "Marketing Team",
  targets: [
    {
      first_name: "Alice",
      last_name: "Johnson",
      email: "alice@company.com",
      position: "Marketing Manager"
    },
    {
      first_name: "Bob",
      last_name: "Wilson",
      email: "bob@company.com",
      position: "Marketing Coordinator"
    }
  ]
)

if group.save
  puts "Group created with ID: #{group.id}"
end
```

##### Update a Group

```ruby
group = Gophish::Group.find(1)
group.name = "Updated Marketing Team"

# Add new target
group.targets << {
  first_name: "Carol",
  last_name: "Brown",
  email: "carol@company.com",
  position: "Marketing Intern"
}

group.save
```

##### Import from CSV

```ruby
csv_content = File.read("targets.csv")
group = Gophish::Group.new(name: "Imported Group")
group.import_csv(csv_content)
group.save
```

## Template Class

The `Gophish::Template` class represents an email template in Gophish.

### Class: `Gophish::Template < Gophish::Base`

#### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | No | Unique template identifier (set by server) |
| `name` | String | Yes | Template name |
| `subject` | String | No | Email subject line |
| `text` | String | No | Plain text email content |
| `html` | String | No | HTML email content |
| `modified_date` | String | No | Last modification timestamp (set by server) |
| `attachments` | Array | No | Array of attachment hashes |

#### Attachment Structure

Each attachment in the `attachments` array must have:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | String | Yes | Base64 encoded file content |
| `type` | String | Yes | MIME type (e.g., "application/pdf") |
| `name` | String | Yes | Filename |

#### Validations

- `name` must be present
- Must have either `text` or `html` content (or both)
- Each attachment must be a Hash with required fields (`content`, `type`, `name`)

#### Class Methods

##### `.import_email(content, convert_links: false)`

Import email content and return template data.

**Parameters:**

- `content` (String) - Raw email content (.eml format)
- `convert_links` (Boolean) - Whether to convert links for Gophish tracking (default: false)

**Returns:** Hash of template attributes

**Raises:**

- `StandardError` if import fails

**Example:**

```ruby
email_content = File.read("sample.eml")
template_data = Gophish::Template.import_email(email_content, convert_links: true)

template = Gophish::Template.new(template_data)
template.name = "Imported Template"
template.save
```

#### Instance Methods

##### `#add_attachment(content, type, name)`

Add an attachment to the template.

**Parameters:**

- `content` (String) - File content (will be Base64 encoded automatically)
- `type` (String) - MIME type
- `name` (String) - Filename

**Returns:** Void

**Side Effects:**

- Adds attachment to `attachments` array
- Marks `attachments` attribute as changed

**Example:**

```ruby
template = Gophish::Template.new(name: "Test", html: "<p>Test</p>")
file_content = File.read("document.pdf")
template.add_attachment(file_content, "application/pdf", "document.pdf")
```

##### `#remove_attachment(name)`

Remove an attachment by filename.

**Parameters:**

- `name` (String) - Filename of attachment to remove

**Returns:** Void

**Side Effects:**

- Removes matching attachment(s) from `attachments` array
- Marks `attachments` attribute as changed if any were removed

**Example:**

```ruby
template.remove_attachment("document.pdf")
```

##### `#has_attachments?`

Check if template has any attachments.

**Returns:** Boolean

**Example:**

```ruby
if template.has_attachments?
  puts "Template has #{template.attachment_count} attachments"
end
```

##### `#attachment_count`

Get the number of attachments.

**Returns:** Integer

**Example:**

```ruby
puts "Attachments: #{template.attachment_count}"
```

#### Usage Examples

##### Create a Template

```ruby
template = Gophish::Template.new(
  name: "Phishing Test Template",
  subject: "Important Security Update",
  html: "<h1>Security Update Required</h1><p>Please click <a href='{{.URL}}'>here</a> to update.</p>",
  text: "Security Update Required\n\nPlease visit {{.URL}} to update your credentials."
)

if template.save
  puts "Template created with ID: #{template.id}"
end
```

##### Template with Attachments

```ruby
template = Gophish::Template.new(
  name: "Invoice Template",
  subject: "Invoice #{{.RId}}",
  html: "<p>Please find your invoice attached.</p>"
)

# Add PDF attachment
pdf_content = File.read("invoice.pdf")
template.add_attachment(pdf_content, "application/pdf", "invoice.pdf")

# Add image attachment
image_content = File.read("logo.png")
template.add_attachment(image_content, "image/png", "logo.png")

template.save
```

##### Import from Email

```ruby
# Import existing email
email_content = File.read("phishing_template.eml")
imported_data = Gophish::Template.import_email(
  email_content,
  convert_links: true  # Convert links for tracking
)

template = Gophish::Template.new(imported_data)
template.name = "Imported Phishing Template"
template.save
```

##### Update Template

```ruby
template = Gophish::Template.find(1)
template.subject = "Updated Subject"
template.html = "<h1>Updated Content</h1>"

# Add new attachment
template.add_attachment(File.read("new_doc.pdf"), "application/pdf", "new_doc.pdf")

# Remove old attachment
template.remove_attachment("old_doc.pdf")

template.save
```

##### Template Validation

```ruby
# Invalid template (no content)
template = Gophish::Template.new(name: "Test Template")

unless template.valid?
  puts "Validation errors:"
  template.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Need to specify at least plaintext or HTML content"]
end

# Invalid attachment
template = Gophish::Template.new(
  name: "Test",
  html: "<p>Test</p>",
  attachments: [{ name: "file.pdf" }]  # Missing content and type
)

unless template.valid?
  puts template.errors.full_messages
  # => ["Attachments item at index 0 must have a content", 
  #     "Attachments item at index 0 must have a type"]
end
```

## Page Class

The `Gophish::Page` class represents a landing page in Gophish campaigns.

### Class: `Gophish::Page < Gophish::Base`

#### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | No | Unique page identifier (set by server) |
| `name` | String | Yes | Page name |
| `html` | String | Yes | HTML content of the page |
| `capture_credentials` | Boolean | No | Whether to capture credentials (default: false) |
| `capture_passwords` | Boolean | No | Whether to capture passwords (default: false) |
| `redirect_url` | String | No | URL to redirect users after form submission |
| `modified_date` | String | No | Last modification timestamp (set by server) |

#### Validations

- `name` must be present
- `html` must be present

#### Class Methods

##### `.import_site(url, include_resources: false)`

Import a website as a landing page template.

**Parameters:**

- `url` (String) - URL of the website to import
- `include_resources` (Boolean) - Whether to include CSS, JS, and images (default: false)

**Returns:** Hash of page attributes

**Raises:**

- `StandardError` if import fails

**Example:**

```ruby
begin
  page_data = Gophish::Page.import_site(
    "https://login.microsoft.com",
    include_resources: true
  )
  
  page = Gophish::Page.new(page_data)
  page.name = "Imported Microsoft Login"
  page.capture_credentials = true
  page.save
rescue StandardError => e
  puts "Import failed: #{e.message}"
end
```

#### Instance Methods

##### `#captures_credentials?`

Check if page is configured to capture credentials.

**Returns:** Boolean

**Example:**

```ruby
page = Gophish::Page.new(capture_credentials: true)
puts page.captures_credentials?  # => true
```

##### `#captures_passwords?`

Check if page is configured to capture passwords.

**Returns:** Boolean

**Example:**

```ruby
page = Gophish::Page.new(capture_passwords: true)
puts page.captures_passwords?  # => true
```

##### `#has_redirect?`

Check if page has a redirect URL configured.

**Returns:** Boolean

**Example:**

```ruby
page = Gophish::Page.new(redirect_url: "https://example.com")
puts page.has_redirect?  # => true

page = Gophish::Page.new
puts page.has_redirect?  # => false
```

#### Usage Examples

##### Create a Basic Landing Page

```ruby
page = Gophish::Page.new(
  name: "Microsoft Login Clone",
  html: <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Microsoft Account</title>
      <style>
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background-color: #f5f5f5;
          margin: 0;
          padding: 40px;
        }
        .login-form {
          max-width: 400px;
          margin: 0 auto;
          background: white;
          padding: 40px;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .form-group { margin-bottom: 20px; }
        input {
          width: 100%;
          padding: 12px;
          border: 1px solid #ddd;
          border-radius: 4px;
          font-size: 14px;
        }
        button {
          width: 100%;
          padding: 12px;
          background: #0078d4;
          color: white;
          border: none;
          border-radius: 4px;
          font-size: 14px;
          cursor: pointer;
        }
        button:hover { background: #106ebe; }
      </style>
    </head>
    <body>
      <div class="login-form">
        <h2>Sign in</h2>
        <form method="post">
          <div class="form-group">
            <input type="email" name="username" placeholder="Email" required>
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

if page.save
  puts "Landing page created with ID: #{page.id}"
end
```

##### Create Page with Credential Capture

```ruby
page = Gophish::Page.new(
  name: "Banking Portal - Credential Capture",
  html: <<~HTML
    <html>
    <head>
      <title>Secure Banking Portal</title>
      <style>
        body { font-family: Arial, sans-serif; background: #1e3d59; color: white; }
        .container { max-width: 400px; margin: 100px auto; padding: 40px; background: white; color: black; border-radius: 10px; }
        input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ccc; }
        button { width: 100%; padding: 12px; background: #1e3d59; color: white; border: none; border-radius: 5px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Secure Login</h2>
        <form method="post">
          <input type="text" name="username" placeholder="Username" required>
          <input type="password" name="password" placeholder="Password" required>
          <button type="submit">Access Account</button>
        </form>
      </div>
    </body>
    </html>
  HTML,
  capture_credentials: true,
  capture_passwords: true,
  redirect_url: "https://www.realbank.com/login"
)

puts "Page captures credentials: #{page.captures_credentials?}"
puts "Page captures passwords: #{page.captures_passwords?}"
puts "Page has redirect: #{page.has_redirect?}"

page.save
```

##### Import Website as Landing Page

```ruby
# Import a real website
begin
  imported_data = Gophish::Page.import_site(
    "https://accounts.google.com/signin",
    include_resources: true  # Include CSS, JS, images
  )
  
  page = Gophish::Page.new(imported_data)
  page.name = "Google Login Clone"
  page.capture_credentials = true
  
  if page.save
    puts "Successfully imported Google login page"
    puts "Page ID: #{page.id}"
  end
  
rescue StandardError => e
  puts "Failed to import site: #{e.message}"
  
  # Fallback to manual creation
  page = Gophish::Page.new(
    name: "Manual Google Login Clone",
    html: "<html><body><h1>Google</h1><form method='post'><input name='email' type='email' placeholder='Email'><input name='password' type='password' placeholder='Password'><button type='submit'>Sign in</button></form></body></html>",
    capture_credentials: true
  )
  page.save
end
```

##### Update Existing Page

```ruby
page = Gophish::Page.find(1)

# Update content
page.html = page.html.gsub("Sign in", "Login")

# Enable credential capture
page.capture_credentials = true
page.capture_passwords = true

# Set redirect URL
page.redirect_url = "https://legitimate-site.com"

if page.save
  puts "Page updated successfully"
  puts "Now captures credentials: #{page.captures_credentials?}"
end
```

##### Page Validation

```ruby
# Invalid page (missing required fields)
page = Gophish::Page.new

unless page.valid?
  puts "Validation errors:"
  page.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Name can't be blank", "Html can't be blank"]
end

# Valid page
page = Gophish::Page.new(
  name: "Valid Page",
  html: "<html><body>Content</body></html>"
)

puts page.valid?  # => true
```

##### Checking Page Configuration

```ruby
page = Gophish::Page.find(1)

# Check capabilities
if page.captures_credentials?
  puts "⚠️  This page will capture user credentials"
end

if page.captures_passwords?
  puts "🔐 This page will capture passwords in plain text"
end

if page.has_redirect?
  puts "🔄 Users will be redirected to: #{page.redirect_url}"
else
  puts "🛑 Users will see a generic success message"
end
```

##### Delete Page

```ruby
page = Gophish::Page.find(1)

if page.destroy
  puts "Page deleted successfully"
  puts "Page frozen: #{page.frozen?}"  # => true
end
```

## SMTP Class

The `Gophish::Smtp` class represents an SMTP sending profile in Gophish campaigns.

### Class: `Gophish::Smtp < Gophish::Base`

#### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | No | Unique SMTP profile identifier (set by server) |
| `name` | String | Yes | SMTP profile name |
| `username` | String | No | SMTP authentication username |
| `password` | String | No | SMTP authentication password |
| `host` | String | Yes | SMTP server hostname |
| `interface_type` | String | No | Interface type (default: "SMTP") |
| `from_address` | String | Yes | From email address (must be valid email format) |
| `ignore_cert_errors` | Boolean | No | Whether to ignore SSL certificate errors (default: false) |
| `modified_date` | String | No | Last modification timestamp (set by server) |
| `headers` | Array | No | Array of custom header hashes |

#### Header Structure

Each header in the `headers` array must have:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `key` | String | Yes | Header name |
| `value` | String | Yes | Header value |

#### Validations

- `name` must be present
- `host` must be present
- `from_address` must be present and have valid email format
- Each header must be a Hash with both `key` and `value`

#### Instance Methods

##### `#add_header(key, value)`

Add a custom header to the SMTP profile.

**Parameters:**

- `key` (String) - Header name
- `value` (String) - Header value

**Returns:** Void

**Side Effects:**

- Adds header to `headers` array
- Marks `headers` attribute as changed

**Example:**

```ruby
smtp = Gophish::Smtp.new(name: "Test", host: "smtp.test.com", from_address: "test@example.com")
smtp.add_header("X-Mailer", "Company Security Tool")
smtp.add_header("Return-Path", "bounces@company.com")
```

##### `#remove_header(key)`

Remove a header by key name.

**Parameters:**

- `key` (String) - Header name to remove

**Returns:** Void

**Side Effects:**

- Removes matching header(s) from `headers` array
- Marks `headers` attribute as changed if any were removed

**Example:**

```ruby
smtp.remove_header("X-Mailer")
```

##### `#has_headers?`

Check if SMTP profile has any custom headers.

**Returns:** Boolean

**Example:**

```ruby
if smtp.has_headers?
  puts "SMTP profile has #{smtp.header_count} custom headers"
end
```

##### `#header_count`

Get the number of custom headers.

**Returns:** Integer

**Example:**

```ruby
puts "Custom headers: #{smtp.header_count}"
```

##### `#has_authentication?`

Check if SMTP profile uses authentication (both username and password are present).

**Returns:** Boolean

**Example:**

```ruby
if smtp.has_authentication?
  puts "SMTP profile uses authentication"
end
```

##### `#ignores_cert_errors?`

Check if SMTP profile ignores SSL certificate errors.

**Returns:** Boolean

**Example:**

```ruby
if smtp.ignores_cert_errors?
  puts "⚠️  SMTP profile ignores SSL certificate errors"
end
```

#### Usage Examples

##### Create a Basic SMTP Profile

```ruby
smtp = Gophish::Smtp.new(
  name: "Company Mail Server",
  host: "smtp.company.com",
  from_address: "security@company.com"
)

if smtp.save
  puts "SMTP profile created with ID: #{smtp.id}"
else
  puts "Failed to create SMTP profile: #{smtp.errors.full_messages}"
end
```

##### Create SMTP Profile with Authentication

```ruby
smtp = Gophish::Smtp.new(
  name: "Gmail SMTP",
  host: "smtp.gmail.com",
  from_address: "phishing.test@company.com",
  username: "smtp_user@company.com",
  password: "app_specific_password",
  ignore_cert_errors: false
)

puts "Uses authentication: #{smtp.has_authentication?}"
puts "Ignores cert errors: #{smtp.ignores_cert_errors?}"

smtp.save
```

##### SMTP Profile with Custom Headers

```ruby
smtp = Gophish::Smtp.new(
  name: "Custom Headers SMTP",
  host: "mail.company.com",
  from_address: "security@company.com"
)

# Add custom headers for routing and identification
smtp.add_header("X-Mailer", "Gophish Security Training")
smtp.add_header("X-Campaign-Type", "Phishing Simulation")
smtp.add_header("X-Company", "ACME Corp")
smtp.add_header("Return-Path", "bounces@company.com")

puts "Header count: #{smtp.header_count}"
puts "Headers: #{smtp.headers.inspect}"

smtp.save
```

##### Update SMTP Profile

```ruby
smtp = Gophish::Smtp.find(1)

# Update basic settings
smtp.name = "Updated Company SMTP"
smtp.ignore_cert_errors = true

# Add new header
smtp.add_header("X-Priority", "High")

# Remove old header
smtp.remove_header("X-Campaign-Type")

if smtp.save
  puts "SMTP profile updated successfully"
  puts "Header count: #{smtp.header_count}"
end
```

##### SMTP Profile Validation

```ruby
# Invalid SMTP profile (missing required fields)
smtp = Gophish::Smtp.new

unless smtp.valid?
  puts "Validation errors:"
  smtp.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # => ["Name can't be blank", "Host can't be blank", "From address can't be blank"]
end

# Invalid email format
smtp = Gophish::Smtp.new(
  name: "Test SMTP",
  host: "smtp.test.com",
  from_address: "invalid-email"
)

unless smtp.valid?
  puts "Email validation error:"
  puts smtp.errors[:from_address]
  # => ["must be a valid email format (email@domain.com)"]
end

# Valid SMTP profile
smtp = Gophish::Smtp.new(
  name: "Valid SMTP",
  host: "smtp.example.com",
  from_address: "valid@example.com"
)

puts smtp.valid?  # => true
```

##### Comprehensive SMTP Configuration

```ruby
# Production-ready SMTP configuration
smtp = Gophish::Smtp.new(
  name: "Production Mail Server",
  host: "smtp.company.com",
  from_address: "security-training@company.com",
  username: "smtp_service_account",
  password: ENV['SMTP_PASSWORD'],  # Use environment variables for secrets
  ignore_cert_errors: false,  # Always verify certificates in production
  interface_type: "SMTP"
)

# Add headers for better deliverability and tracking
smtp.add_header("X-Mailer", "Gophish Security Training Platform")
smtp.add_header("X-Department", "Information Security")
smtp.add_header("Return-Path", "bounces+security@company.com")
smtp.add_header("Reply-To", "security-team@company.com")

# Validate before saving
if smtp.valid?
  if smtp.save
    puts "✓ SMTP profile created successfully!"
    puts "  ID: #{smtp.id}"
    puts "  Name: #{smtp.name}"
    puts "  Host: #{smtp.host}"
    puts "  From: #{smtp.from_address}"
    puts "  Authentication: #{smtp.has_authentication? ? 'Yes' : 'No'}"
    puts "  Custom Headers: #{smtp.header_count}"
    puts "  SSL Verification: #{smtp.ignore_cert_errors? ? 'Disabled' : 'Enabled'}"
  else
    puts "✗ Failed to save SMTP profile:"
    smtp.errors.full_messages.each { |msg| puts "  - #{msg}" }
  end
else
  puts "✗ SMTP validation failed:"
  smtp.errors.full_messages.each { |msg| puts "  - #{msg}" }
end
```

##### Delete SMTP Profile

```ruby
smtp = Gophish::Smtp.find(1)

if smtp.destroy
  puts "SMTP profile deleted successfully"
  puts "Profile frozen: #{smtp.frozen?}"  # => true
end
```

##### Security Considerations for SMTP

```ruby
smtp = Gophish::Smtp.find(1)

# Security checks
puts "🔍 Security Assessment:"
puts "  Authentication required: #{smtp.has_authentication? ? '✓' : '✗'}"
puts "  SSL verification: #{smtp.ignore_cert_errors? ? '✗ DISABLED' : '✓ ENABLED'}"
puts "  From address domain: #{smtp.from_address.split('@').last}"

if smtp.has_headers?
  puts "  Custom headers (#{smtp.header_count}):"
  smtp.headers.each do |header|
    puts "    #{header[:key] || header['key']}: #{header[:value] || header['value']}"
  end
end

# Warn about potential security issues
if smtp.ignore_cert_errors?
  puts "⚠️  WARNING: SSL certificate verification is disabled!"
  puts "   This may allow man-in-the-middle attacks in production."
end

unless smtp.has_authentication?
  puts "ℹ️  INFO: No authentication configured."
  puts "   Ensure your SMTP server allows unauthenticated sending."
end
```

## Error Handling

### Validation Errors

Validation errors are stored in the `errors` object (ActiveModel::Errors):

```ruby
group = Gophish::Group.new(name: "", targets: [])

unless group.valid?
  puts "Validation failed:"
  group.errors.full_messages.each { |msg| puts "  - #{msg}" }

  # Check specific field errors
  if group.errors[:name].any?
    puts "Name errors: #{group.errors[:name]}"
  end
end
```

### API Errors

API errors are handled and added to the errors collection:

```ruby
group = Gophish::Group.new(name: "Test", targets: [...])

unless group.save
  puts "Save failed:"
  group.errors.full_messages.each { |msg| puts "  - #{msg}" }
end
```

### Network Errors

Network-level errors raise exceptions:

```ruby
begin
  group = Gophish::Group.find(999)  # Non-existent ID
rescue StandardError => e
  puts "API Error: #{e.message}"
end
```

## Examples

### Complete Workflow Example

```ruby
require 'gophish-ruby'

# Configure the SDK
Gophish.configure do |config|
  config.url = "https://localhost:3333"
  config.api_key = "your-api-key"
  config.verify_ssl = false
  config.debug_output = true
end

# Create a new group
group = Gophish::Group.new(
  name: "Security Training Group",
  targets: []
)

# Import targets from CSV
csv_data = <<~CSV
  First Name,Last Name,Email,Position
  John,Doe,john@example.com,Manager
  Jane,Smith,jane@example.com,Developer
  Bob,Johnson,bob@example.com,Analyst
CSV

group.import_csv(csv_data)

# Validate before saving
if group.valid?
  if group.save
    puts "✓ Group created successfully!"
    puts "  ID: #{group.id}"
    puts "  Name: #{group.name}"
    puts "  Targets: #{group.targets.length}"
  else
    puts "✗ Failed to save group:"
    group.errors.full_messages.each { |msg| puts "  - #{msg}" }
  end
else
  puts "✗ Group validation failed:"
  group.errors.full_messages.each { |msg| puts "  - #{msg}" }
end

# List all groups
puts "\nAll groups:"
Gophish::Group.all.each do |g|
  puts "  #{g.id}: #{g.name} (#{g.targets.length} targets)"
end
```

### Error Recovery Example

```ruby
# Robust error handling
def create_group_safely(name, csv_data)
  group = Gophish::Group.new(name: name)

  begin
    group.import_csv(csv_data)
  rescue CSV::MalformedCSVError => e
    puts "CSV parsing failed: #{e.message}"
    return false
  end

  unless group.valid?
    puts "Validation failed: #{group.errors.full_messages.join(', ')}"
    return false
  end

  unless group.save
    puts "Save failed: #{group.errors.full_messages.join(', ')}"
    return false
  end

  puts "Group '#{name}' created successfully with ID #{group.id}"
  true
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  false
end

# Usage
csv_data = File.read("team.csv")
create_group_safely("Development Team", csv_data)
```
