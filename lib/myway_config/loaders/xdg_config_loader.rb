# frozen_string_literal: true

require 'anyway_config'
require 'yaml'

module MywayConfig
  module Loaders
    # XDG Base Directory Specification loader for Anyway Config
    #
    # Loads configuration from XDG-compliant paths:
    # 1. $XDG_CONFIG_HOME/{app}/{app}.yml (if XDG_CONFIG_HOME is set)
    # 2. ~/.config/{app}/{app}.yml (XDG default fallback)
    #
    # On macOS, also checks:
    # 3. ~/Library/Application Support/{app}/{app}.yml
    #
    # This loader runs BEFORE the project-local config loader,
    # so project configs take precedence over user-global configs.
    #
    # @example XDG config file location
    #   ~/.config/myapp/myapp.yml
    #
    # @example Custom XDG_CONFIG_HOME
    #   export XDG_CONFIG_HOME=/my/config
    #   # Looks for /my/config/myapp/myapp.yml
    #
    class XdgConfigLoader < Anyway::Loaders::Base
      class << self
        # Returns all XDG config paths to check for a given app name
        #
        # @param name [String] the application name
        # @return [Array<String>] list of potential config directory paths
        def config_paths(name)
          paths = []

          # macOS Application Support (lowest priority for XDG loader)
          if macos?
            macos_path = File.expand_path("~/Library/Application Support/#{name}")
            paths << macos_path if Dir.exist?(File.dirname(macos_path))
          end

          # XDG default: ~/.config/{name}
          xdg_default = File.expand_path("~/.config/#{name}")
          paths << xdg_default

          # XDG_CONFIG_HOME override (highest priority for XDG loader)
          if ENV['XDG_CONFIG_HOME'] && !ENV['XDG_CONFIG_HOME'].empty?
            xdg_home = File.join(ENV['XDG_CONFIG_HOME'], name.to_s)
            paths << xdg_home unless xdg_home == xdg_default
          end

          paths
        end

        # Find the first existing config file for the given app name
        #
        # @param name [String] config name (e.g., 'myapp')
        # @return [String, nil] path to config file or nil if not found
        def find_config_file(name)
          config_paths(name).reverse_each do |dir|
            file = File.join(dir, "#{name}.yml")
            return file if File.exist?(file)
          end
          nil
        end

        private

        def macos?
          RUBY_PLATFORM.include?('darwin')
        end
      end

      def call(name:, **_options)
        config_file = self.class.find_config_file(name)
        return {} unless config_file

        trace!(:xdg, path: config_file) do
          load_yaml(config_file, name)
        end
      end

      private

      def load_yaml(path, name)
        return {} unless File.exist?(path)

        content = File.read(path)
        parsed = YAML.safe_load(
          content,
          permitted_classes: [Symbol],
          symbolize_names: true,
          aliases: true
        ) || {}

        env = current_environment

        # Check for environment key first, fall back to root level
        if parsed.key?(env.to_sym)
          parsed[env.to_sym] || {}
        elsif parsed.key?(env.to_s)
          parsed[env.to_s] || {}
        else
          # No environment key, treat as flat config
          parsed
        end
      rescue Psych::SyntaxError => e
        warn "MywayConfig: Failed to parse XDG config #{path}: #{e.message}"
        {}
      end

      def current_environment
        Anyway::Settings.current_environment ||
          ENV['RAILS_ENV'] ||
          ENV['RACK_ENV'] ||
          'development'
      end
    end
  end
end
