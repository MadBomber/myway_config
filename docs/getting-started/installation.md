# Installation

## Using Bundler (Recommended)

Add MywayConfig to your application's Gemfile:

```ruby
gem "myway_config"
```

Then run:

```bash
bundle install
```

## Manual Installation

If you're not using Bundler, install the gem directly:

```bash
gem install myway_config
```

Then require it in your code:

```ruby
require "myway_config"
```

## Dependencies

MywayConfig depends on:

- **anyway_config** (>= 2.0) - The underlying configuration framework

These dependencies are automatically installed when you install the gem.

## Verifying Installation

You can verify the installation by checking the version:

```ruby
require "myway_config"
puts MywayConfig::VERSION
```

## Next Steps

Now that you have MywayConfig installed, head to the [Quick Start](quick-start.md) guide to create your first configuration.
