# API Reference

This document provides detailed API reference for the Gophish Ruby SDK.

## Table of Contents

- [Configuration](#configuration)
- [Base Class](#base-class)
- [Group Class](#group-class)
- [Template Class](#template-class)
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
