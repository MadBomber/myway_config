# Quick Start

This guide will walk you through creating your first MywayConfig configuration in 5 minutes.

## Step 1: Create Your Defaults File

The YAML file is the single source of truth for your configuration structure and default values.

Create `lib/myapp/config/defaults.yml`:

```yaml
defaults:
  database:
    host: localhost
    port: 5432
    name: myapp_db
    pool: 5
  api:
    base_url: https://api.example.com
    timeout: 30
  log_level: :info
  debug: false

development:
  database:
    name: myapp_development
  log_level: :debug
  debug: true

production:
  database:
    host: prod-db.example.com
    pool: 25
  log_level: :warn

test:
  database:
    name: myapp_test
  log_level: :debug
```

## Step 2: Define Your Config Class

Create `lib/myapp/config.rb`:

```ruby
require "myway_config"

module MyApp
  class Config < MywayConfig::Base
    config_name :myapp
    env_prefix  :myapp
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

That's it! The `auto_configure!` method reads your YAML and sets up everything automatically.

## Step 3: Use Your Configuration

```ruby
require "myapp/config"

# Access nested values with method syntax
MyApp.config.database.host      # => "localhost"
MyApp.config.database.port      # => 5432
MyApp.config.api.timeout        # => 30
MyApp.config.log_level          # => :info

# Environment helpers
MyApp.config.development?       # => true (when RACK_ENV=development)
MyApp.config.production?        # => false
MyApp.config.environment        # => "development"
```

## Step 4: Override with Environment Variables

You can override any value using environment variables:

```bash
# Scalar values
export MYAPP_LOG_LEVEL=warn

# Nested values (use double underscore)
export MYAPP_DATABASE__HOST=custom-db.local
export MYAPP_DATABASE__PORT=5433

# Run your app
ruby myapp.rb
```

## What's Next?

- [Defining Configuration](../guides/defining-configuration.md) - Learn about config class options
- [YAML Structure](../guides/yaml-structure.md) - Understand the YAML file format
- [Accessing Values](../guides/accessing-values.md) - All the ways to access config
- [Examples](../examples/index.md) - Real-world usage examples
