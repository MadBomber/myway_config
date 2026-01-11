# Testing

Running and writing tests for MywayConfig.

## Running Tests

### All Tests

```bash
bundle exec rake test
```

### Specific Test File

```bash
bundle exec ruby -Itest test/test_myway_config.rb
```

### Specific Test Method

```bash
bundle exec ruby -Itest test/test_myway_config.rb -n test_auto_configure
```

### With Verbose Output

```bash
bundle exec rake test TESTOPTS="--verbose"
```

## Code Coverage

The project uses [single_cov](https://github.com/grosser/single_cov) for line-level coverage.

### How It Works

`single_cov` verifies that every line in the source file is executed by tests. After tests run, it reports any uncovered lines.

### Viewing Coverage

Coverage is reported after test runs:

```
# All lines covered
Run options: --seed 12345

# Running:
.........

Finished in 0.05s, 180.0 runs/s, 360.0 assertions/s.
9 runs, 18 assertions, 0 failures, 0 errors, 0 skips

# If lines are uncovered:
lib/myway_config/base.rb new uncovered lines introduced (1 current vs 0 configured)
Uncovered lines:
lib/myway_config/base.rb:42
```

### Fixing Coverage Issues

If tests fail due to uncovered lines:

1. Identify the uncovered line from the report
2. Add a test that exercises that code path
3. Re-run tests to verify coverage

## Test Structure

### Test Files

```
test/
├── test_helper.rb              # Test setup and configuration
├── test_myway_config.rb        # Main test file
└── fixtures/
    ├── auto_config_defaults.yml    # Fixture for auto_configure tests
    └── custom_config.yml           # Fixture for custom file loading
```

### Test Helper

```ruby
# test/test_helper.rb
require 'single_cov'
SingleCov.setup :minitest

require 'minitest/autorun'
require 'myway_config'

# Set neutral environment to test pure defaults
ENV['RACK_ENV'] = 'neutral'
```

### Writing Tests

```ruby
# test/test_myway_config.rb
require 'test_helper'

class TestMywayConfig < Minitest::Test
  def test_config_section_keys
    section = MywayConfig::ConfigSection.new(
      host: 'localhost',
      port: 5432
    )
    assert_equal [:host, :port], section.keys
  end
end
```

## Test Fixtures

### Creating Fixtures

Place YAML fixtures in `test/fixtures/`:

```yaml
# test/fixtures/example_defaults.yml
defaults:
  database:
    host: localhost
    port: 5432

development:
  database:
    name: example_dev

test:
  database:
    name: example_test
```

### Using Fixtures

```ruby
def test_loading_from_fixture
  fixture_path = File.expand_path('fixtures/example_defaults.yml', __dir__)

  Class.new(MywayConfig::Base) do
    config_name :example
    defaults_path fixture_path
    auto_configure!
  end

  # Test assertions...
end
```

## Testing Patterns

### Testing Configuration Classes

```ruby
def test_auto_configure_creates_attributes
  config_class = Class.new(MywayConfig::Base) do
    config_name :test_app
    defaults_path File.expand_path('fixtures/test_defaults.yml', __dir__)
    auto_configure!
  end

  config = config_class.new

  assert_respond_to config, :database
  assert_respond_to config, :log_level
end
```

### Testing ConfigSection

```ruby
def test_config_section_enumerable
  section = MywayConfig::ConfigSection.new(a: 1, b: 2, c: 3)

  result = section.map { |k, v| v }

  assert_equal [1, 2, 3], result
end
```

### Testing Environment Detection

```ruby
def test_environment_detection
  original = ENV['RACK_ENV']
  ENV['RACK_ENV'] = 'production'

  config_class = Class.new(MywayConfig::Base) do
    config_name :env_test
    defaults_path File.expand_path('fixtures/test_defaults.yml', __dir__)
    auto_configure!
  end

  config = config_class.new

  assert config.production?
  refute config.development?
ensure
  ENV['RACK_ENV'] = original
end
```

### Testing Error Cases

```ruby
def test_raises_on_missing_defaults_file
  assert_raises(MywayConfig::ConfigurationError) do
    Class.new(MywayConfig::Base) do
      config_name :missing
      defaults_path '/nonexistent/path.yml'
    end
  end
end
```

### Testing with Overrides

```ruby
def test_hash_overrides_defaults
  config_class = Class.new(MywayConfig::Base) do
    config_name :override_test
    defaults_path File.expand_path('fixtures/test_defaults.yml', __dir__)
    auto_configure!
  end

  config = config_class.new(database: { host: 'custom-host' })

  assert_equal 'custom-host', config.database.host
end
```

## Continuous Integration

Tests run automatically on GitHub Actions for:

- Ruby 3.2
- Ruby 3.3
- Ruby 3.4

### CI Configuration

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        ruby-version: ['3.2', '3.3', '3.4']

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true
      - run: bundle exec rake test
```

## Best Practices

1. **Isolate tests** - Each test should be independent
2. **Test edge cases** - Empty values, nil, missing keys
3. **Test errors** - Verify exceptions are raised correctly
4. **Use fixtures** - Keep test data in YAML files
5. **Reset state** - Clean up after tests that modify global state
6. **Descriptive names** - Test names should explain what's being tested

