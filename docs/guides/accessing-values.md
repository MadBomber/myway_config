# Accessing Values

MywayConfig provides multiple ways to access configuration values.

## Method Access

The most common way to access values:

```ruby
config.database.host      # => "localhost"
config.database.port      # => 5432
config.api.base_url       # => "https://api.example.com"
config.log_level          # => :info
```

Nested access works naturally:

```ruby
config.api.headers.content_type  # => "application/json"
```

## Bracket Access

Use symbol or string keys:

```ruby
# Symbol keys
config.database[:host]    # => "localhost"
config.database[:port]    # => 5432

# String keys
config.database["host"]   # => "localhost"
config.database["port"]   # => 5432
```

## All Access Patterns

These are all equivalent:

```ruby
config.database.host      # Method syntax
config.database[:host]    # Symbol bracket
config.database["host"]   # String bracket
```

## Hash-like Methods

ConfigSection provides Hash-like methods:

```ruby
# Keys and values
config.database.keys      # => [:host, :port, :name, :pool]
config.database.values    # => ["localhost", 5432, "myapp_db", 5]
config.database.size      # => 4
config.database.length    # => 4 (alias)

# Check for keys
config.database.key?(:host)     # => true
config.database.has_key?(:host) # => true (alias)
config.database.include?(:host) # => true (alias)

# Empty check
config.database.empty?    # => false
```

## Fetch with Default

Use `fetch` for safe access with defaults:

```ruby
# Returns value if key exists
config.database.fetch(:host)  # => "localhost"

# Returns default if key missing
config.database.fetch(:missing, "default")  # => "default"

# Block form
config.database.fetch(:missing) { "computed" }  # => "computed"

# Raises KeyError if no default
config.database.fetch(:missing)  # => KeyError!
```

## Dig for Nested Access

Use `dig` to safely access deeply nested values:

```ruby
config.api.dig(:headers, :content_type)  # => "application/json"
config.api.dig(:headers, :missing)       # => nil (no error)
config.api.dig(:missing, :nested)        # => nil (no error)
```

## Convert to Hash

Convert any section to a plain Ruby Hash:

```ruby
config.database.to_h
# => {host: "localhost", port: 5432, name: "myapp_db", pool: 5}
```

Nested sections are also converted:

```ruby
config.api.to_h
# => {
#      base_url: "https://api.example.com",
#      timeout: 30,
#      headers: {content_type: "application/json"}
#    }
```

## Enumerable Methods

ConfigSection includes `Enumerable`:

```ruby
# Iterate over key-value pairs
config.database.each do |key, value|
  puts "#{key}: #{value}"
end

# Map
config.database.map { |k, v| "#{k}=#{v}" }
# => ["host=localhost", "port=5432", ...]

# Select
config.database.select { |k, v| v.is_a?(Integer) }
# => [[:port, 5432], [:pool, 5]]

# Find
config.database.find { |k, v| v == 5432 }
# => [:port, 5432]

# Any/all
config.database.any? { |k, v| v.nil? }  # => false
config.database.all? { |k, v| v }       # => true
```

## Missing Keys

Accessing a missing key returns `nil`:

```ruby
config.database.missing_key  # => nil
config.database[:missing]    # => nil
```

## Next Steps

- [Environment Overrides](environment-overrides.md) - Override values with env vars
- [Hash-like Behavior](hash-like-behavior.md) - Deep dive into ConfigSection
