# frozen_string_literal: true

require_relative "lib/myway_config/version"

Gem::Specification.new do |spec|
  spec.name = "myway_config"
  spec.version = MywayConfig::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dewayne@vanhoozer.me"]

  spec.summary = "Configuration management extending anyway_config with XDG support and auto-configuration"
  spec.description = "MywayConfig extends anyway_config with XDG config file loading, bundled defaults, " \
                     "and auto-configuration from YAML. Define your config structure once in YAML and " \
                     "access values using method syntax, bracket notation, or Hash-like enumeration."
  spec.homepage = "https://github.com/madbomber/myway_config"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/madbomber/myway_config"
  spec.metadata["changelog_uri"] = "https://github.com/madbomber/myway_config/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ examples/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "anyway_config", ">= 2.0"
end
