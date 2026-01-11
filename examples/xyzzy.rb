#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo: Using MywayConfig for the Xyzzy application
#
# Run with different environments:
#   ruby examples/xyzzy.rb
#   RACK_ENV=production ruby examples/xyzzy.rb
#   RACK_ENV=test ruby examples/xyzzy.rb
#
# Override with environment variables:
#   XYZZY_DATABASE__HOST=custom-db.local ruby examples/xyzzy.rb
#   XYZZY_LOG_LEVEL=warn ruby examples/xyzzy.rb

require_relative '../lib/myway_config'

module Xyzzy
  # Configuration class - the YAML file is the single source of truth
  class Config < MywayConfig::Base
    config_name :xyzzy
    env_prefix  :xyzzy
    defaults_path File.expand_path('config/defaults.yml', __dir__)
    auto_configure!
  end

  class << self
    # Singleton access to configuration
    #
    # @return [Xyzzy::Config] the configuration instance
    def config
      @config ||= Config.new
    end

    # Reset the configuration (useful for testing)
    def reset_config!
      @config = nil
    end
  end
end

# Access via singleton
config = Xyzzy.config

puts <<~OUTPUT
  Xyzzy Configuration Demo
  ========================

  Environment: #{config.environment}
  Valid environment: #{config.valid_environment?}

  Database Configuration:
    Host: #{config.database.host}
    Port: #{config.database.port}
    Name: #{config.database.name}
    Pool: #{config.database.pool}
    Timeout: #{config.database.timeout}ms

  API Configuration:
    Base URL: #{config.api.base_url}
    Timeout: #{config.api.timeout}s
    Retries: #{config.api.retries}
    Headers:
      Content-Type: #{config.api.headers.content_type}
      Accept: #{config.api.headers.accept}

  Cache Configuration:
    Enabled: #{config.cache.enabled}
    TTL: #{config.cache.ttl}s
    Store: #{config.cache.store}

  Other Settings:
    Log Level: #{config.log_level.inspect}
    Debug: #{config.debug}
    Max Connections: #{config.max_connections}

  Environment Helpers:
    development? #{config.development?}
    production?  #{config.production?}
    test?        #{config.test?}

  Access Patterns (all equivalent):
    Xyzzy.config.database.host   = #{Xyzzy.config.database.host.inspect}
    Xyzzy.config.database[:host] = #{Xyzzy.config.database[:host].inspect}
    Xyzzy.config.database['host'] = #{Xyzzy.config.database['host'].inspect}

  Hash-like Behavior:
    database.keys     = #{config.database.keys.inspect}
    database.values   = #{config.database.values.inspect}
    database.size     = #{config.database.size}
    database.fetch(:host) = #{config.database.fetch(:host).inspect}
    database.fetch(:missing, 'default') = #{config.database.fetch(:missing, 'default').inspect}
    database.dig(:host) = #{config.database.dig(:host).inspect}
    config.dig(:api, :headers, :content_type) = #{config.api.dig(:headers, :content_type).inspect}

  Enumerable Methods:
    database.map { |k, v| k } = #{config.database.map { |k, v| k }.inspect}
    database.select { |k, v| v.is_a?(Integer) } = #{config.database.select { |k, v| v.is_a?(Integer) }.inspect}

  Converting to Hash:
    #{config.database.to_h.inspect}
OUTPUT
