# Rails Integration

Using MywayConfig in Rails applications.

## Setup

### Gemfile

```ruby
gem 'myway_config'
```

### Configuration Class

```ruby
# app/config/my_app_config.rb
# or lib/my_app/config.rb

class MyAppConfig < MywayConfig::Base
  config_name :myapp
  env_prefix  :myapp
  defaults_path Rails.root.join("config/myapp_defaults.yml").to_s
  auto_configure!
end
```

### Defaults File

```yaml
# config/myapp_defaults.yml
defaults:
  feature_flags:
    new_checkout: false
    dark_mode: true

  external_api:
    base_url: https://api.example.com
    timeout: 30
    api_key: null  # Set via environment variable

  cache:
    ttl: 3600
    namespace: myapp

development:
  feature_flags:
    new_checkout: true
  cache:
    ttl: 60

production:
  external_api:
    timeout: 10
  cache:
    ttl: 86400

test:
  cache:
    ttl: 0
```

### Initializer

```ruby
# config/initializers/myapp_config.rb

Rails.application.config.myapp = MyAppConfig.new

# Convenience method
def MyApp
  Rails.application.config.myapp
end
```

## Usage in Rails

### Controllers

```ruby
class CheckoutsController < ApplicationController
  def new
    if MyApp.feature_flags.new_checkout
      render :new_checkout
    else
      render :legacy_checkout
    end
  end
end
```

### Models

```ruby
class Order < ApplicationRecord
  def sync_to_external_api
    client = ExternalApi::Client.new(
      base_url: MyApp.external_api.base_url,
      timeout: MyApp.external_api.timeout,
      api_key: MyApp.external_api.api_key
    )
    client.create_order(self)
  end
end
```

### Views

```erb
<% if MyApp.feature_flags.dark_mode %>
  <%= stylesheet_link_tag "dark_mode" %>
<% end %>
```

### Jobs

```ruby
class SyncJob < ApplicationJob
  def perform(record_id)
    timeout = MyApp.external_api.timeout

    Timeout.timeout(timeout) do
      # Sync logic
    end
  end
end
```

## Environment Detection

MywayConfig automatically detects the Rails environment:

```ruby
config = MyAppConfig.new

config.environment    # => "development" (from RAILS_ENV)
config.development?   # => true
config.production?    # => false
config.test?          # => false
```

## Credentials Integration

Combine with Rails credentials for secrets:

```yaml
# config/myapp_defaults.yml
defaults:
  external_api:
    base_url: https://api.example.com
    api_key: null  # Loaded from credentials
```

```ruby
# config/initializers/myapp_config.rb

config = MyAppConfig.new

# Override API key from credentials
if Rails.application.credentials.dig(:external_api, :api_key)
  config.external_api.api_key = Rails.application.credentials.external_api.api_key
end

Rails.application.config.myapp = config
```

Or use environment variables:

```bash
# In production
MYAPP_EXTERNAL_API__API_KEY=your_secret_key
```

## Testing

### RSpec

```ruby
# spec/support/config_helpers.rb
module ConfigHelpers
  def with_config(overrides)
    original = Rails.application.config.myapp
    Rails.application.config.myapp = MyAppConfig.new(overrides)
    yield
  ensure
    Rails.application.config.myapp = original
  end
end

RSpec.configure do |config|
  config.include ConfigHelpers
end
```

```ruby
# spec/models/order_spec.rb
RSpec.describe Order do
  describe "#sync_to_external_api" do
    it "uses configured timeout" do
      with_config(external_api: { timeout: 5 }) do
        # Test with 5 second timeout
      end
    end
  end
end
```

### Minitest

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  def with_config(overrides, &block)
    original = Rails.application.config.myapp
    Rails.application.config.myapp = MyAppConfig.new(overrides)
    yield
  ensure
    Rails.application.config.myapp = original
  end
end
```

## Multiple Configurations

For complex applications:

```ruby
# config/initializers/configs.rb

Rails.application.config.features = FeaturesConfig.new
Rails.application.config.integrations = IntegrationsConfig.new
Rails.application.config.limits = LimitsConfig.new

# Convenience methods
def Features; Rails.application.config.features; end
def Integrations; Rails.application.config.integrations; end
def Limits; Rails.application.config.limits; end
```

## Best Practices

### 1. Keep Secrets Out of YAML

```yaml
# Bad - secrets in YAML
defaults:
  api_key: sk_live_abc123

# Good - use null placeholder
defaults:
  api_key: null
```

Set secrets via environment variables:

```bash
MYAPP_API_KEY=sk_live_abc123
```

### 2. Use Environment-Specific Overrides

```yaml
defaults:
  cache_ttl: 3600

development:
  cache_ttl: 60  # Short TTL for development

test:
  cache_ttl: 0   # No caching in tests
```

### 3. Validate in Initializer

```ruby
# config/initializers/myapp_config.rb

config = MyAppConfig.new

# Validate required values
if config.production? && config.external_api.api_key.nil?
  raise "MYAPP_EXTERNAL_API__API_KEY must be set in production"
end

Rails.application.config.myapp = config
```

### 4. Document Configuration

```yaml
# config/myapp_defaults.yml

# Feature Flags
# Control feature rollout without deploys
defaults:
  feature_flags:
    # Enable new checkout flow (default: disabled)
    new_checkout: false

    # Enable dark mode theme (default: enabled)
    dark_mode: true
```

