# Development

Information for contributing to MywayConfig.

## Guides

### [Contributing](contributing.md)

How to contribute to the project:

- Setting up the development environment
- Making changes
- Submitting pull requests

### [Testing](testing.md)

Running and writing tests:

- Test suite overview
- Running tests
- Code coverage

## Quick Start

```bash
# Clone the repository
git clone https://github.com/madbomber/myway_config.git
cd myway_config

# Install dependencies
bin/setup

# Run tests
bundle exec rake test

# Start interactive console
bin/console
```

## Project Structure

```
myway_config/
├── lib/
│   ├── myway_config.rb          # Main module and setup
│   └── myway_config/
│       ├── base.rb              # Base configuration class
│       ├── config_section.rb    # Hash-like wrapper
│       ├── version.rb           # Version constant
│       └── loaders/
│           ├── defaults_loader.rb     # Bundled defaults loader
│           └── xdg_config_loader.rb   # XDG config loader
├── test/
│   ├── test_helper.rb           # Test setup
│   ├── test_myway_config.rb     # Main tests
│   └── fixtures/                # Test YAML files
├── examples/
│   ├── xyzzy.rb                 # Demo application
│   └── config/
│       └── defaults.yml         # Demo defaults
├── docs/                        # MkDocs documentation
└── .github/
    └── workflows/
        └── ci.yml               # GitHub Actions CI
```

## Architecture

MywayConfig extends [Anyway Config](https://github.com/palkan/anyway_config) with:

1. **DefaultsLoader** - Loads bundled YAML defaults
2. **XdgConfigLoader** - Loads user XDG config files
3. **ConfigSection** - Hash-like wrapper with Enumerable
4. **Base** - Configuration base class with `auto_configure!`

### Loading Order

```
DefaultsLoader (lowest priority)
    ↓
XdgConfigLoader
    ↓
Anyway Config loaders (yml, local)
    ↓
Environment variables
    ↓
Constructor overrides (highest priority)
```

## Dependencies

- Ruby 3.2+
- anyway_config (~> 2.0)

### Development Dependencies

- minitest
- rake
- single_cov

