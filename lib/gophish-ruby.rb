require_relative 'gophish/version'
require_relative 'gophish/configuration'
require_relative 'gophish/base'
require_relative 'gophish/group'


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
