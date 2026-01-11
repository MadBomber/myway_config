# frozen_string_literal: true

require "test_helper"

SingleCov.covered!

class TestMywayConfig < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MywayConfig::VERSION
  end

  def test_setup_is_complete
    assert MywayConfig.setup?
  end

  def test_loaders_are_registered
    loader_names = Anyway.loaders.registry.map(&:first)
    assert_includes loader_names, :bundled_defaults
    assert_includes loader_names, :xdg
  end

  def test_setup_is_idempotent
    # Setup was already called, calling again should be a no-op
    MywayConfig.setup!
    assert MywayConfig.setup?

    loader_names = Anyway.loaders.registry.map(&:first)
    # Should still only have one of each loader
    assert_equal 1, loader_names.count(:bundled_defaults)
    assert_equal 1, loader_names.count(:xdg)
  end

  def test_reset_clears_setup_state
    assert MywayConfig.setup?
    MywayConfig.reset!
    refute MywayConfig.setup?

    # Restore state for other tests
    MywayConfig.setup!
    assert MywayConfig.setup?
  end
end

class TestConfigSection < Minitest::Test
  def test_basic_access
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    assert_equal 'localhost', section.host
    assert_equal 5432, section.port
  end

  def test_nested_access
    section = MywayConfig::ConfigSection.new(
      database: { host: 'localhost', port: 5432 }
    )
    assert_equal 'localhost', section.database.host
    assert_equal 5432, section.database.port
  end

  def test_missing_key_returns_nil
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_nil section.missing_key
  end

  def test_setter
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    section.host = '127.0.0.1'
    assert_equal '127.0.0.1', section.host
  end

  def test_bracket_access
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_equal 'localhost', section[:host]
  end

  def test_bracket_setter
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    section[:host] = '127.0.0.1'
    assert_equal '127.0.0.1', section.host
  end

  def test_to_h
    section = MywayConfig::ConfigSection.new(
      host: 'localhost',
      nested: { foo: 'bar' }
    )
    expected = { host: 'localhost', nested: { foo: 'bar' } }
    assert_equal expected, section.to_h
  end

  def test_merge
    section1 = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    section2 = MywayConfig::ConfigSection.new(port: 5433, name: 'mydb')
    merged = section1.merge(section2)

    assert_equal 'localhost', merged.host
    assert_equal 5433, merged.port
    assert_equal 'mydb', merged.name
  end

  def test_keys
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    assert_equal [:host, :port], section.keys
  end

  def test_each
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    pairs = []
    section.each { |k, v| pairs << [k, v] }
    assert_equal [[:host, 'localhost'], [:port, 5432]], pairs
  end

  def test_key?
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert section.key?(:host)
    refute section.key?(:missing)
  end

  def test_empty?
    assert MywayConfig::ConfigSection.new.empty?
    refute MywayConfig::ConfigSection.new(host: 'localhost').empty?
  end

  def test_values
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    assert_equal ['localhost', 5432], section.values
  end

  def test_size_and_length
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    assert_equal 2, section.size
    assert_equal 2, section.length
  end

  def test_fetch_with_existing_key
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_equal 'localhost', section.fetch(:host)
    assert_equal 'localhost', section.fetch('host')
  end

  def test_fetch_with_default
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_equal 'default', section.fetch(:missing, 'default')
  end

  def test_fetch_with_block
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_equal 'block_default', section.fetch(:missing) { 'block_default' }
  end

  def test_fetch_raises_key_error
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_raises(KeyError) { section.fetch(:missing) }
  end

  def test_dig_single_level
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_equal 'localhost', section.dig(:host)
    assert_equal 'localhost', section.dig('host')
  end

  def test_dig_nested
    section = MywayConfig::ConfigSection.new(
      database: { connection: { host: 'localhost' } }
    )
    assert_equal 'localhost', section.dig(:database, :connection, :host)
  end

  def test_dig_missing_returns_nil
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert_nil section.dig(:missing)
    assert_nil section.dig(:missing, :nested)
  end

  def test_has_key_aliases
    section = MywayConfig::ConfigSection.new(host: 'localhost')
    assert section.has_key?(:host)
    assert section.include?(:host)
    assert section.member?(:host)
    refute section.has_key?(:missing)
  end

  def test_enumerable_map
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    result = section.map { |k, v| "#{k}=#{v}" }
    assert_equal ['host=localhost', 'port=5432'], result
  end

  def test_enumerable_select
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432, name: 'db')
    result = section.select { |k, v| v.is_a?(String) }
    assert_equal [[:host, 'localhost'], [:name, 'db']], result
  end

  def test_enumerable_find
    section = MywayConfig::ConfigSection.new(host: 'localhost', port: 5432)
    result = section.find { |k, v| v.is_a?(Integer) }
    assert_equal [:port, 5432], result
  end
end

