# API Reference

This document provides detailed API reference for the Gophish Ruby SDK.

## Table of Contents

- [Configuration](#configuration)
- [Base Class](#base-class)
- [Group Class](#group-class)
- [Template Class](#template-class)
- [Page Class](#page-class)
- [SMTP Class](#smtp-class)
- [Campaign Class](#campaign-class)
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
| `envelope_sender` | String | No | Envelope sender email address for advanced delivery control |
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

##### `#has_envelope_sender?`

Check if template has an envelope sender configured.

**Returns:** Boolean

**Example:**

```ruby
template = Gophish::Template.new(envelope_sender: "noreply@company.com")
puts template.has_envelope_sender?  # => true

template = Gophish::Template.new
puts template.has_envelope_sender?  # => false
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

##### Template with Envelope Sender

```ruby
# Create template with envelope sender for better deliverability
template = Gophish::Template.new(
  name: "Corporate IT Update",
  envelope_sender: "noreply@company.com",  # Separate envelope sender
  subject: "Important IT Security Update",
  html: <<~HTML
    <html>
    <body>
      <h1>IT Security Department</h1>
      <p>We've detected suspicious activity on your account.</p>
      <p><a href="{{.URL}}">Click here to verify your account</a></p>
      <p>Thank you,<br>IT Security Team</p>
    </body>
    </html>
  HTML
)

if template.save
  puts "Template created with envelope sender"
  puts "Envelope sender: #{template.envelope_sender}"
  puts "Has envelope sender: #{template.has_envelope_sender?}"
end
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

## Campaign Class

The `Gophish::Campaign` class represents a phishing campaign that orchestrates the sending of phishing emails to target groups using templates, landing pages, and SMTP profiles.

### Class: `Gophish::Campaign < Gophish::Base`

#### Attributes

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | No | Unique campaign identifier (set by server) |
| `name` | String | Yes | Campaign name |
| `created_date` | String | No | Campaign creation timestamp (set by server) |
| `launch_date` | String | No | When the campaign should start sending emails |
| `send_by_date` | String | No | Deadline for sending all campaign emails |
| `completed_date` | String | No | When the campaign was completed (set by server) |
| `template` | Hash/Object | Yes | Reference to email template (can be hash with name or Template instance) |
| `page` | Hash/Object | Yes | Reference to landing page (can be hash with name or Page instance) |
| `status` | String | No | Current campaign status (e.g., "In progress", "Completed") |
| `results` | Array | No | Array of Result instances showing target interactions |
| `groups` | Array | Yes | Array of target groups (can be hashes with names or Group instances) |
| `timeline` | Array | No | Array of Event instances showing campaign timeline |
| `smtp` | Hash/Object | Yes | Reference to SMTP profile (can be hash with name or Smtp instance) |
| `url` | String | Yes | Base URL for the campaign |

#### Validations

- `name` must be present
- `template` must be present (reference to existing template)
- `page` must be present (reference to existing landing page)
- `groups` must be present and non-empty (references to existing groups)
- `smtp` must be present (reference to existing SMTP profile)
- `url` must be present
- All groups must have names if provided as hashes
- All results must have email addresses
- All timeline events must have time and message

#### Class Methods

##### `.get_results(id)`

Get campaign results by campaign ID without loading the full campaign object.

**Parameters:**

- `id` (Integer) - Campaign ID

**Returns:** Array of result hashes

**Raises:**

- `StandardError` if campaign not found or API request fails

**Example:**

```ruby
results = Gophish::Campaign.get_results(1)
puts "Campaign has #{results.length} results"
```

##### `.get_summary(id)`

Get campaign summary statistics by ID without loading the full campaign object.

**Parameters:**

- `id` (Integer) - Campaign ID

**Returns:** Hash of summary statistics

**Raises:**

- `StandardError` if campaign not found or API request fails

**Example:**

```ruby
summary = Gophish::Campaign.get_summary(1)
puts "Campaign stats: #{summary['stats']}"
```

##### `.complete(id)`

Complete a campaign by ID without loading the full campaign object.

**Parameters:**

- `id` (Integer) - Campaign ID

**Returns:** Hash with success status

**Raises:**

- `StandardError` if campaign not found or API request fails

**Example:**

```ruby
result = Gophish::Campaign.complete(1)
puts "Campaign completed: #{result['success']}"
```

#### Instance Methods

##### `#get_results`

Get detailed campaign results for this campaign instance.

**Returns:** Array of parsed response data

**Example:**

```ruby
campaign = Gophish::Campaign.find(1)
results = campaign.get_results
puts "Total targets: #{results.length}"
```

##### `#get_summary`

Get campaign summary statistics for this campaign instance.

**Returns:** Hash of summary data

**Example:**

```ruby
campaign = Gophish::Campaign.find(1)
summary = campaign.get_summary
puts "Campaign summary: #{summary}"
```

##### `#complete!`

Complete the campaign and update the status attribute.

**Returns:** Hash with success status

**Side Effects:**

- Updates `status` attribute to 'Completed' on success

**Example:**

```ruby
campaign = Gophish::Campaign.find(1)
if campaign.in_progress?
  result = campaign.complete!
  puts "Campaign completed: #{result['success']}"
  puts "New status: #{campaign.status}"
end
```

##### `#in_progress?`

Check if campaign is currently running.

**Returns:** Boolean (true if status is "In progress")

**Example:**

```ruby
if campaign.in_progress?
  puts "Campaign is actively running"
end
```

##### `#completed?`

Check if campaign has been completed.

**Returns:** Boolean (true if status is "Completed")

**Example:**

```ruby
if campaign.completed?
  puts "Campaign has finished"
end
```

##### `#launched?`

Check if campaign has a launch date set.

**Returns:** Boolean (true if launch_date is not blank)

**Example:**

```ruby
if campaign.launched?
  puts "Campaign launched at: #{campaign.launch_date}"
end
```

##### `#has_send_by_date?`

Check if campaign has a send-by deadline configured.

**Returns:** Boolean (true if send_by_date is not blank)

**Example:**

```ruby
if campaign.has_send_by_date?
  puts "Must complete sending by: #{campaign.send_by_date}"
end
```

#### Nested Classes

##### `Gophish::Campaign::Result`

Represents individual target results within a campaign.

**Attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | String | Result identifier |
| `first_name` | String | Target's first name |
| `last_name` | String | Target's last name |
| `position` | String | Target's position |
| `email` | String | Target's email address |
| `status` | String | Current result status |
| `ip` | String | IP address of target interactions |
| `latitude` | Float | Geographic latitude |
| `longitude` | Float | Geographic longitude |
| `send_date` | String | When email was sent |
| `reported` | Boolean | Whether target reported the email |
| `modified_date` | String | Last modification timestamp |

**Instance Methods:**

- `#reported?` - Check if target reported the phishing email
- `#clicked?` - Check if target clicked the phishing link (status == "Clicked Link")
- `#opened?` - Check if target opened the email (status == "Email Opened")
- `#sent?` - Check if email was sent to target (status == "Email Sent")
- `#submitted_data?` - Check if target submitted data on landing page (status == "Submitted Data")

##### `Gophish::Campaign::Event`

Represents timeline events within a campaign.

**Attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `email` | String | Target email associated with event |
| `time` | String | Event timestamp |
| `message` | String | Event description |
| `details` | String | Additional event details (JSON string) |

**Instance Methods:**

- `#has_details?` - Check if event has additional details
- `#parsed_details` - Parse details JSON into hash (returns empty hash on parse error)

#### Usage Examples

##### Create a Basic Campaign

```ruby
campaign = Gophish::Campaign.new(
  name: "Q1 Security Awareness Training",
  template: { name: "Phishing Template" },  # Reference existing template by name
  page: { name: "Login Page" },             # Reference existing landing page by name
  groups: [{ name: "Marketing Team" }],     # Reference existing groups by name
  smtp: { name: "Company SMTP" },           # Reference existing SMTP profile by name
  url: "https://phishing.company.com"       # Base URL for campaign
)

if campaign.save
  puts "Campaign created successfully!"
  puts "  ID: #{campaign.id}"
  puts "  Name: #{campaign.name}"
  puts "  Status: #{campaign.status}"
else
  puts "Failed to create campaign:"
  campaign.errors.full_messages.each { |msg| puts "  - #{msg}" }
end
```

##### Create a Scheduled Campaign

```ruby
# Create a campaign with specific launch timing
campaign = Gophish::Campaign.new(
  name: "Scheduled Phishing Test",
  template: { name: "Email Template" },
  page: { name: "Landing Page" },
  groups: [
    { name: "HR Department" },
    { name: "Finance Team" }
  ],
  smtp: { name: "SMTP Profile" },
  url: "https://training.company.com",
  launch_date: "2024-01-15T09:00:00Z",      # Start sending at 9 AM
  send_by_date: "2024-01-15T17:00:00Z"      # Finish sending by 5 PM
)

if campaign.save
  puts "Scheduled campaign created:"
  puts "  Launch Date: #{campaign.launch_date}"
  puts "  Send By Date: #{campaign.send_by_date}"
  puts "  Launched? #{campaign.launched?}"
  puts "  Has send by date? #{campaign.has_send_by_date?}"
end
```

##### Monitor Campaign Progress

```ruby
# Load and monitor an existing campaign
campaign = Gophish::Campaign.find(1)

puts "Campaign: #{campaign.name}"
puts "Status: #{campaign.status}"
puts "In progress? #{campaign.in_progress?}"
puts "Completed? #{campaign.completed?}"

# Get detailed results
results = campaign.get_results
puts "\nCampaign Results Summary:"
puts "  Total targets: #{results.length}"

# Analyze results by status
clicked_count = 0
opened_count = 0
reported_count = 0

campaign.results.each do |result|
  clicked_count += 1 if result.clicked?
  opened_count += 1 if result.opened?
  reported_count += 1 if result.reported?
end

puts "  Clicked links: #{clicked_count}"
puts "  Opened emails: #{opened_count}"
puts "  Reported phishing: #{reported_count}"
puts "  Click rate: #{(clicked_count.to_f / results.length * 100).round(2)}%"
```

##### Analyze Campaign Timeline

```ruby
campaign = Gophish::Campaign.find(1)

puts "Campaign Timeline:"
campaign.timeline.each do |event|
  puts "  #{event.time}: #{event.message}"
  puts "    Email: #{event.email}" if event.email
  
  # Check for additional event details
  if event.has_details?
    details = event.parsed_details
    puts "    Details: #{details.inspect}"
  end
  puts ""
end
```

##### Complete a Running Campaign

```ruby
campaign = Gophish::Campaign.find(1)

if campaign.in_progress?
  puts "Completing campaign '#{campaign.name}'..."
  
  result = campaign.complete!
  
  if result['success']
    puts "✓ Campaign completed successfully"
    puts "  Final status: #{campaign.status}"
    puts "  Completed date: #{campaign.completed_date}"
  else
    puts "✗ Failed to complete campaign: #{result['message']}"
  end
else
  puts "Campaign is not in progress (current status: #{campaign.status})"
end
```

##### Campaign with Object References

```ruby
# Create campaign using actual object instances instead of name references
template = Gophish::Template.find(1)
page = Gophish::Page.find(2)
group = Gophish::Group.find(3)
smtp = Gophish::Smtp.find(4)

campaign = Gophish::Campaign.new(
  name: "Advanced Campaign Setup",
  template: template,    # Full template object
  page: page,           # Full page object
  groups: [group],      # Array of group objects
  smtp: smtp,           # Full SMTP object
  url: "https://secure.company.com/phishing"
)

# The campaign will automatically serialize these objects appropriately
if campaign.save
  puts "Campaign created using object references"
  puts "Template: #{campaign.template.name}"
  puts "Page: #{campaign.page.name}"
  puts "Groups: #{campaign.groups.map(&:name).join(', ')}"
  puts "SMTP: #{campaign.smtp.name}"
end
```

##### Campaign Validation Examples

```ruby
# Invalid campaign - missing required components
incomplete_campaign = Gophish::Campaign.new(name: "Incomplete Campaign")

unless incomplete_campaign.valid?
  puts "Validation errors:"
  incomplete_campaign.errors.full_messages.each { |msg| puts "  - #{msg}" }
  # Output:
  # - Template can't be blank
  # - Page can't be blank
  # - Groups can't be blank
  # - Smtp can't be blank
  # - Url can't be blank
end

# Invalid group structure
invalid_groups_campaign = Gophish::Campaign.new(
  name: "Test Campaign",
  template: { name: "Template" },
  page: { name: "Page" },
  groups: [{}],  # Invalid: group without name
  smtp: { name: "SMTP" },
  url: "https://test.com"
)

unless invalid_groups_campaign.valid?
  puts "Group validation error:"
  puts invalid_groups_campaign.errors.full_messages.first
  # => "Groups item at index 0 must have a name"
end

# Valid campaign
valid_campaign = Gophish::Campaign.new(
  name: "Valid Campaign",
  template: { name: "Test Template" },
  page: { name: "Test Page" },
  groups: [{ name: "Test Group" }],
  smtp: { name: "Test SMTP" },
  url: "https://valid.example.com"
)

puts "Campaign valid? #{valid_campaign.valid?}"  # => true
```

##### Bulk Campaign Operations

```ruby
# Create multiple campaigns programmatically
templates = Gophish::Template.all
groups = Gophish::Group.all
page = Gophish::Page.find(1)
smtp = Gophish::Smtp.find(1)

campaigns_created = 0

templates.each do |template|
  campaign = Gophish::Campaign.new(
    name: "Auto Campaign - #{template.name}",
    template: template,
    page: page,
    groups: [groups.sample],  # Random group for testing
    smtp: smtp,
    url: "https://training.company.com",
    launch_date: (Time.now + 1.hour).iso8601
  )
  
  if campaign.save
    campaigns_created += 1
    puts "✓ Created campaign: #{campaign.name}"
  else
    puts "✗ Failed to create campaign for template #{template.name}:"
    campaign.errors.full_messages.each { |msg| puts "    #{msg}" }
  end
end

puts "\nCreated #{campaigns_created} campaigns successfully"
```

##### Campaign Reporting

```ruby
# Generate comprehensive campaign report
def generate_campaign_report(campaign_id)
  campaign = Gophish::Campaign.find(campaign_id)
  
  puts "="*60
  puts "CAMPAIGN REPORT: #{campaign.name}"
  puts "="*60
  
  puts "\nBasic Information:"
  puts "  ID: #{campaign.id}"
  puts "  Status: #{campaign.status}"
  puts "  Created: #{campaign.created_date}"
  puts "  Launched: #{campaign.launch_date || 'Not launched'}"
  puts "  Completed: #{campaign.completed_date || 'Not completed'}"
  
  puts "\nCampaign Components:"
  puts "  Template: #{campaign.template.name rescue 'Unknown'}"
  puts "  Landing Page: #{campaign.page.name rescue 'Unknown'}"
  puts "  SMTP Profile: #{campaign.smtp.name rescue 'Unknown'}"
  puts "  Target Groups: #{campaign.groups.map(&:name).join(', ') rescue 'Unknown'}"
  
  puts "\nResults Summary:"
  total_targets = campaign.results.length
  puts "  Total Targets: #{total_targets}"
  
  if total_targets > 0
    sent = campaign.results.count(&:sent?)
    opened = campaign.results.count(&:opened?)
    clicked = campaign.results.count(&:clicked?)
    submitted = campaign.results.count(&:submitted_data?)
    reported = campaign.results.count(&:reported?)
    
    puts "  Emails Sent: #{sent} (#{(sent.to_f/total_targets*100).round(1)}%)"
    puts "  Emails Opened: #{opened} (#{(opened.to_f/total_targets*100).round(1)}%)"
    puts "  Links Clicked: #{clicked} (#{(clicked.to_f/total_targets*100).round(1)}%)"
    puts "  Data Submitted: #{submitted} (#{(submitted.to_f/total_targets*100).round(1)}%)"
    puts "  Phishing Reported: #{reported} (#{(reported.to_f/total_targets*100).round(1)}%)"
  end
  
  puts "\nTimeline Events: #{campaign.timeline.length}"
  campaign.timeline.last(5).each do |event|
    puts "  #{event.time}: #{event.message}"
  end
  
  puts "\n" + "="*60
end

# Usage
generate_campaign_report(1)
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
