# frozen_string_literal: true

require 'anyway_config'
require 'yaml'

module MywayConfig
  module Loaders
    # Bundled Defaults Loader for Anyway Config
    #
    # Loads default configuration values from a YAML file bundled with a gem.
    # This ensures defaults are always available regardless of where the gem is installed.
    #
    # The defaults.yml file structure:
    #   defaults:      # Base values for all environments
    #     database:
    #       host: localhost
    #       port: 5432
    #   development:   # Overrides for development
    #     database:
    #       name: myapp_development
    #   test:          # Overrides for test
    #     database:
    #       name: myapp_test
    #   production:    # Overrides for production
    #     database:
    #       sslmode: require
    #
    # This loader deep-merges `defaults` with the current environment's overrides.
    #
    # Loading priority (lowest to highest):
    # 1. Bundled defaults (this loader)
    # 2. XDG user config (~/.config/app/app.yml)
    # 3. Project config (./config/app.yml)
    # 4. Local overrides (./config/app.local.yml)
    # 5. Environment variables (APP_*)
    # 6. Programmatic (configure block)
    #
    class DefaultsLoader < Anyway::Loaders::Base
      # Registry of defaults paths keyed by config name
      @defaults_paths = {}

      class << self
        attr_reader :defaults_paths

        # Register a defaults file path for a config name
        #
        # @param name [Symbol, String] the config name
        # @param path [String] absolute path to the defaults.yml file
        def register(name, path)
          @defaults_paths[name.to_sym] = path
        end

        # Get the registered defaults path for a config name
        #
        # @param name [Symbol, String] the config name
        # @return [String, nil] the path or nil if not registered
        def defaults_path(name)
          @defaults_paths[name.to_sym]
        end

        # Check if defaults file exists for a config name
        #
        # @param name [Symbol, String] the config name
        # @return [Boolean]
        def defaults_exist?(name)
          path = defaults_path(name)
          path && File.exist?(path)
        end

        # Load and parse the raw YAML content
        #
        # @param name [Symbol, String] the config name
        # @return [Hash] parsed YAML with symbolized keys
        def load_raw_yaml(name)
          path = defaults_path(name)
          return {} unless path && File.exist?(path)

          content = File.read(path)
          YAML.safe_load(
            content,
            permitted_classes: [Symbol],
            symbolize_names: true,
            aliases: true
          ) || {}
        rescue Psych::SyntaxError => e
          warn "MywayConfig: Failed to parse bundled defaults #{path}: #{e.message}"
          {}
        end

        # Extract the schema (attribute names) from the defaults section
        #
        # @param name [Symbol, String] the config name
        # @return [Hash] the defaults section containing all attribute definitions
        def schema(name)
          raw = load_raw_yaml(name)
          raw[:defaults] || {}
        end

        # Returns valid environment names from the config file
        #
        # Valid environments are top-level keys excluding 'defaults'.
        #
        # @param name [Symbol, String] the config name
        # @return [Array<Symbol>] list of valid environment names
        def valid_environments(name)
          raw = load_raw_yaml(name)
          raw.keys.reject { |k| k == :defaults }.sort
        end

        # Check if a given environment name is valid
        #
        # @param name [Symbol, String] the config name
        # @param env [String, Symbol] environment name to check
        # @return [Boolean] true if environment is valid
        def valid_environment?(name, env)
          return false if env.nil? || env.to_s.empty?
          return false if env.to_s == 'defaults'

          valid_environments(name).include?(env.to_sym)
        end
      end

      def call(name:, **_options)
        return {} unless self.class.defaults_exist?(name)

        path = self.class.defaults_path(name)
        trace!(:bundled_defaults, path: path) do
          load_and_merge_for_environment(name)
        end
      end

      private

      # Load defaults and deep merge with environment-specific overrides
      #
      # @param name [Symbol, String] the config name
      # @return [Hash] merged configuration for current environment
      def load_and_merge_for_environment(name)
        raw = self.class.load_raw_yaml(name)
        return {} if raw.empty?

        # Start with the defaults section
        defaults = raw[:defaults] || {}

        # Deep merge with environment-specific overrides
        env = current_environment
        env_overrides = raw[env.to_sym] || {}

        deep_merge(defaults, env_overrides)
      end

      # Deep merge two hashes, with overlay taking precedence
      #
      # @param base [Hash] base configuration
      # @param overlay [Hash] overlay configuration (takes precedence)
      # @return [Hash] merged result
      def deep_merge(base, overlay)
        base.merge(overlay) do |_key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end

      # Determine the current environment
      #
      # @return [String] current environment name
      def current_environment
        Anyway::Settings.current_environment ||
          ENV['RAILS_ENV'] ||
          ENV['RACK_ENV'] ||
          'development'
      end
    end
  end
end