class TestAutoConfig < Minitest::Test
  FIXTURES_PATH = File.expand_path('fixtures', __dir__)

  def setup
    # Set a neutral environment that doesn't exist in the YAML
    # so only pure defaults are applied (no environment overrides)
    @original_rack_env = ENV['RACK_ENV']
    @original_rails_env = ENV['RAILS_ENV']
    ENV['RACK_ENV'] = 'neutral'
    ENV.delete('RAILS_ENV')
  end

  def teardown
    if @original_rack_env
      ENV['RACK_ENV'] = @original_rack_env
    else
      ENV.delete('RACK_ENV')
    end
    ENV['RAILS_ENV'] = @original_rails_env if @original_rails_env
  end

  def create_config_class(name)
    Class.new(MywayConfig::Base) do
      config_name name
      env_prefix name
    end
  end

  def test_auto_configure_raises_without_defaults_path
    config_class = create_config_class(:auto_test_no_path)
    error = assert_raises(MywayConfig::ConfigurationError) do
      config_class.auto_configure!
    end
    assert_match(/defaults_path must be set/, error.message)
  end

  def test_defaults_path_raises_for_missing_file
    config_class = create_config_class(:missing_defaults)
    error = assert_raises(MywayConfig::ConfigurationError) do
      config_class.defaults_path '/nonexistent/defaults.yml'
    end
    assert_match(/Defaults file not found/, error.message)
  end

  def test_auto_configure_creates_attr_config_for_each_key
    config_class = create_config_class(:auto_test_attrs)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    # All keys from defaults should be accessible
    assert config.respond_to?(:database)
    assert config.respond_to?(:api)
    assert config.respond_to?(:log_level)
    assert config.respond_to?(:timeout)
    assert config.respond_to?(:enabled)
  end

  def test_auto_configure_coerces_hashes_to_config_section
    config_class = create_config_class(:auto_test_coerce)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    assert_kind_of MywayConfig::ConfigSection, config.database
    assert_kind_of MywayConfig::ConfigSection, config.api
  end

  def test_auto_configure_provides_nested_method_access
    config_class = create_config_class(:auto_test_nested)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    assert_equal 'localhost', config.database.host
    assert_equal 5432, config.database.port
    assert_equal 'test_db', config.database.name
    assert_equal 'https://api.example.com', config.api.base_url
    assert_equal 30, config.api.timeout
  end

  def test_auto_configure_coerces_symbols
    config_class = create_config_class(:auto_test_sym)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    assert_equal :info, config.log_level
  end

  def test_auto_configure_preserves_scalar_values
    config_class = create_config_class(:auto_test_scalar)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    assert_equal 60, config.timeout
    assert_equal true, config.enabled
  end

  def test_auto_configure_with_environment_overrides
    ENV['RACK_ENV'] = 'production'

    config_class = create_config_class(:auto_test_prod)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    # Production overrides should be applied
    assert_equal 'prod-db.example.com', config.database.host
    assert_equal 'test_db_prod', config.database.name
    # Non-overridden values should come from defaults
    assert_equal 5432, config.database.port
  end

  def test_auto_configure_with_development_environment
    ENV['RACK_ENV'] = 'development'

    config_class = create_config_class(:auto_test_dev)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    # Development overrides should be applied
    assert_equal 'test_db_dev', config.database.name
    assert_equal :debug, config.log_level
    # Non-overridden values should come from defaults
    assert_equal 'localhost', config.database.host
  end

  def test_auto_configure_with_env_var_overrides
    ENV['AUTO_TEST_ENVVAR_TIMEOUT'] = '120'

    config_class = create_config_class(:auto_test_envvar)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new

    assert_equal 120, config.timeout
  ensure
    ENV.delete('AUTO_TEST_ENVVAR_TIMEOUT')
  end

  def test_new_with_string_path
    config_class = create_config_class(:new_string_path)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new(File.join(FIXTURES_PATH, 'custom_config.yml'))

    assert_equal 'custom-host.example.com', config.database.host
    assert_equal 5433, config.database.port
    assert_equal :warn, config.log_level
  end

  def test_new_with_pathname
    config_class = create_config_class(:new_pathname)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new(Pathname.new(File.join(FIXTURES_PATH, 'custom_config.yml')))

    assert_equal 'custom-host.example.com', config.database.host
    assert_equal 5433, config.database.port
  end

  def test_new_with_path_uses_current_environment
    ENV['RACK_ENV'] = 'production'

    config_class = create_config_class(:new_path_env)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new(File.join(FIXTURES_PATH, 'auto_config_defaults.yml'))

    assert_equal 'prod-db.example.com', config.database.host
    assert_equal 'test_db_prod', config.database.name
    assert_equal :warn, config.log_level
  end

  def test_new_with_hash_overrides
    config_class = create_config_class(:new_hash)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    config = config_class.new(database: { host: 'override.local' }, timeout: 999)

    assert_equal 'override.local', config.database.host
    assert_equal 999, config.timeout
  end

  def test_new_with_missing_path_raises
    config_class = create_config_class(:new_path_missing)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    error = assert_raises(MywayConfig::ConfigurationError) do
      config_class.new('/nonexistent/config.yml')
    end
    assert_match(/Config file not found/, error.message)
  end

  def test_new_with_invalid_source_raises
    config_class = create_config_class(:new_invalid)
    config_class.defaults_path File.join(FIXTURES_PATH, 'auto_config_defaults.yml')
    config_class.auto_configure!

    error = assert_raises(MywayConfig::ConfigurationError) do
      config_class.new(12345)
    end
    assert_match(/Invalid source/, error.message)
  end
end
