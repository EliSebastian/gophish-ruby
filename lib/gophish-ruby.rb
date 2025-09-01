require_relative 'gophish/version'
require_relative 'gophish/configuration'
require_relative 'gophish/group'
require_relative 'gophish/template'
require_relative 'gophish/page'
require_relative 'gophish/smtp'

module Gophish
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
