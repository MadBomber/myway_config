# Defining Configuration

This guide explains how to create and configure your config class.

## Basic Definition

The minimal config class requires four things:

```ruby
class MyApp::Config < MywayConfig::Base
  config_name :myapp           # Used for file names and loader registration
  env_prefix  :myapp           # Prefix for environment variables
  defaults_path File.expand_path("config/defaults.yml", __dir__)
  auto_configure!              # Auto-generate attributes from YAML
end
```

## Class Methods

### `config_name`

Sets the configuration name used for:

- Finding config files (`config/myapp.yml`)
- XDG config path (`~/.config/myapp/config.yml`)
- Loader registration

```ruby
config_name :myapp
```

### `env_prefix`

Sets the prefix for environment variables:

```ruby
env_prefix :myapp
# Allows: MYAPP_DATABASE__HOST, MYAPP_LOG_LEVEL, etc.
```

### `defaults_path`

Registers the path to your defaults YAML file:

```ruby
defaults_path File.expand_path("config/defaults.yml", __dir__)
```

!!! warning "File Must Exist"
    The defaults file must exist when the class is loaded. A `ConfigurationError` is raised if the file is not found.

### `auto_configure!`

Automatically generates `attr_config` declarations and type coercions from your YAML schema:

```ruby
auto_configure!
```

This method:

- Creates an attribute for each key in the `defaults:` section
- Coerces Hash values to `ConfigSection` objects
- Coerces Symbol values to symbols

## Manual Configuration

For custom coercions or special handling, configure manually:

```ruby
class MyApp::Config < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp
  defaults_path File.expand_path("config/defaults.yml", __dir__)

  # Manually declare attributes
  attr_config :database, :api, :log_level

  # Custom coercions
  coerce_types(
    database: config_section_coercion(:database),
    api: config_section_coercion(:api),
    log_level: ->(v) { v.to_s.upcase.to_sym }  # Custom: uppercase symbols
  )
end
```

## Singleton Pattern

It's common to provide a singleton accessor:

```ruby
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

# Usage
MyApp.config.database.host
```

## Instance Methods

All config instances have these helper methods:

```ruby
config = MyApp::Config.new

config.environment        # => "development"
config.development?       # => true
config.production?        # => false
config.test?              # => false
config.valid_environment? # => true (if environment exists in YAML)
```

## Next Steps

- [YAML Structure](yaml-structure.md) - Learn about the defaults file format
- [Accessing Values](accessing-values.md) - How to read configuration values
