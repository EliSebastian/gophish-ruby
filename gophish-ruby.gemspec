# frozen_string_literal: true

require_relative "lib/gophish_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "gophish-ruby"
  spec.version = GophishRuby::VERSION
  spec.authors = ["Eli Sebastian Herrera Aguilar"]
  spec.email = ["esrbastianherrera@gmail.com"]

  spec.summary = "Gophish Ruby SDK"
  spec.description = "A Ruby SDK for Gophish API"
  spec.homepage = "https://github.com/EliSebastian/gopish-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/EliSebastian/gopish-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/EliSebastian/gopish-ruby/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename __FILE__
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'httparty', '~> 0.23.1'
  spec.add_dependency 'activesupport', '~> 8.0', '>= 8.0.2.1'
  spec.add_dependency 'activemodel', '~> 8.0', '>= 8.0.2.1'
  spec.add_dependency 'activerecord', '~> 8.0', '>= 8.0.2.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
