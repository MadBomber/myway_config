# frozen_string_literal: true

module MywayConfig
  # ConfigSection provides method access to nested configuration hashes
  #
  # This allows configuration values to be accessed using method syntax
  # instead of hash bracket notation, making config access more readable.
  # Includes Enumerable for full Hash-like iteration support.
  #
  # @example Basic usage
  #   section = ConfigSection.new(host: 'localhost', port: 5432)
  #   section.host        # => 'localhost'
  #   section[:host]      # => 'localhost'
  #   section['host']     # => 'localhost'
  #
  # @example Nested sections
  #   section = ConfigSection.new(database: { host: 'localhost', port: 5432 })
  #   section.database.host  # => 'localhost'
  #
  # @example Hash-like behavior
  #   section.keys           # => [:host, :port]
  #   section.values         # => ['localhost', 5432]
  #   section.fetch(:host)   # => 'localhost'
  #   section.map { |k, v| "#{k}=#{v}" }  # => ['host=localhost', 'port=5432']
  #
  class ConfigSection
    include Enumerable
    def initialize(hash = {})
      @data = {}
      (hash || {}).each do |key, value|
        @data[key.to_sym] = value.is_a?(Hash) ? ConfigSection.new(value) : value
      end
    end

    def method_missing(method, *args, &block)
      key = method.to_s
      if key.end_with?('=')
        @data[key.chomp('=').to_sym] = args.first
      elsif @data.key?(method)
        @data[method]
      else
        nil
      end
    end

    def respond_to_missing?(method, include_private = false)
      key = method.to_s.chomp('=').to_sym
      @data.key?(key) || super
    end

    # Convert to a plain Ruby hash
    #
    # @return [Hash] the configuration as a hash
    def to_h
      @data.transform_values do |v|
        v.is_a?(ConfigSection) ? v.to_h : v
      end
    end

    # Access a value by key
    #
    # @param key [Symbol, String] the key to access
    # @return [Object] the value
    def [](key)
      @data[key.to_sym]
    end

    # Set a value by key
    #
    # @param key [Symbol, String] the key to set
    # @param value [Object] the value to set
    def []=(key, value)
      @data[key.to_sym] = value
    end

    # Merge with another ConfigSection or hash
    #
    # @param other [ConfigSection, Hash] the other config to merge
    # @return [ConfigSection] a new merged ConfigSection
    def merge(other)
      other_hash = other.is_a?(ConfigSection) ? other.to_h : other
      ConfigSection.new(deep_merge(to_h, other_hash || {}))
    end

    # Get all keys
    #
    # @return [Array<Symbol>] the keys
    def keys
      @data.keys
    end

    # Iterate over key-value pairs
    #
    # @yield [key, value] each key-value pair
    def each(&block)
      @data.each(&block)
    end

    # Check if a key exists
    #
    # @param key [Symbol, String] the key to check
    # @return [Boolean] true if the key exists
    def key?(key)
      @data.key?(key.to_sym)
    end

    # Check if the section is empty
    #
    # @return [Boolean] true if no keys are present
    def empty?
      @data.empty?
    end

    # Get all values
    #
    # @return [Array] the values
    def values
      @data.values
    end

    # Get the number of keys
    #
    # @return [Integer] the number of keys
    def size
      @data.size
    end
    alias length size

    # Fetch a value with optional default
    #
    # @param key [Symbol, String] the key to fetch
    # @param default [Object] optional default value
    # @yield optional block for default value
    # @return [Object] the value or default
    # @raise [KeyError] if key not found and no default given
    def fetch(key, *args, &block)
      @data.fetch(key.to_sym, *args, &block)
    end

    # Dig into nested values
    #
    # @param keys [Array<Symbol, String>] the keys to dig through
    # @return [Object, nil] the value or nil if not found
    def dig(*keys)
      keys.reduce(self) do |obj, key|
        return nil unless obj.respond_to?(:[])
        obj[key]
      end
    end

    # Alias for key? to match Hash interface
    alias has_key? key?
    alias include? key?
    alias member? key?

    private

    def deep_merge(base, overlay)
      base.merge(overlay) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end
  end
end
