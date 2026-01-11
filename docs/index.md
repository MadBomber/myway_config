# MywayConfig

**Configuration management for Ruby applications with XDG support and auto-configuration from YAML.**

MywayConfig extends [anyway_config](https://github.com/palkan/anyway_config) with:

- **XDG config file loading** - Respects `~/.config/<app>/config.yml`
- **Bundled defaults** - Ship defaults with your gem
- **Auto-configuration** - Define structure once in YAML, access everywhere
- **Hash-like behavior** - `Enumerable` support for config sections

## Features

```yaml
# Define once in YAML
defaults:
  database:
    host: localhost
    port: 5432
  log_level: :info

production:
  database:
    host: prod-db.example.com
```

```ruby
# Access with clean Ruby syntax
config.database.host      # => "localhost"
config.database[:host]    # => "localhost"
config.database['host']   # => "localhost"
config.log_level          # => :info
```

## Quick Example

```ruby
require "myway_config"

module MyApp
  class Config < MywayConfig::Base
    config_name :myapp
    env_prefix  :myapp
    defaults_path File.expand_path("config/defaults.yml", __dir__)
    auto_configure!
  end

  def self.config
    @config ||= Config.new
  end
end

# Use it
MyApp.config.database.host
MyApp.config.production?
```

## Installation

```bash
gem install myway_config
```

Or add to your Gemfile:

```ruby
gem "myway_config"
```

## Configuration Priority

Values are loaded in priority order (lowest to highest):

1. Bundled defaults (`defaults.yml` - the `defaults:` section)
2. Environment overrides (`defaults.yml` - e.g., `production:` section)
3. XDG user config (`~/.config/<app>/config.yml`)
4. Project config (`./config/<app>.yml`)
5. Environment variables (`MYAPP_DATABASE__HOST=...`)
6. Constructor overrides

## Next Steps

- [Installation](getting-started/installation.md) - Get up and running
- [Quick Start](getting-started/quick-start.md) - Build your first config
- [Guides](guides/index.md) - Deep dive into features
- [API Reference](api/index.md) - Complete API documentation
