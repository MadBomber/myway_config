# MywayConfig::Base

Base class for configuration. Extends `Anyway::Config`.

## Class Methods

### config_name

Set the configuration name.

```ruby
config_name :myapp
```

**Parameters:**

- `name` (Symbol) - The configuration name

**Used for:**

- Finding config files (`config/myapp.yml`)
- XDG config path (`~/.config/myapp/config.yml`)
- Loader registration

---

### env_prefix

Set the environment variable prefix.

```ruby
env_prefix :myapp
```

**Parameters:**

- `prefix` (Symbol) - The prefix for environment variables

**Result:**

Environment variables like `MYAPP_DATABASE__HOST` will be recognized.

---

### defaults_path

Register the defaults file path.

```ruby
defaults_path File.expand_path("config/defaults.yml", __dir__)
```

**Parameters:**

- `path` (String) - Absolute path to the defaults YAML file

**Raises:**

- `ConfigurationError` if the file does not exist

---

### auto_configure!

Auto-generate attributes and coercions from the YAML schema.

```ruby
auto_configure!
```

**Raises:**

- `ConfigurationError` if `defaults_path` is not set

**Behavior:**

- Creates `attr_config` for each key in the `defaults:` section
- Coerces Hash values to `ConfigSection`
- Coerces Symbol values to symbols

---

### schema

Returns the defaults section from the YAML file.

```ruby
MyConfig.schema  # => {database: {host: "localhost", ...}, ...}
```

**Returns:**

- `Hash` - The parsed `defaults:` section

---

### config_section_coercion

Create a coercion proc that merges with schema defaults.

```ruby
coerce_types(
  database: config_section_coercion(:database)
)
```

**Parameters:**

- `section_key` (Symbol) - The section key in the schema

**Returns:**

- `Proc` - Coercion proc for use with `coerce_types`

---

### config_section

Create a simple ConfigSection coercion (without schema defaults).

```ruby
coerce_types(
  settings: config_section
)
```

**Returns:**

- `Proc` - Coercion proc

---

### to_symbol

Create a symbol coercion proc.

```ruby
coerce_types(
  log_level: to_symbol
)
```

**Returns:**

- `Proc` - Coercion proc that converts to symbol

---

### env

Get the current environment.

```ruby
MyConfig.env  # => "development"
```

**Returns:**

- `String` - Current environment name

**Priority:**

1. `Anyway::Settings.current_environment`
2. `ENV['RAILS_ENV']`
3. `ENV['RACK_ENV']`
4. `'development'`

---

### valid_environments

Get list of valid environment names from the defaults file.

```ruby
MyConfig.valid_environments  # => [:development, :production, :test]
```

**Returns:**

- `Array<Symbol>` - Environment names defined in YAML

---

### valid_environment?

Check if current environment is valid.

```ruby
MyConfig.valid_environment?  # => true
```

**Returns:**

- `Boolean` - true if environment has a section in YAML

---

## Instance Methods

### initialize

Create a new configuration instance.

```ruby
# Default (use loaders)
config = MyConfig.new

# From file path
config = MyConfig.new("/path/to/config.yml")

# From Hash
config = MyConfig.new(database: { host: "custom" })
```

**Parameters:**

- `source` (nil, String, Pathname, Hash) - Configuration source

**Raises:**

- `ConfigurationError` if file path doesn't exist
- `ConfigurationError` if source type is invalid

---

### environment

Get the current environment name.

```ruby
config.environment  # => "development"
```

**Returns:**

- `String` - Current environment

---

### development?

Check if running in development environment.

```ruby
config.development?  # => true
```

---

### production?

Check if running in production environment.

```ruby
config.production?  # => false
```

---

### test?

Check if running in test environment.

```ruby
config.test?  # => false
```

---

### valid_environment?

Check if current environment is valid.

```ruby
config.valid_environment?  # => true
```

## Example

```ruby
class MyApp::Config < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp
  defaults_path File.expand_path("config/defaults.yml", __dir__)
  auto_configure!
end

config = MyApp::Config.new
config.database.host      # => "localhost"
config.environment        # => "development"
config.development?       # => true
```
