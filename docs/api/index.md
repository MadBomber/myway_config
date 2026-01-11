# API Reference

Complete API documentation for MywayConfig.

## Core Classes

- [MywayConfig::Base](base.md) - Base class for configuration
- [ConfigSection](config-section.md) - Hash-like configuration sections
- [Loaders](loaders.md) - Configuration loaders

## Module

### MywayConfig

The main module provides setup and error classes.

#### Methods

##### `MywayConfig.setup!`

Registers the XDG and defaults loaders with Anyway Config. Called automatically when the gem is loaded.

```ruby
MywayConfig.setup!
```

##### `MywayConfig.setup?`

Check if setup has been completed.

```ruby
MywayConfig.setup?  # => true
```

##### `MywayConfig.reset!`

Reset setup state (mainly for testing).

```ruby
MywayConfig.reset!
```

## Error Classes

### MywayConfig::Error

Base error class for all MywayConfig errors.

```ruby
begin
  # ...
rescue MywayConfig::Error => e
  # Handle any MywayConfig error
end
```

### MywayConfig::ConfigurationError

Raised for configuration problems:

- Missing defaults file
- Invalid constructor argument
- `auto_configure!` called without `defaults_path`

```ruby
begin
  MyConfig.new("/nonexistent/file.yml")
rescue MywayConfig::ConfigurationError => e
  puts "Config error: #{e.message}"
end
```

### MywayConfig::ValidationError

Reserved for validation errors (future use).

## Constants

### MywayConfig::VERSION

The gem version string.

```ruby
MywayConfig::VERSION  # => "0.1.0"
```
