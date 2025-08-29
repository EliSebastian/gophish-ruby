require 'httparty'
require 'active_support'
require 'active_model'
require 'active_record'
require 'json'
require 'uri'

require_relative 'configuration'
module Gophish
  class Base
    include HTTParty
    include ActiveSupport::Inflector
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include ActiveRecord::Callbacks

    def initialize(attributes = {})
      @persisted = false
      @changed_attributes = {}
      super(attributes)
    end

    def self.configuration
      @configuration ||= {
        base_uri: "#{Gophish.configuration.url}/api",
        headers: { 'Authorization' => Gophish.configuration.api_key },
        verify: Gophish.configuration.verify_ssl,
        debug_output: Gophish.configuration.debug_output ? STDOUT : nil
      }
    end

    def self.get(path, options = {})
      options = configuration.merge options
      options[:headers] = (options[:headers] || {}).merge(configuration[:headers])
      super(path, options)
    end

    def self.post(path, options = {})
      options = configuration.merge options
      options[:headers] = (options[:headers] || {}).merge(configuration[:headers])
      super(path, options)
    end

    def self.put(path, options = {})
      options = configuration.merge options
      options[:headers] = (options[:headers] || {}).merge(configuration[:headers])
      super(path, options)
    end

    def self.delete(path, options = {})
      options = configuration.merge options
      options[:headers] = (options[:headers] || {}).merge(configuration[:headers])
      super(path, options)
    end

    def self.resource_name
    name.split('::').last.underscore.dasherize
    end

    def self.resource_path
      "/#{resource_name.pluralize}"
    end

    def self.all
      response = get "#{resource_path}/"
      if response.response.code == '200'
        response.parsed_response.map do |data|
          instance = new filter_attributes(data)
          instance.instance_variable_set :@persisted, true
          instance
        end
      end
    end

    def self.find(id)
      response = get "#{resource_path}/#{id}"
      raise StandardError, "Resource not found with id: #{id}" if response.response.code != '200'

      data = JSON.parse response.body
      instance = new filter_attributes(data)
      instance.instance_variable_set :@persisted, true
      instance
    end

    def save
      return false unless valid?

      return update_record if persisted?

      create_record
    end

    def update_attributes(attributes)
      attributes.each { |key, value| send "#{key}=", value if respond_to? "#{key}=" }
      save
    end

    def destroy
      return false unless persisted?
      return false if id.nil?

      response = self.class.delete "#{self.class.resource_path}/#{id}"
      return handle_error_response response unless response.success?

      @persisted = false
      freeze
      true
    end

    def persisted?
      @persisted && !id.nil?
    end

    def new_record?
      !persisted?
    end

    private

    def update_attributes_from_response(parsed_response)
      return unless parsed_response.is_a? Hash

      parsed_response.each do |key, value|
        send "#{key}=", value if respond_to? "#{key}="
      end
      @persisted = true
      @changed_attributes.clear
    end

    def handle_error_response(response)
      errors.add :base, response.parsed_response['message'] if response.parsed_response['success'] == false
      false
    end

    private

    def create_record
      response = self.class.post "#{self.class.resource_path}/", request_options(body_for_create)
      return handle_error_response response unless response.success?

      update_attributes_from_response response.parsed_response
      true
    end

    def update_record
      return false if id.nil?
      return true if @changed_attributes.empty?

      response = self.class.put "#{self.class.resource_path}/#{id}/", request_options(body_for_update)
      return handle_error_response response unless response.success?

      update_attributes_from_response response.parsed_response
      true
    end

    def request_options(body)
      { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
    end

    def self.filter_attributes(data)
      return data unless data.is_a? Hash

      defined_attributes = attribute_names.map(&:to_s)

      filtered_data = {}
      data.each do |key, value|
        snake_case_key = key.to_s.underscore
        filtered_data[snake_case_key] = value if defined_attributes.include? snake_case_key
      end

      filtered_data
    end

    def body_for_create
      raise NotImplementedError, 'You must implement the body_for_create method in your subclass'
    end

    def body_for_update
      body_for_create
    end

    def attribute_changed?(attribute)
      @changed_attributes.key? attribute.to_s
    end

    def changed_attributes
      @changed_attributes.keys
    end

    def attribute_was(attribute)
      @changed_attributes[attribute.to_s]
    end

    def []=(attribute, value)
      attribute_str = attribute.to_s
      current_value = send attribute if respond_to? attribute

      unless current_value == value
        @changed_attributes[attribute_str] = current_value
      end

      send "#{attribute}=", value if respond_to? "#{attribute}="
    end
  end
end
