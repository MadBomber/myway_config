# Loaders

MywayConfig provides custom loaders that extend Anyway Config's loading system.

## Loading Priority

Configuration values are loaded in order (lowest to highest priority):

1. **DefaultsLoader** - Bundled defaults from your gem
2. **XdgConfigLoader** - User's XDG config files
3. **Anyway Config loaders** - Project config, local overrides
4. **Environment variables** - `PREFIX_KEY=value`
5. **Constructor overrides** - Hash passed to `new`

Higher priority sources override lower priority values.

---

## DefaultsLoader

Loads bundled default configuration from a YAML file.

### Purpose

Ensures default values are always available regardless of where the gem is installed. The defaults file is the single source of truth for configuration structure.

### Registration

```ruby
class MyApp::Config < MywayConfig::Base
  config_name :myapp
  defaults_path File.expand_path("config/defaults.yml", __dir__)
end
```

### Class Methods

#### register

Register a defaults file path.

```ruby
MywayConfig::Loaders::DefaultsLoader.register(:myapp, "/path/to/defaults.yml")
```

---

#### defaults_path

Get the registered path for a config name.

```ruby
MywayConfig::Loaders::DefaultsLoader.defaults_path(:myapp)
# => "/path/to/defaults.yml"
```

---

#### defaults_exist?

Check if defaults file exists.

```ruby
MywayConfig::Loaders::DefaultsLoader.defaults_exist?(:myapp)
# => true
```

---

#### schema

Get the defaults section from the YAML file.

```ruby
MywayConfig::Loaders::DefaultsLoader.schema(:myapp)
# => {database: {host: "localhost", ...}, log_level: :info, ...}
```

---

#### valid_environments

Get list of valid environment names.

```ruby
MywayConfig::Loaders::DefaultsLoader.valid_environments(:myapp)
# => [:development, :production, :test]
```

---

#### valid_environment?

Check if an environment name is valid.

```ruby
MywayConfig::Loaders::DefaultsLoader.valid_environment?(:myapp, :production)
# => true

MywayConfig::Loaders::DefaultsLoader.valid_environment?(:myapp, :staging)
# => false
```

---

### Loading Behavior

The loader:

1. Reads the `defaults:` section as base values
2. Deep-merges current environment's overrides
3. Returns the merged configuration

```yaml
# defaults.yml
defaults:
  database:
    host: localhost
    port: 5432

production:
  database:
    host: prod-db.example.com
```

In production, the loader returns:

```ruby
{database: {host: "prod-db.example.com", port: 5432}}
```

---

## XdgConfigLoader

Loads user configuration from XDG Base Directory paths.

### Purpose

Allows users to override configuration globally without modifying project files. Useful for personal preferences or machine-specific settings.

### XDG Paths

The loader checks these paths (in order of priority):

1. **macOS only:** `~/Library/Application Support/{app}/{app}.yml`
2. `~/.config/{app}/{app}.yml` (XDG default)
3. `$XDG_CONFIG_HOME/{app}/{app}.yml` (if set)

Higher-numbered paths take precedence.

### Class Methods

#### config_paths

Get all potential config directory paths.

```ruby
MywayConfig::Loaders::XdgConfigLoader.config_paths(:myapp)
# => [
#      "/Users/me/Library/Application Support/myapp",  # macOS only
#      "/Users/me/.config/myapp"
#    ]
```

---

#### find_config_file

Find the first existing config file.

```ruby
MywayConfig::Loaders::XdgConfigLoader.find_config_file(:myapp)
# => "/Users/me/.config/myapp/myapp.yml" or nil
```

---

### File Format

XDG config files can be flat or environment-specific:

**Flat format:**

```yaml
# ~/.config/myapp/myapp.yml
database:
  host: my-custom-host
  port: 5433
```

**With environments:**

```yaml
# ~/.config/myapp/myapp.yml
development:
  database:
    host: dev-custom-host

production:
  database:
    host: prod-custom-host
```

### Example Usage

Create a user-specific override:

```bash
mkdir -p ~/.config/myapp
cat > ~/.config/myapp/myapp.yml << 'EOF'
database:
  host: custom-db.local
  port: 5433
EOF
```

Now your application uses these values:

```ruby
config = MyApp::Config.new
config.database.host  # => "custom-db.local"
config.database.port  # => 5433
```

---

## Loader Registration

Loaders are automatically registered when you call `MywayConfig.setup!` (which happens when requiring the gem).

```ruby
# lib/myway_config.rb
module MywayConfig
  def self.setup!
    return if @setup_complete

    Anyway.loaders.insert_before(
      :yml,
      :xdg_config,
      Loaders::XdgConfigLoader
    )

    Anyway.loaders.insert_before(
      :xdg_config,
      :bundled_defaults,
      Loaders::DefaultsLoader
    )

    @setup_complete = true
  end
end
```

### Manual Setup

If you need to control when loaders are registered:

```ruby
require 'myway_config'

# Check if already set up
MywayConfig.setup?  # => true (automatic)

# Reset and re-setup (mainly for testing)
MywayConfig.reset!
MywayConfig.setup!
```

---

## Custom Loaders

You can create custom loaders by extending `Anyway::Loaders::Base`:

```ruby
class MyCustomLoader < Anyway::Loaders::Base
  def call(name:, **options)
    trace!(:custom, source: "my_source") do
      # Return a Hash of configuration values
      load_from_custom_source(name)
    end
  end

  private

  def load_from_custom_source(name)
    # Your loading logic here
    {}
  end
end

# Register the loader
Anyway.loaders.insert_after(:yml, :custom, MyCustomLoader)
```

