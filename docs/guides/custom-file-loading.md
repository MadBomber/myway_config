# Custom File Loading

Load configuration from non-standard locations or pass configuration directly.

## Loading from a File Path

Pass a file path (String or Pathname) to the constructor:

```ruby
# From a String path
config = MyApp::Config.new("/etc/myapp/config.yml")

# From a Pathname
config = MyApp::Config.new(Pathname.new("/etc/myapp/config.yml"))
```

## File Format

The file can be a flat configuration:

```yaml
# /etc/myapp/config.yml (flat format)
database:
  host: custom-db.example.com
  port: 5432
log_level: :warn
```

Or include environment sections:

```yaml
# /etc/myapp/config.yml (with environments)
defaults:
  database:
    host: localhost
    port: 5432
  log_level: :info

production:
  database:
    host: prod-db.example.com
  log_level: :warn
```

## Environment Detection

When loading from a file with environment sections, the current environment (`RACK_ENV`/`RAILS_ENV`) determines which overrides are applied:

```bash
# Uses production overrides from the file
RACK_ENV=production ruby -e "config = MyApp::Config.new('/etc/myapp/config.yml')"
```

## Loading from a Hash

Pass configuration directly as a Hash:

```ruby
config = MyApp::Config.new(
  database: {
    host: "custom.local",
    port: 5433
  },
  log_level: :debug
)
```

Hash values override defaults:

```ruby
config.database.host   # => "custom.local" (from Hash)
config.database.port   # => 5433 (from Hash)
config.database.name   # => "myapp_db" (from defaults)
```

## Constructor Signatures

The constructor accepts three types:

```ruby
# nil - use normal loading (defaults + loaders + env vars)
config = MyApp::Config.new

# String or Pathname - load from file
config = MyApp::Config.new("/path/to/config.yml")

# Hash - use as overrides
config = MyApp::Config.new(database: { host: "custom" })
```

## Use Cases

### External Configuration

Load configuration from a system-wide location:

```ruby
config_path = if File.exist?("/etc/myapp/config.yml")
                "/etc/myapp/config.yml"
              else
                nil  # Fall back to defaults
              end

config = MyApp::Config.new(config_path)
```

### Testing

Override configuration in tests:

```ruby
# test/test_helper.rb
def with_config(overrides, &block)
  original = MyApp.config
  MyApp.instance_variable_set(:@config, MyApp::Config.new(overrides))
  yield
ensure
  MyApp.instance_variable_set(:@config, original)
end

# In tests
def test_something
  with_config(database: { host: "test-db" }) do
    assert_equal "test-db", MyApp.config.database.host
  end
end
```

### Dynamic Configuration

Load configuration based on runtime conditions:

```ruby
config_file = case
              when ENV["CUSTOM_CONFIG"]
                ENV["CUSTOM_CONFIG"]
              when File.exist?("config/local.yml")
                "config/local.yml"
              else
                nil
              end

config = MyApp::Config.new(config_file)
```

## Error Handling

A `ConfigurationError` is raised if the file doesn't exist:

```ruby
begin
  config = MyApp::Config.new("/nonexistent/path.yml")
rescue MywayConfig::ConfigurationError => e
  puts "Config file not found: #{e.message}"
end
```

## Next Steps

- [Hash-like Behavior](hash-like-behavior.md) - ConfigSection features
- [Examples](../examples/index.md) - Real-world usage examples
