require_relative 'base'
require 'active_support/core_ext/object/blank'
require 'csv'

module Gophish
  class Group < Base
    attribute :id, :integer
    attribute :name, :string
    attribute :modified_date, :string
    attribute :targets

    define_attribute_methods :id, :name, :modified_date, :targets

    validates :name, presence: true
    validates :targets, presence: true
    validate :validate_targets_structure

    def body_for_create
      { name:, targets: }
    end

    def import_csv(csv_data)
      targets_array = CSV.parse(csv_data, headers: true).map { |row| parse_csv_row row }
      self.targets = targets_array
    end

    private

    def validate_targets_structure
      return if targets.blank?
      return errors.add :targets, 'must be an array' unless targets.is_a? Array

      targets.each_with_index { |target, index| validate_target target, index }
    end

    def parse_csv_row(row)
      {
        first_name: row['First Name'],
        last_name: row['Last Name'],
        email: row['Email'],
        position: row['Position']
      }
    end

    def validate_target(target, index)
      return errors.add :targets, "item at index #{index} must be a hash" unless target.is_a? Hash

      validate_target_email target, index
      validate_required_field target, index, :position
      validate_required_field target, index, :first_name
      validate_required_field target, index, :last_name
    end

    def validate_target_email(target, index)
      email = target[:email] || target['email']
      if email.blank?
        errors.add :targets, "item at index #{index} must have an email"
      elsif !valid_email_format?(email)
        errors.add :targets, "item at index #{index} must have a valid email format"
      end
    end

    def validate_required_field(target, index, field)
      value = target[field] || target[field.to_s]
      return unless value.blank?

      errors.add :targets, "item at index #{index} must have a #{field}"
    end

    def valid_email_format?(email)
      email.match?(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
    end
  end
end
