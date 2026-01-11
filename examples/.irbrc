# IRB configuration for playing with Xyzzy config
# Usage: cd examples && irb

require_relative '../lib/myway_config'

module Xyzzy
  class Config < MywayConfig::Base
    config_name :xyzzy
    env_prefix  :xyzzy
    defaults_path File.expand_path('config/defaults.yml', __dir__)
    auto_configure!
  end

  class << self
    def config
      @config ||= Config.new
    end

    def reset_config!
      @config = nil
    end
  end
end

puts <<~BANNER
  Xyzzy Configuration loaded!
  Environment: #{Xyzzy.config.environment}

  Try:
    Xyzzy.config.database.host
    Xyzzy.config.database[:host]
    Xyzzy.config.database['host']
    Xyzzy.config.database.keys
    Xyzzy.config.database.to_h
    Xyzzy.config.api.headers.content_type
    Xyzzy.config.log_level

BANNER
