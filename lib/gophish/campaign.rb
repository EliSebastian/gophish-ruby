require_relative 'base'
require_relative 'template'
require_relative 'page'
require_relative 'smtp'
require_relative 'group'
require 'active_support/core_ext/object/blank'

module Gophish
  class Campaign < Base
    attribute :id, :integer
    attribute :name, :string
    attribute :created_date, :string
    attribute :launch_date, :string
    attribute :send_by_date, :string
    attribute :completed_date, :string
    attribute :template
    attribute :page
    attribute :status, :string
    attribute :results, default: -> { [] }
    attribute :groups, default: -> { [] }
    attribute :timeline, default: -> { [] }
    attribute :smtp
    attribute :url, :string

    define_attribute_methods :id, :name, :created_date, :launch_date, :send_by_date,
                             :completed_date, :template, :page, :status, :results,
                             :groups, :timeline, :smtp, :url

    validates :name, presence: true
    validates :template, presence: true
    validates :page, presence: true
    validates :groups, presence: true
    validates :smtp, presence: true
    validates :url, presence: true
    validate :validate_groups_structure
    validate :validate_results_structure
    validate :validate_timeline_structure

    def body_for_create
      build_campaign_payload
    end

    def self.get_results(id)
      response = get "#{resource_path}/#{id}/results"
      raise StandardError, "Campaign not found with id: #{id}" if response.response.code != '200'

      response.parsed_response
    end

    def self.get_summary(id)
      response = get "#{resource_path}/#{id}/summary"
      raise StandardError, "Campaign not found with id: #{id}" if response.response.code != '200'

      response.parsed_response
    end

    def self.complete(id)
      response = get "#{resource_path}/#{id}/complete"
      raise StandardError, "Campaign not found with id: #{id}" if response.response.code != '200'

      response.parsed_response
    end

    def get_results
      self.class.get_results id
    end

    def get_summary
      self.class.get_summary id
    end

    def complete!
      response = self.class.complete id
      self.status = 'Completed' if response['success']
      response
    end

    def in_progress?
      status == 'In progress'
    end

    def completed?
      status == 'Completed'
    end

    def launched?
      !launch_date.blank?
    end

    def has_send_by_date?
      !send_by_date.blank?
    end

    # Custom getters to return proper class instances
    def template
      convert_to_instance super, Gophish::Template
    end

    def page
      convert_to_instance super, Gophish::Page
    end

    def smtp
      convert_to_instance super, Gophish::Smtp
    end

    def groups
      convert_to_instances super, Gophish::Group
    end

    def results
      convert_to_instances super, Result
    end

    def timeline
      convert_to_instances super, Event
    end

    # Custom setters to handle both instances and hashes
    def template=(value)
      @template_raw = value
      super(convert_from_instance(value))
    end

    def page=(value)
      @page_raw = value
      super(convert_from_instance(value))
    end

    def smtp=(value)
      @smtp_raw = value
      super(convert_from_instance(value))
    end

    def groups=(value)
      @groups_raw = value
      super(convert_from_instances(value))
    end

    def results=(value)
      super(convert_from_instances(value))
    end

    def timeline=(value)
      super(convert_from_instances(value))
    end

    private

    def build_campaign_payload
      {
        name: name,
        template: serialize_object(@template_raw || template),
        page: serialize_object(@page_raw || page),
        groups: serialize_groups,
        smtp: serialize_object(@smtp_raw || smtp),
        url: url, launch_date: launch_date, send_by_date: send_by_date
      }
    end

    def serialize_object(obj)
      return obj if obj.is_a? Hash
      return { name: obj } if obj.is_a? String
      return { name: obj.name } if obj.respond_to? :name

      obj
    end

    def serialize_groups
      raw_groups = @groups_raw || groups
      return raw_groups if raw_groups.empty?

      raw_groups.map { |group| serialize_object group }
    end

    def validate_groups_structure
      return if groups.blank?
      return errors.add :groups, 'must be an array' unless groups.is_a? Array
      return errors.add :groups, 'cannot be empty' if groups.empty?

      groups.each_with_index { |group, index| validate_group group, index }
    end

    def validate_group(group, index)
      return if group.is_a?(Hash) && (group[:name] || group['name'])
      return if group.respond_to? :name

      errors.add :groups, "item at index #{index} must have a name"
    end

    def validate_results_structure
      return if results.blank?
      return errors.add :results, 'must be an array' unless results.is_a? Array

      results.each_with_index { |result, index| validate_result result, index }
    end

    def validate_result(result, index)
      return errors.add :results, "item at index #{index} must be a hash" unless result.is_a? Hash

      validate_result_field result, index, :email
    end

    def validate_timeline_structure
      return if timeline.blank?
      return errors.add :timeline, 'must be an array' unless timeline.is_a? Array

      timeline.each_with_index { |event, index| validate_timeline_event event, index }
    end

    def validate_timeline_event(event, index)
      return errors.add :timeline, "item at index #{index} must be a hash" unless event.is_a? Hash

      validate_event_field event, index, :time
      validate_event_field event, index, :message
    end

    def validate_result_field(result, index, field)
      value = result[field] || result[field.to_s]
      return unless value.blank?

      errors.add :results, "item at index #{index} must have a #{field}"
    end

    def validate_event_field(event, index, field)
      value = event[field] || event[field.to_s]
      return unless value.blank?

      errors.add :timeline, "item at index #{index} must have a #{field}"
    end

    # Helper methods for instance conversion
    def convert_to_instance(value, klass)
      return nil if value.nil?
      return value if value.is_a? klass
      return create_instance_safely value, klass if value.is_a? Hash

      value
    end

    def create_instance_safely(hash, klass)
      klass.new hash
    rescue ActiveModel::UnknownAttributeError
      # Filter out unknown attributes and try again
      known_attributes = klass.attribute_names.map(&:to_s)
      filtered_hash = hash.select { |k, _v| known_attributes.include? k.to_s }
      klass.new filtered_hash
    end

    def convert_to_instances(values, klass)
      return [] if values.blank?
      return values unless values.is_a? Array

      values.map { |value| convert_to_instance value, klass }
    end

    def convert_from_instance(value)
      return value if value.nil? || value.is_a?(Hash)

      value
    end

    def convert_from_instances(values)
      return values if values.blank?
      return values unless values.is_a? Array

      values
    end

    class Result
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :position, :string
      attribute :email, :string
      attribute :status, :string
      attribute :ip, :string
      attribute :latitude, :float
      attribute :longitude, :float
      attribute :send_date, :string
      attribute :reported, :boolean, default: false
      attribute :modified_date, :string

      def reported?
        reported == true
      end

      def clicked?
        status == 'Clicked Link'
      end

      def opened?
        status == 'Email Opened'
      end

      def sent?
        status == 'Email Sent'
      end

      def submitted_data?
        status == 'Submitted Data'
      end
    end

    class Event
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :email, :string
      attribute :time, :string
      attribute :message, :string
      attribute :details, :string

      def has_details?
        !details.blank?
      end

      def parsed_details
        return {} if details.blank?

        JSON.parse details
      rescue JSON::ParserError
        {}
      end
    end
  end
end
