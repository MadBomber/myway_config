# YAML Structure

The YAML defaults file is the single source of truth for your configuration structure and default values.

## Required Structure

The file must have a `defaults` key. Other top-level keys are environment names.

```yaml
defaults:           # Required - defines structure and default values
  key: value

development:        # Optional - overrides for development
  key: dev_value

production:         # Optional - overrides for production
  key: prod_value

test:               # Optional - overrides for test
  key: test_value
```

## The `defaults` Section

The `defaults` section defines:

1. **Structure** - What keys exist in your configuration
2. **Types** - Hash values become `ConfigSection`, symbols stay symbols
3. **Default values** - Base values before any overrides

```yaml
defaults:
  # Nested configuration (becomes ConfigSection)
  database:
    host: localhost
    port: 5432
    name: myapp_db
    pool: 5

  # Another nested section
  api:
    base_url: https://api.example.com
    timeout: 30
    headers:
      content_type: application/json

  # Symbol value (coerced to :info)
  log_level: :info

  # Scalar values
  debug: false
  max_connections: 10
```

## Environment Sections

Environment sections contain only overrides. Values merge with defaults.

```yaml
defaults:
  database:
    host: localhost
    port: 5432
    name: myapp_db
  log_level: :info
  debug: false

development:
  # Only override what's different
  database:
    name: myapp_development
  log_level: :debug
  debug: true

production:
  database:
    host: prod-db.example.com
    name: myapp_production
    pool: 25
  log_level: :warn
  # debug remains false (from defaults)

test:
  database:
    name: myapp_test
```

## Merge Behavior

Environment values are deep-merged with defaults:

```yaml
defaults:
  database:
    host: localhost
    port: 5432
    name: myapp_db
    pool: 5

production:
  database:
    host: prod-db.example.com
    pool: 25
```

Result in production:

```ruby
config.database.host  # => "prod-db.example.com" (overridden)
config.database.port  # => 5432 (from defaults)
config.database.name  # => "myapp_db" (from defaults)
config.database.pool  # => 25 (overridden)
```

## Supported Value Types

| YAML Type | Ruby Type | Notes |
|-----------|-----------|-------|
| `string` | `String` | Plain strings |
| `123` | `Integer` | Numbers |
| `1.5` | `Float` | Decimals |
| `true`/`false` | `Boolean` | Booleans |
| `:symbol` | `Symbol` | Colon prefix for symbols |
| `hash:` | `ConfigSection` | Nested hashes become ConfigSection |
| `[a, b]` | `Array` | Arrays |
| `null` | `nil` | Null values |

## Environment Detection

The current environment is determined by (in order):

1. `Anyway::Settings.current_environment`
2. `ENV['RAILS_ENV']`
3. `ENV['RACK_ENV']`
4. `'development'` (default)

## Custom Environments

You can define any environment name:

```yaml
defaults:
  api_url: https://api.example.com

staging:
  api_url: https://staging-api.example.com

canary:
  api_url: https://canary-api.example.com
```

```bash
RACK_ENV=staging ruby app.rb
```

## Valid Environments

You can check if an environment is defined:

```ruby
MyApp::Config.valid_environments  # => [:development, :production, :test]
MyApp::Config.valid_environment?  # => true (if current env is defined)
```

## Next Steps

- [Accessing Values](accessing-values.md) - How to read your configuration
- [Environment Overrides](environment-overrides.md) - Override with environment variables
