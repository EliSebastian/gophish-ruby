# Examples

This document contains practical examples for common use cases with the Gophish Ruby SDK.

## Table of Contents

- [Basic Operations](#basic-operations)
- [CSV Operations](#csv-operations)
- [Template Operations](#template-operations)
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
