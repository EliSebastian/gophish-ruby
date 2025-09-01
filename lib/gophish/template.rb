require_relative 'base'
require 'active_support/core_ext/object/blank'
require 'base64'

module Gophish
  class Template < Base
    attribute :id, :integer
    attribute :name, :string
    attribute :envelope_sender, :string
    attribute :subject, :string
    attribute :text, :string
    attribute :html, :string
    attribute :modified_date, :string
    attribute :attachments, default: -> { [] }

    define_attribute_methods :id, :name, :envelope_sender, :subject, :text, :html, :modified_date, :attachments

    validates :name, presence: true
    validate :validate_content_presence
    validate :validate_attachments_structure

    def body_for_create
      { name:, envelope_sender:, subject:, text:, html:, attachments: }
    end

    def self.import_email(content, convert_links: false)
      options = build_import_options content, convert_links
      response = post '/import/email', options
      raise StandardError, 'Failed to import email' unless response.success?

      response.parsed_response
    end

    def self.build_import_options(content, convert_links)
      {
        body: { content:, convert_links: }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    def add_attachment(content, type, name)
      encoded_content = encode_content content
      attachments << { content: encoded_content, type:, name: }
      attachments_will_change!
    end

    def remove_attachment(name)
      original_size = attachments.size
      attachments.reject! { |attachment| attachment[:name] == name || attachment['name'] == name }
      attachments_will_change! if attachments.size != original_size
    end

    def has_attachments?
      !attachments.empty?
    end

    def attachment_count
      attachments.length
    end

    def has_envelope_sender?
      !envelope_sender.blank?
    end

    private

    def encode_content(content)
      content.is_a?(String) ? Base64.strict_encode64(content) : content
    end

    def validate_content_presence
      return unless text.blank? && html.blank?

      errors.add :base, 'Need to specify at least plaintext or HTML content'
    end

    def validate_attachments_structure
      return if attachments.blank?
      return errors.add :attachments, 'must be an array' unless attachments.is_a? Array

      attachments.each_with_index { |attachment, index| validate_attachment attachment, index }
    end

    def validate_attachment(attachment, index)
      return errors.add :attachments, "item at index #{index} must be a hash" unless attachment.is_a? Hash

      validate_attachment_field attachment, index, :content
      validate_attachment_field attachment, index, :type
      validate_attachment_field attachment, index, :name
    end

    def validate_attachment_field(attachment, index, field)
      value = attachment[field] || attachment[field.to_s]
      return unless value.blank?

      errors.add :attachments, "item at index #{index} must have a #{field}"
    end
  end
end
