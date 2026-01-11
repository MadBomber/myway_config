# Examples

Real-world examples of using MywayConfig in different contexts.

## Examples

### [Basic Usage](basic-usage.md)

Simple configuration patterns for any Ruby application.

- Defining a configuration class
- Accessing configuration values
- Environment-specific settings

### [Standalone Application](standalone-app.md)

Using MywayConfig in non-Rails Ruby applications.

- Setting up configuration for gems
- CLI applications
- Background workers

### [Rails Integration](rails-integration.md)

Integrating MywayConfig with Rails applications.

- Initializer setup
- Environment detection
- Credentials integration

## Quick Example

```ruby
# config/defaults.yml
# defaults:
#   database:
#     host: localhost
#     port: 5432

class MyApp::Config < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp
  defaults_path File.expand_path("config/defaults.yml", __dir__)
  auto_configure!
end

# Access configuration
config = MyApp::Config.new
config.database.host  # => "localhost"
```

## Common Patterns

### Singleton Access

```ruby
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

# Usage
MyApp.config.database.host
```

### Test Overrides

```ruby
def with_config(overrides, &block)
  original = MyApp.config
  MyApp.instance_variable_set(:@config, MyApp::Config.new(overrides))
  yield
ensure
  MyApp.instance_variable_set(:@config, original)
end

# In tests
with_config(database: { host: "test-db" }) do
  assert_equal "test-db", MyApp.config.database.host
end
```

### Environment Detection

```ruby
config = MyApp::Config.new

if config.production?
  # Production-specific logic
elsif config.development?
  # Development-specific logic
end
```

