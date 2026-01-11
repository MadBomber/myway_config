# frozen_string_literal: true

require 'anyway_config'
require 'yaml'

module MywayConfig
  # Base configuration class that extends Anyway::Config with additional features
  #
  # Provides:
  # - ConfigSection coercion for nested configuration
  # - XDG config file loading
  # - Bundled defaults loading with environment overrides
  # - Environment detection helpers
  # - Deep merge utilities
  #
  # @example Define a configuration class (recommended)
  #   class MyApp::Config < MywayConfig::Base
  #     config_name :myapp
  #     env_prefix :myapp
  #     defaults_path File.expand_path('config/defaults.yml', __dir__)
  #     auto_configure!
  #   end
  #
  # @example Manual configuration (when custom coercions are needed)
  #   class MyApp::Config < MywayConfig::Base
  #     config_name :myapp
  #     env_prefix :myapp
  #     defaults_path File.expand_path('config/defaults.yml', __dir__)
  #
  #     attr_config :database, :api, :log_level
  #
  #     coerce_types(
  #       database: config_section_coercion(:database),
  #       api: config_section_coercion(:api),
  #       log_level: ->(v) { v.to_s.upcase.to_sym }
  #     )
  #   end
  #
  class Base < Anyway::Config
    class << self
      # Register a defaults file path for this config class
      #
      # @param path [String] absolute path to the defaults.yml file
      # @raise [ConfigurationError] if the file does not exist
      def defaults_path(path = nil)
        if path
          raise ConfigurationError, "Defaults file not found: #{path}" unless File.exist?(path)
          @defaults_path = path
          # Register with the loader
          MywayConfig::Loaders::DefaultsLoader.register(config_name, path)
        end
        @defaults_path
      end

      # Load and cache the schema from defaults file
      #
      # @return [Hash] the defaults section from the YAML file
      def schema
        @schema ||= begin
          return {} unless @defaults_path && File.exist?(@defaults_path)

          content = File.read(@defaults_path)
          raw = YAML.safe_load(
            content,
            permitted_classes: [Symbol],
            symbolize_names: true,
            aliases: true
          ) || {}
          raw[:defaults] || {}
        end
      end

      # Create a coercion that merges incoming value with schema defaults for a section
      #
      # This ensures environment variables don't lose other defaults.
      #
      # @param section_key [Symbol] the section key in the schema
      # @return [Proc] coercion proc for use with coerce_types
      def config_section_coercion(section_key)
        defaults = schema[section_key] || {}
        ->(v) {
          return v if v.is_a?(MywayConfig::ConfigSection)

          incoming = v || {}
          # Deep merge: defaults first, then overlay incoming values
          merged = deep_merge_hashes(defaults.dup, incoming)
          MywayConfig::ConfigSection.new(merged)
        }
      end

      # Simple ConfigSection coercion without schema defaults
      #
      # @return [Proc] coercion proc for use with coerce_types
      def config_section
        ->(v) {
          return v if v.is_a?(MywayConfig::ConfigSection)
          MywayConfig::ConfigSection.new(v || {})
        }
      end

      # Symbol coercion helper
      #
      # @return [Proc] coercion proc that converts to symbol
      def to_symbol
        ->(v) { v.nil? ? nil : v.to_s.to_sym }
      end

      # Deep merge helper for coercion
      #
      # @param base [Hash] base hash
      # @param overlay [Hash] overlay hash (takes precedence)
      # @return [Hash] merged hash
      def deep_merge_hashes(base, overlay)
        base.merge(overlay) do |_key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge_hashes(old_val, new_val)
          else
            new_val.nil? ? old_val : new_val
          end
        end
      end

      # Get the current environment
      #
      # Override this method to customize environment detection.
      # Default priority: RAILS_ENV > RACK_ENV > 'development'
      #
      # @return [String] current environment name
      def env
        Anyway::Settings.current_environment ||
          ENV['RAILS_ENV'] ||
          ENV['RACK_ENV'] ||
          'development'
      end

      # Returns list of valid environment names from bundled defaults
      #
      # @return [Array<Symbol>] valid environment names
      def valid_environments
        MywayConfig::Loaders::DefaultsLoader.valid_environments(config_name)
      end

      # Check if current environment is valid
      #
      # @return [Boolean] true if environment has a config section
      def valid_environment?
        MywayConfig::Loaders::DefaultsLoader.valid_environment?(config_name, env)
      end

      # Auto-configure attributes and coercions from the YAML schema
      #
      # This method reads the defaults section from the YAML file and
      # automatically generates attr_config declarations and coercions.
      # Hash values become ConfigSection objects with method-style access.
      #
      # @example Minimal config class
      #   class Xyzzy::Config < MywayConfig::Base
      #     config_name :xyzzy
      #     env_prefix  :xyzzy
      #     defaults_path File.expand_path('config/defaults.yml', __dir__)
      #     auto_configure!
      #   end
      #
      def auto_configure!
        raise ConfigurationError, 'defaults_path must be set before auto_configure!' unless @defaults_path

        coercions = {}

        schema.each do |key, value|
          attr_config key

          coercions[key] = if value.is_a?(Hash)
                             config_section_coercion(key)
                           elsif value.is_a?(Symbol)
                             to_symbol
                           end
        end

        coerce_types(coercions.compact)
      end
    end

    # ==========================================================================
    # Instance Methods
    # ==========================================================================

    # Initialize configuration from defaults, a file path, or a Hash
    #
    # @param source [nil, String, Pathname, Hash] configuration source
    #   - nil: use defaults and environment overrides
    #   - String/Pathname: path to a YAML config file
    #   - Hash: direct configuration overrides
    #
    # @example Standard usage (defaults + environment)
    #   config = MyConfig.new
    #
    # @example Load from a custom file path
    #   config = MyConfig.new('/path/to/custom.yml')
    #   config = MyConfig.new(Pathname.new('/path/to/custom.yml'))
    #
    # @example With Hash overrides
    #   config = MyConfig.new(database: { host: 'custom.local' })
    #
    def initialize(source = nil)
      overrides = case source
                  when String, Pathname
                    load_from_file(source.to_s)
                  when Hash
                    source
                  when nil
                    nil
                  else
                    raise ConfigurationError, "Invalid source: expected String, Pathname, Hash, or nil"
                  end

      super(overrides)
    end

    private

    def load_from_file(path)
      raise ConfigurationError, "Config file not found: #{path}" unless File.exist?(path)

      content = File.read(path)
      raw = YAML.safe_load(
        content,
        permitted_classes: [Symbol],
        symbolize_names: true,
        aliases: true
      ) || {}

      environment = self.class.env

      if raw.key?(:defaults)
        base = raw[:defaults] || {}
        env_key = environment.to_sym
        env_overrides = raw[env_key] || {}
        self.class.deep_merge_hashes(base, env_overrides)
      else
        raw
      end
    end

    public

    # Check if running in test environment
    #
    # @return [Boolean]
    def test?
      self.class.env == 'test'
    end

    # Check if running in development environment
    #
    # @return [Boolean]
    def development?
      self.class.env == 'development'
    end

    # Check if running in production environment
    #
    # @return [Boolean]
    def production?
      self.class.env == 'production'
    end

    # Get the current environment name
    #
    # @return [String]
    def environment
      self.class.env
    end

    # Check if environment is valid
    #
    # @return [Boolean]
    def valid_environment?
      self.class.valid_environment?
    end
  end
end
