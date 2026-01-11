# Basic Usage

Step-by-step guide to using MywayConfig.

## Step 1: Create the Defaults File

Create your configuration YAML file with a `defaults:` section:

```yaml
# config/defaults.yml
defaults:
  database:
    host: localhost
    port: 5432
    name: myapp_development
    pool: 5

  api:
    base_url: https://api.example.com
    timeout: 30
    headers:
      content_type: application/json

  log_level: :info
  debug: false

development:
  debug: true

production:
  database:
    host: prod-db.example.com
    pool: 20
  log_level: :warn

test:
  database:
    name: myapp_test
```

## Step 2: Define the Configuration Class

```ruby
# lib/myapp/config.rb
require 'myway_config'

module MyApp
  class Config < MywayConfig::Base
    config_name :myapp
    env_prefix  :myapp
    defaults_path File.expand_path("../../config/defaults.yml", __dir__)
    auto_configure!
  end
end
```

## Step 3: Access Configuration

### Basic Access

```ruby
config = MyApp::Config.new

# Top-level values
config.log_level  # => :info
config.debug      # => false

# Nested values
config.database.host  # => "localhost"
config.database.port  # => 5432
config.api.timeout    # => 30
```

### Environment Methods

```ruby
config.environment    # => "development"
config.development?   # => true
config.production?    # => false
config.test?          # => false
```

### Multiple Access Styles

```ruby
# All equivalent
config.database.host        # Method syntax
config.database[:host]      # Symbol bracket
config.database["host"]     # String bracket
```

## Step 4: Override with Environment Variables

```bash
# Override database host
MYAPP_DATABASE__HOST=custom-db.local ruby app.rb

# Override log level
MYAPP_LOG_LEVEL=debug ruby app.rb

# Multiple overrides
MYAPP_DATABASE__HOST=prod-db.local MYAPP_DATABASE__PORT=5433 ruby app.rb
```

## Step 5: Singleton Pattern (Recommended)

Create a module-level accessor:

```ruby
# lib/myapp.rb
require_relative 'myapp/config'

module MyApp
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

Usage:

```ruby
require 'myapp'

MyApp.config.database.host
MyApp.config.api.base_url
```

## Complete Example

```ruby
#!/usr/bin/env ruby
require 'myway_config'

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
  end
end

# Use the configuration
config = MyApp.config

puts "Environment: #{config.environment}"
puts "Database: #{config.database.host}:#{config.database.port}"
puts "Debug mode: #{config.debug}"

# Hash-like iteration
config.database.each do |key, value|
  puts "  #{key}: #{value}"
end
```

## Next Steps

- [Standalone Application](standalone-app.md) - Configuration for gems and CLI apps
- [Rails Integration](rails-integration.md) - Using with Rails

