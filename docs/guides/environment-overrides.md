# Environment Overrides

Override any configuration value using environment variables.

## Basic Syntax

Environment variables use the pattern:

```
{PREFIX}_{KEY}=value
```

For your config:

```ruby
class MyApp::Config < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp  # This sets the prefix
  # ...
end
```

Override values:

```bash
MYAPP_LOG_LEVEL=warn
MYAPP_DEBUG=true
MYAPP_MAX_CONNECTIONS=50
```

## Nested Values

Use double underscore (`__`) for nested keys:

```bash
# Override database.host
MYAPP_DATABASE__HOST=custom-db.local

# Override database.port
MYAPP_DATABASE__PORT=5433

# Override api.headers.content_type
MYAPP_API__HEADERS__CONTENT_TYPE=text/plain
```

## Priority Order

Environment variables have high priority. Values are loaded in order:

1. Bundled defaults (lowest)
2. Environment-specific overrides from YAML
3. XDG user config
4. Project config
5. **Environment variables** (high priority)
6. Constructor overrides (highest)

## Type Coercion

Values are automatically coerced based on the default type:

```yaml
defaults:
  port: 5432        # Integer
  debug: false      # Boolean
  timeout: 30.5     # Float
  log_level: :info  # Symbol
```

```bash
MYAPP_PORT=9999           # Becomes Integer 9999
MYAPP_DEBUG=true          # Becomes Boolean true
MYAPP_TIMEOUT=60.0        # Becomes Float 60.0
MYAPP_LOG_LEVEL=warn      # Becomes Symbol :warn
```

## Examples

### Running with Overrides

```bash
# Development with custom database
MYAPP_DATABASE__HOST=localhost MYAPP_DATABASE__PORT=5433 ruby app.rb

# Production-like settings locally
RACK_ENV=production MYAPP_DATABASE__HOST=prod-db.local ruby app.rb
```

### In Docker

```dockerfile
ENV MYAPP_DATABASE__HOST=db
ENV MYAPP_DATABASE__PORT=5432
ENV MYAPP_LOG_LEVEL=info
```

### In docker-compose

```yaml
services:
  app:
    environment:
      - RACK_ENV=production
      - MYAPP_DATABASE__HOST=db
      - MYAPP_DATABASE__PORT=5432
```

### In Heroku

```bash
heroku config:set MYAPP_DATABASE__HOST=your-db.herokuapp.com
heroku config:set MYAPP_LOG_LEVEL=warn
```

## Checking Values

Verify environment variable overrides are working:

```ruby
config = MyApp::Config.new

puts "Database host: #{config.database.host}"
puts "From env: #{ENV['MYAPP_DATABASE__HOST']}"
```

## Debugging

If values aren't being picked up, check:

1. **Prefix matches** - `env_prefix` in your class must match
2. **Double underscore** - Nested keys need `__`
3. **Case sensitivity** - Environment variables are uppercase
4. **Load order** - Config class must be loaded after env vars are set

## Next Steps

- [Custom File Loading](custom-file-loading.md) - Load from non-standard locations
- [Hash-like Behavior](hash-like-behavior.md) - ConfigSection features
