# Contributing

Thank you for your interest in contributing to MywayConfig!

## Getting Started

### Prerequisites

- Ruby 3.2 or later
- Git
- Bundler

### Setup

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/myway_config.git
cd myway_config

# Install dependencies
bin/setup

# Verify everything works
bundle exec rake test
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Write code following the existing style
- Add tests for new functionality
- Update documentation if needed

### 3. Run Tests

```bash
# Run all tests
bundle exec rake test

# Run a specific test file
bundle exec ruby -Itest test/test_myway_config.rb

# Run a specific test
bundle exec ruby -Itest test/test_myway_config.rb -n test_auto_configure
```

### 4. Check Coverage

```bash
# Run tests with coverage
bundle exec rake test

# Coverage report is displayed after tests complete
```

The project uses `single_cov` for line-level coverage. All lines should be covered.

### 5. Commit Changes

```bash
git add .
git commit -m "Add feature: description of changes"
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Code Style

### Ruby Style

- Use 2 spaces for indentation
- Use `frozen_string_literal: true` pragma
- Prefer `do...end` for multi-line blocks
- Prefer `{ }` for single-line blocks

### Documentation

- Add YARD documentation for public methods
- Update guides for user-facing changes
- Include examples in documentation

### Testing

- Write tests for all new code
- Test edge cases and error conditions
- Use descriptive test names

## Project Structure

```
lib/
├── myway_config.rb              # Entry point
└── myway_config/
    ├── base.rb                  # Configuration base class
    ├── config_section.rb        # Hash-like wrapper
    ├── version.rb               # Version number
    └── loaders/
        ├── defaults_loader.rb   # Bundled defaults
        └── xdg_config_loader.rb # XDG paths
```

## Adding Features

### New Configuration Option

1. Add to `defaults.yml` if applicable
2. Add accessor method if needed
3. Add tests
4. Update documentation

### New Loader

1. Create loader in `lib/myway_config/loaders/`
2. Extend `Anyway::Loaders::Base`
3. Register in `MywayConfig.setup!`
4. Add tests
5. Document in `docs/api/loaders.md`

### New ConfigSection Method

1. Add method to `config_section.rb`
2. Add YARD documentation
3. Add tests
4. Update `docs/api/config-section.md`

## Running the Demo

```bash
# Run the demo application
ruby examples/xyzzy.rb

# With different environments
RACK_ENV=production ruby examples/xyzzy.rb
RACK_ENV=test ruby examples/xyzzy.rb

# With environment variable overrides
XYZZY_DATABASE__HOST=custom-db.local ruby examples/xyzzy.rb
```

## Interactive Console

```bash
# Start IRB with the gem loaded
bin/console

# Or from the examples directory
cd examples
irb -r ./xyzzy.rb
```

## Documentation

Documentation is built with MkDocs and Material theme.

### Preview Documentation

```bash
# Install MkDocs (if not installed)
pip install mkdocs mkdocs-material

# Serve documentation locally
mkdocs serve

# Build static site
mkdocs build
```

### Documentation Structure

```
docs/
├── index.md                 # Home page
├── getting-started/         # Installation and quick start
├── guides/                  # Usage guides
├── examples/                # Real-world examples
├── api/                     # API reference
└── development/             # Contributing info
```

## Releasing

Releases are managed by maintainers:

1. Update `lib/myway_config/version.rb`
2. Update `CHANGELOG.md`
3. Commit: `git commit -m "Release vX.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push origin main --tags`
6. Build and publish: `gem build && gem push myway_config-X.Y.Z.gem`

## Getting Help

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Provide reproduction steps for bugs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

