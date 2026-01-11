# MywayConfig

Configuration management for Ruby applications. Extends [anyway_config](https://github.com/palkan/anyway_config) with XDG config file loading, bundled defaults, and auto-configuration from YAML.

## Installation

Add to your Gemfile:

```ruby
gem "myway_config"
```

## Quick Start

### 1. Create your defaults file

The YAML file is the single source of truth for configuration structure and defaults.

```yaml
# lib/xyzzy/config/defaults.yml

defaults:
  database:
    host: localhost
    port: 5432
    name: xyzzy_db
    pool: 5
  api:
    base_url: https://api.example.com
    timeout: 30
  log_level: :info
  debug: false

development:
  database:
    name: xyzzy_development
  log_level: :debug
  debug: true

production:
  database:
    host: prod-db.example.com
    pool: 25
  log_level: :warn

test:
  database:
    name: xyzzy_test
  log_level: :debug
```

### 2. Define your config class

```ruby
# lib/xyzzy/config.rb

require "myway_config"

module Xyzzy
  class Config < MywayConfig::Base
    config_name :xyzzy
    env_prefix  :xyzzy
    defaults_path File.expand_path("config/defaults.yml", __dir__)
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
```

### 3. Use it

```ruby
# Access configuration
Xyzzy.config.database.host      # => "localhost"
Xyzzy.config.database.port      # => 5432
Xyzzy.config.api.timeout        # => 30
Xyzzy.config.log_level          # => :info

# Environment helpers
Xyzzy.config.development?       # => true
Xyzzy.config.production?        # => false
Xyzzy.config.environment        # => "development"
```

## Access Patterns

ConfigSection supports multiple access styles:

```ruby
# Method access
Xyzzy.config.database.host      # => "localhost"

# Symbol bracket access
Xyzzy.config.database[:host]    # => "localhost"

# String bracket access
Xyzzy.config.database["host"]   # => "localhost"
```

## Hash-like Behavior

ConfigSection includes `Enumerable` and provides Hash-like methods:

```ruby
config.database.keys            # => [:host, :port, :name, :pool]
config.database.values          # => ["localhost", 5432, "xyzzy_db", 5]
config.database.size            # => 4
config.database.to_h            # => {host: "localhost", port: 5432, ...}

# Fetch with default
config.database.fetch(:host)                    # => "localhost"
config.database.fetch(:missing, "default")      # => "default"

# Dig into nested values
config.api.dig(:headers, :content_type)         # => "application/json"

# Enumerable methods
config.database.map { |k, v| "#{k}=#{v}" }
config.database.select { |k, v| v.is_a?(Integer) }
config.database.any? { |k, v| v.nil? }
```

## Loading from Custom Files

Load configuration from a non-standard location:

```ruby
# From a file path (String or Pathname)
config = Xyzzy::Config.new("/path/to/custom.yml")
config = Xyzzy::Config.new(Pathname.new("/etc/myapp/config.yml"))

# Environment is determined by RACK_ENV / RAILS_ENV
RACK_ENV=production ruby -e "config = Xyzzy::Config.new('/path/to/config.yml')"
```

## Loading from a Hash

Pass configuration directly as a Hash:

```ruby
config = Xyzzy::Config.new(
  database: { host: "custom.local", port: 5433 },
  log_level: :debug,
  timeout: 120
)
```

## Configuration Sources

Values are loaded in priority order (lowest to highest):

1. Bundled defaults (`defaults.yml` - the `defaults:` section)
2. Environment overrides (`defaults.yml` - e.g., `production:` section)
3. XDG user config (`~/.config/<app>/config.yml`)
4. Project config (`./config/<app>.yml`)
5. Environment variables (`XYZZY_DATABASE__HOST=...`)
6. Constructor overrides

## Environment Variables

Override any config value via environment variables:

```bash
# Scalar values
XYZZY_LOG_LEVEL=warn

# Nested values (use double underscore)
XYZZY_DATABASE__HOST=custom-db.local
XYZZY_DATABASE__PORT=5433

# Run with overrides
XYZZY_DATABASE__HOST=prod.example.com ruby app.rb
```

## YAML File Structure

The defaults file requires a `defaults` key. Other top-level keys are environment names:

```yaml
defaults:           # Required - defines structure and default values
  key: value

development:        # Optional - overrides for development
  key: dev_value

production:         # Optional - overrides for production
  key: prod_value

test:               # Optional - overrides for test
  key: test_value

staging:            # Optional - any environment name works
  key: staging_value
```

## Manual Configuration

For custom coercions, configure manually instead of using `auto_configure!`:

```ruby
class MyConfig < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp
  defaults_path File.expand_path("config/defaults.yml", __dir__)

  attr_config :database, :api, :log_level

  coerce_types(
    database: config_section_coercion(:database),
    api: config_section_coercion(:api),
    log_level: ->(v) { v.to_s.upcase.to_sym }
  )
end
```

## Development

```bash
bin/setup          # Install dependencies
rake test          # Run tests
bin/console        # Interactive prompt
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
