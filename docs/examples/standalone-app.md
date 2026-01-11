# Standalone Application

Using MywayConfig in non-Rails Ruby applications like gems, CLI tools, and background workers.

## Ruby Gem

### Directory Structure

```
my_gem/
├── lib/
│   ├── my_gem.rb
│   └── my_gem/
│       ├── config.rb
│       └── config/
│           └── defaults.yml
├── my_gem.gemspec
└── Gemfile
```

### Configuration Class

```ruby
# lib/my_gem/config.rb
require 'myway_config'

module MyGem
  class Config < MywayConfig::Base
    config_name :my_gem
    env_prefix  :my_gem
    defaults_path File.expand_path("config/defaults.yml", __dir__)
    auto_configure!
  end
end
```

### Defaults File

```yaml
# lib/my_gem/config/defaults.yml
defaults:
  api:
    base_url: https://api.service.com
    timeout: 30
    retries: 3

  cache:
    enabled: true
    ttl: 3600

  log_level: :info
```

### Main Module

```ruby
# lib/my_gem.rb
require_relative 'my_gem/config'

module MyGem
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config if block_given?
    end

    def reset_config!
      @config = nil
    end
  end
end
```

### Usage

```ruby
require 'my_gem'

# Default configuration
MyGem.config.api.base_url  # => "https://api.service.com"

# Environment variable override
# MY_GEM_API__TIMEOUT=60 ruby app.rb
MyGem.config.api.timeout   # => 60

# XDG user config (~/.config/my_gem/my_gem.yml)
# Automatically loaded if present
```

---

## CLI Application

### Using Thor

```ruby
#!/usr/bin/env ruby
require 'thor'
require 'myway_config'

module MyCLI
  class Config < MywayConfig::Base
    config_name :mycli
    env_prefix  :mycli
    defaults_path File.expand_path("../config/defaults.yml", __dir__)
    auto_configure!
  end

  class << self
    def config
      @config ||= Config.new
    end
  end

  class CLI < Thor
    desc "status", "Show current configuration"
    def status
      puts "API URL: #{MyCLI.config.api.base_url}"
      puts "Timeout: #{MyCLI.config.api.timeout}s"
    end

    desc "run", "Run the main task"
    option :verbose, type: :boolean, default: false
    def run
      config = MyCLI.config

      if config.debug || options[:verbose]
        puts "Debug mode enabled"
      end

      # Your application logic
    end
  end
end

MyCLI::CLI.start(ARGV)
```

### Custom Config File

```ruby
class CLI < Thor
  class_option :config, type: :string, desc: "Path to config file"

  desc "run", "Run with optional custom config"
  def run
    config = if options[:config]
               MyCLI::Config.new(options[:config])
             else
               MyCLI.config
             end

    # Use config...
  end
end
```

---

## Background Worker

### Sidekiq Example

```ruby
# config/initializers/sidekiq.rb
require 'myway_config'

module MyWorker
  class Config < MywayConfig::Base
    config_name :my_worker
    env_prefix  :my_worker
    defaults_path File.expand_path("../../config/defaults.yml", __dir__)
    auto_configure!
  end

  class << self
    def config
      @config ||= Config.new
    end
  end
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: MyWorker.config.redis.url,
    pool_size: MyWorker.config.redis.pool_size
  }
end
```

### Worker Class

```ruby
class ProcessingWorker
  include Sidekiq::Worker

  def perform(item_id)
    config = MyWorker.config

    timeout = config.processing.timeout
    retries = config.processing.retries

    # Process with configured settings
  end
end
```

---

## Multiple Configurations

For applications with multiple configuration concerns:

```ruby
module MyApp
  class DatabaseConfig < MywayConfig::Base
    config_name :database
    env_prefix  :myapp_db
    defaults_path File.expand_path("config/database.yml", __dir__)
    auto_configure!
  end

  class ApiConfig < MywayConfig::Base
    config_name :api
    env_prefix  :myapp_api
    defaults_path File.expand_path("config/api.yml", __dir__)
    auto_configure!
  end

  class << self
    def database_config
      @database_config ||= DatabaseConfig.new
    end

    def api_config
      @api_config ||= ApiConfig.new
    end
  end
end

# Usage
MyApp.database_config.host
MyApp.api_config.timeout
```

---

## Testing Configuration

```ruby
# test/test_helper.rb
require 'minitest/autorun'
require 'my_gem'

module TestHelpers
  def with_config(overrides, &block)
    original = MyGem.instance_variable_get(:@config)
    MyGem.instance_variable_set(:@config, MyGem::Config.new(overrides))
    yield
  ensure
    MyGem.instance_variable_set(:@config, original)
  end
end

class MyTest < Minitest::Test
  include TestHelpers

  def test_with_custom_config
    with_config(api: { timeout: 5 }) do
      assert_equal 5, MyGem.config.api.timeout
    end
  end
end
```

