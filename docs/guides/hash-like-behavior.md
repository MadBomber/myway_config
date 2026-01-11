# Hash-like Behavior

ConfigSection provides Hash-like access and Enumerable support.

## What is ConfigSection?

When you define a nested configuration in YAML:

```yaml
defaults:
  database:
    host: localhost
    port: 5432
```

The `database` value becomes a `ConfigSection` object, not a plain Hash:

```ruby
config.database.class  # => MywayConfig::ConfigSection
```

## Why ConfigSection?

ConfigSection provides:

1. **Method access** - `config.database.host` instead of `config.database[:host]`
2. **Multiple access patterns** - Methods, symbols, and strings all work
3. **Hash-like enumeration** - `Enumerable` methods like `map`, `select`, `find`
4. **Safe nested access** - `dig` for deep traversal

## Access Methods

### Method Syntax

```ruby
config.database.host  # => "localhost"
```

### Bracket Syntax

```ruby
config.database[:host]   # => "localhost"
config.database["host"]  # => "localhost"
```

### Setting Values

```ruby
config.database.host = "new-host"
config.database[:port] = 5433
```

## Hash Methods

### Keys and Values

```ruby
config.database.keys    # => [:host, :port, :name, :pool]
config.database.values  # => ["localhost", 5432, "myapp_db", 5]
config.database.size    # => 4
config.database.length  # => 4
```

### Key Checking

```ruby
config.database.key?(:host)      # => true
config.database.has_key?(:host)  # => true
config.database.include?(:host)  # => true
config.database.member?(:host)   # => true

config.database.empty?           # => false
```

### Fetch

```ruby
# With key
config.database.fetch(:host)  # => "localhost"

# With default
config.database.fetch(:missing, "default")  # => "default"

# With block
config.database.fetch(:missing) { |k| "no #{k}" }  # => "no missing"

# Without default (raises KeyError)
config.database.fetch(:missing)  # => KeyError: key not found: :missing
```

### Dig

```ruby
config.api.dig(:headers, :content_type)  # => "application/json"
config.api.dig(:missing, :nested)        # => nil
```

## Enumerable Methods

ConfigSection includes `Enumerable`:

### each

```ruby
config.database.each do |key, value|
  puts "#{key}: #{value}"
end
# host: localhost
# port: 5432
# ...
```

### map

```ruby
config.database.map { |k, v| "#{k}=#{v}" }
# => ["host=localhost", "port=5432", ...]
```

### select / reject

```ruby
# Select numeric values
config.database.select { |k, v| v.is_a?(Integer) }
# => [[:port, 5432], [:pool, 5]]

# Reject nil values
config.database.reject { |k, v| v.nil? }
```

### find / detect

```ruby
config.database.find { |k, v| v == 5432 }
# => [:port, 5432]
```

### any? / all? / none?

```ruby
config.database.any? { |k, v| v.nil? }   # => false
config.database.all? { |k, v| v }        # => true
config.database.none? { |k, v| v.nil? }  # => true
```

### Other Enumerable Methods

All standard Enumerable methods work:

- `count`, `first`, `take`, `drop`
- `min`, `max`, `minmax`
- `sort`, `sort_by`
- `group_by`, `partition`
- `reduce`, `inject`
- And more...

## Conversion

### to_h

Convert to a plain Ruby Hash:

```ruby
config.database.to_h
# => {host: "localhost", port: 5432, name: "myapp_db", pool: 5}
```

Nested ConfigSections are also converted:

```ruby
config.api.to_h
# => {
#      base_url: "https://api.example.com",
#      timeout: 30,
#      headers: {content_type: "application/json"}
#    }
```

### merge

Merge with another ConfigSection or Hash:

```ruby
overrides = { host: "new-host", pool: 10 }
merged = config.database.merge(overrides)

merged.host  # => "new-host"
merged.pool  # => 10
merged.port  # => 5432 (from original)
```

## Practical Examples

### Building Connection Strings

```ruby
db = config.database
connection_string = "postgres://#{db.host}:#{db.port}/#{db.name}"
```

### Filtering Configuration

```ruby
# Get all non-nil database settings
config.database.reject { |k, v| v.nil? }.to_h
```

### Transforming Values

```ruby
# Upcase all string values
config.database.map { |k, v|
  [k, v.is_a?(String) ? v.upcase : v]
}.to_h
```

## Next Steps

- [Examples](../examples/index.md) - Real-world usage examples
- [API Reference](../api/config-section.md) - Complete ConfigSection API
