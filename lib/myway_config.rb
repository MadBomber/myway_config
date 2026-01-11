# frozen_string_literal: true

require 'anyway_config'

require_relative 'myway_config/version'
require_relative 'myway_config/config_section'
require_relative 'myway_config/loaders/defaults_loader'
require_relative 'myway_config/loaders/xdg_config_loader'
require_relative 'myway_config/base'

module MywayConfig
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ValidationError < Error; end

  class << self
    # Register the XDG and defaults loaders with Anyway Config
    #
    # Call this method after requiring myway_config to enable
    # XDG config file loading and bundled defaults.
    #
    # The loader order determines priority (lowest to highest):
    # 1. Bundled defaults (DefaultsLoader)
    # 2. XDG user config (XdgConfigLoader)
    # 3. Project config (:yml loader - Anyway default)
    # 4. Environment variables (:env loader - Anyway default)
    #
    def setup!
      return if @setup_complete

      # Insert loaders before :yml so they have lower priority
      # Bundled defaults first (lowest priority)
      unless loader_registered?(:bundled_defaults)
        Anyway.loaders.insert_before :yml, :bundled_defaults, Loaders::DefaultsLoader
      end

      # XDG config second (higher priority than bundled defaults)
      unless loader_registered?(:xdg)
        Anyway.loaders.insert_before :yml, :xdg, Loaders::XdgConfigLoader
      end

      @setup_complete = true
    end

    # Check if setup has been completed
    #
    # @return [Boolean]
    def setup?
      @setup_complete || false
    end

    # Reset setup state (mainly for testing)
    def reset!
      @setup_complete = false
    end

    private

    def loader_registered?(name)
      Anyway.loaders.registry.any? { |entry| entry.first == name }
    end
  end
end

# Auto-setup when the gem is loaded
MywayConfig.setup!
