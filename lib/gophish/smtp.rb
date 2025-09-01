require_relative 'base'
require 'active_support/core_ext/object/blank'

module Gophish
  class Smtp < Base
    def self.resource_path
      '/smtp'
    end
    attribute :id, :integer
    attribute :name, :string
    attribute :username, :string
    attribute :password, :string
    attribute :host, :string
    attribute :interface_type, :string, default: 'SMTP'
    attribute :from_address, :string
    attribute :ignore_cert_errors, :boolean, default: false
    attribute :modified_date, :string
    attribute :headers, default: -> { [] }

    define_attribute_methods :id, :name, :username, :password, :host, :interface_type, :from_address,
                             :ignore_cert_errors, :modified_date, :headers

    validates :name, presence: true
    validates :host, presence: true
    validates :from_address, presence: true
    validate :validate_from_address_format
    validate :validate_headers_structure

    def body_for_create
      {
        name:, username:, password:, host:,
        interface_type:,
        from_address:,
        ignore_cert_errors:,
        headers:
      }
    end

    def add_header(key, value)
      headers << { key:, value: }
      headers_will_change!
    end

    def remove_header(key)
      original_size = headers.size
      headers.reject! { |header| header[:key] == key || header['key'] == key }
      headers_will_change! if headers.size != original_size
    end

    def has_headers?
      !headers.empty?
    end

    def header_count
      headers.length
    end

    def has_authentication?
      !username.blank? && !password.blank?
    end

    def ignores_cert_errors?
      ignore_cert_errors == true
    end

    private

    def validate_from_address_format
      return if from_address.blank?

      email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

      unless from_address.match? email_regex
        errors.add :from_address, 'must be a valid email format (email@domain.com)'
      end
    end

    def validate_headers_structure
      return if headers.blank?
      return errors.add :headers, 'must be an array' unless headers.is_a? Array

      headers.each_with_index { |header, index| validate_header header, index }
    end

    def validate_header(header, index)
      return errors.add :headers, "item at index #{index} must be a hash" unless header.is_a? Hash

      validate_header_field header, index, :key
      validate_header_field header, index, :value
    end

    def validate_header_field(header, index, field)
      value = header[field] || header[field.to_s]
      return unless value.blank?

      errors.add :headers, "item at index #{index} must have a #{field}"
    end
  end
end
