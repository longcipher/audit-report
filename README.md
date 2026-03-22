# Bash Template

A modern Bash shell script template with comprehensive tooling for package management, formatting, linting, and testing.

## Features

- **Package Management**: Basher integration
- **Code Formatting**: shfmt with consistent style
- **Linting**: ShellCheck for static analysis
- **Testing**: Bats-core for unit testing
- **Task Running**: Just for command management

## Quick Start

### Prerequisites

Install the required tools:

```bash
# Install shfmt (shell formatter)
go install mvdan.cc/sh/v3/cmd/shfmt@latest

# Install shellcheck (shell linter)
brew install shellcheck

# Install bats-core (testing framework)
brew install bats-core

# Install just (command runner)
brew install just
```

### Installation

```bash
# Clone the template
git clone <repository-url>
cd bash-template

# Install dependencies
just install

# Run the application
just run hello "World"
```

### Package Management with Basher

This template uses [basher](https://github.com/basherpm/basher) for package management:

```bash
# Install basher (if not already installed)
git clone https://github.com/basherpm/basher.git ~/.basher
~/.basher/bin/basher init

# Install a package
basher install <username>/<package>

# List installed packages
basher list
```

## Project Structure

```
bash-template/
├── bin/                    # Executable scripts
│   └── bash-app            # Main application entry point
├── lib/                    # Library functions
│   └── bash_app/
│       ├── core.sh         # Core business logic
│       └── utils.sh        # Utility functions
├── tests/                  # Test files
│   ├── core.bats           # Core function tests
│   ├── utils.bats          # Utility function tests
│   └── test_helper.bash    # Test helper functions
├── scripts/                # Build and utility scripts
├── .shellcheckrc           # ShellCheck configuration
├── .editorconfig           # Editor configuration
├── Justfile                # Task runner commands
├── CLAUDE.md               # Claude AI instructions
└── README.md               # Project documentation
```

## Usage

### Running the Application

```bash
# Show help
./bin/bash-app --help

# Say hello
./bin/bash-app hello
./bin/bash-app hello "Alice"

# Process a file
./bin/bash-app process myfile.txt

# Validate input
./bin/bash-app validate "some input"
```

### Development Commands

```bash
# Format code
just format

# Lint code
just lint

# Run tests
just test

# Run all checks
just check

# Build for production
just build
```

## Code Style

### Shell Script Standards

1. **Strict Mode**: Always use `set -euo pipefail`
2. **ShellCheck Compliance**: All code must pass ShellCheck
3. **Consistent Formatting**: 4-space indentation with shfmt
4. **Error Handling**: Handle errors explicitly
5. **Function Documentation**: Document all functions

### Naming Conventions

- **Files**: `lowercase-with-hyphens.sh`
- **Functions**: `lowercase_with_underscores()`
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Variables**: `lowercase_with_underscores`

## Testing

### Running Tests

```bash
# Run all tests
just test

# Run specific test file
just test-file tests/core.bats

# Run with verbose output
just test-verbose
```

### Writing Tests

```bash
setup() {
    load 'test_helper'
    common_setup
}

@test "descriptive test name" {
    run function_under_test "input"
    [ "$status" -eq 0 ]
    [ "$output" = "expected" ]
}
```

## Configuration

### ShellCheck (.shellcheckrc)

```bash
# Enable all checks
enable=all

# Disable specific checks
disable=SC1091  # Not following non-constant source
disable=SC2034  # Unused variables
```

### EditorConfig (.editorconfig)

```ini
[*.sh]
indent_style = space
indent_size = 4
shell_variant = bash
```

## CI/CD Integration

The template is designed for easy CI/CD integration:

```yaml
# Example GitHub Actions
- name: Check code quality
  run: just check

- name: Run tests
  run: just test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `just check` to verify
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [shfmt](https://github.com/mvdan/sh) - Shell formatter
- [ShellCheck](https://github.com/koalaman/shellcheck) - Shell linter
- [Bats-core](https://github.com/bats-core/bats-core) - Testing framework
- [Just](https://github.com/casey/just) - Command runner
- [Basher](https://github.com/basherpm/basher) - Package manager
