require_relative 'base'
require 'active_support/core_ext/object/blank'

module Gophish
  class Page < Base
    attribute :id, :integer
    attribute :name, :string
    attribute :html, :string
    attribute :capture_credentials, :boolean, default: false
    attribute :capture_passwords, :boolean, default: false
    attribute :modified_date, :string
    attribute :redirect_url, :string

    define_attribute_methods :id, :name, :html, :capture_credentials, :capture_passwords, :modified_date, :redirect_url

    validates :name, presence: true
    validates :html, presence: true

    def body_for_create
      {
        name:,
        html:,
        capture_credentials:,
        capture_passwords:,
        redirect_url:
      }
    end

    def self.import_site(url, include_resources: false)
      options = build_import_options url, include_resources
      response = post '/import/site', options
      raise StandardError, 'Failed to import site' unless response.success?

      response.parsed_response
    end

    def self.build_import_options(url, include_resources)
      {
        body: { url:, include_resources: }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    def captures_credentials?
      capture_credentials == true
    end

    def captures_passwords?
      capture_passwords == true
    end

    def has_redirect?
      !redirect_url.blank?
    end
  end
end
