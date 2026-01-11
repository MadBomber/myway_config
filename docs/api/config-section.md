# ConfigSection

Hash-like wrapper for nested configuration with method access and Enumerable support.

## Overview

`ConfigSection` wraps Hash values from YAML, providing:

- Method access (`config.database.host`)
- Bracket access (`config.database[:host]`)
- Enumerable iteration
- Hash-like methods (`keys`, `values`, `fetch`, `dig`)

## Constructor

### new

Create a new ConfigSection from a Hash.

```ruby
section = MywayConfig::ConfigSection.new(host: "localhost", port: 5432)
```

**Parameters:**

- `hash` (Hash) - The hash to wrap (default: `{}`)

**Behavior:**

- Keys are symbolized
- Nested Hashes become nested ConfigSections

---

## Access Methods

### Method Access

```ruby
section.host        # => "localhost"
section.port        # => 5432
section.missing     # => nil
```

### Bracket Access

```ruby
section[:host]      # => "localhost"
section["host"]     # => "localhost"
```

### Setting Values

```ruby
section.host = "new-host"
section[:port] = 5433
```

---

## Hash Methods

### keys

Get all keys.

```ruby
section.keys  # => [:host, :port, :name]
```

**Returns:**

- `Array<Symbol>` - All keys

---

### values

Get all values.

```ruby
section.values  # => ["localhost", 5432, "myapp_db"]
```

**Returns:**

- `Array` - All values

---

### size / length

Get the number of keys.

```ruby
section.size    # => 3
section.length  # => 3
```

**Returns:**

- `Integer` - Number of keys

---

### key? / has_key? / include? / member?

Check if a key exists.

```ruby
section.key?(:host)       # => true
section.has_key?(:host)   # => true
section.include?(:host)   # => true
section.member?(:host)    # => true
```

**Parameters:**

- `key` (Symbol, String) - The key to check

**Returns:**

- `Boolean` - true if key exists

---

### empty?

Check if the section has no keys.

```ruby
section.empty?  # => false
MywayConfig::ConfigSection.new.empty?  # => true
```

**Returns:**

- `Boolean` - true if no keys

---

### fetch

Fetch a value with optional default.

```ruby
# With key
section.fetch(:host)  # => "localhost"

# With default value
section.fetch(:missing, "default")  # => "default"

# With block
section.fetch(:missing) { |k| "no #{k}" }  # => "no missing"

# Without default (raises KeyError)
section.fetch(:missing)  # => KeyError: key not found: :missing
```

**Parameters:**

- `key` (Symbol, String) - The key to fetch
- `default` (Object) - Optional default value

**Yields:**

- `key` - When block provided and key missing

**Returns:**

- `Object` - The value or default

**Raises:**

- `KeyError` - If key not found and no default

---

### dig

Access nested values safely.

```ruby
config.api.dig(:headers, :content_type)  # => "application/json"
config.api.dig(:missing, :nested)        # => nil
```

**Parameters:**

- `keys` (Array<Symbol, String>) - Keys to dig through

**Returns:**

- `Object, nil` - The value or nil if not found

---

### [] and []=

Bracket access and assignment.

```ruby
section[:host]        # => "localhost"
section[:host] = "new-host"
```

---

## Enumerable Methods

ConfigSection includes `Enumerable`, providing all iteration methods.

### each

Iterate over key-value pairs.

```ruby
section.each do |key, value|
  puts "#{key}: #{value}"
end
```

---

### map

Transform key-value pairs.

```ruby
section.map { |k, v| "#{k}=#{v}" }
# => ["host=localhost", "port=5432"]
```

---

### select / reject

Filter key-value pairs.

```ruby
section.select { |k, v| v.is_a?(Integer) }
# => [[:port, 5432], [:pool, 5]]

section.reject { |k, v| v.nil? }
```

---

### find / detect

Find first matching pair.

```ruby
section.find { |k, v| v == 5432 }
# => [:port, 5432]
```

---

### any? / all? / none?

Check conditions.

```ruby
section.any? { |k, v| v.nil? }   # => false
section.all? { |k, v| v }        # => true
section.none? { |k, v| v.nil? }  # => true
```

---

### Other Enumerable Methods

All standard Enumerable methods work:

- `count`, `first`, `take`, `drop`
- `min`, `max`, `minmax`
- `sort`, `sort_by`
- `group_by`, `partition`
- `reduce`, `inject`
- And more...

---

## Conversion Methods

### to_h

Convert to a plain Ruby Hash.

```ruby
section.to_h
# => {host: "localhost", port: 5432, name: "myapp_db"}
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

**Returns:**

- `Hash` - Plain Ruby Hash

---

### merge

Merge with another ConfigSection or Hash.

```ruby
overrides = { host: "new-host", pool: 10 }
merged = section.merge(overrides)

merged.host  # => "new-host"
merged.pool  # => 10
merged.port  # => 5432 (from original)
```

**Parameters:**

- `other` (ConfigSection, Hash) - Values to merge

**Returns:**

- `ConfigSection` - New merged ConfigSection

---

## Examples

### Building Connection Strings

```ruby
db = config.database
connection_string = "postgres://#{db.host}:#{db.port}/#{db.name}"
# => "postgres://localhost:5432/myapp_db"
```

### Filtering Configuration

```ruby
# Get all non-nil settings
config.database.reject { |k, v| v.nil? }.to_h
```

### Transforming Values

```ruby
# Upcase all string values
config.database.map { |k, v|
  [k, v.is_a?(String) ? v.upcase : v]
}.to_h
```

### Safe Nested Access

```ruby
# Won't raise even if path doesn't exist
timeout = config.api.dig(:retry, :timeout) || 30
```

