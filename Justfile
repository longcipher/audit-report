# Default recipe to display help
default:
    @just --list

# ============================================================
# Code Quality
# ============================================================

# Format all code
format:
    @echo "Formatting shell scripts..."
    @command -v shfmt >/dev/null 2>&1 && shfmt -i 4 -bn -ci -sr -w bin/ lib/ tests/ || echo "⚠️  shfmt not installed"
    rumdl fmt .

# Check formatting without modifying
format-check:
    @echo "Checking formatting..."
    @command -v shfmt >/dev/null 2>&1 && shfmt -i 4 -bn -ci -sr -d bin/ lib/ tests/ || echo "⚠️  shfmt not installed"

# Auto-fix linting issues
fix:
    @echo "Auto-fixing lint issues..."
    @shellcheck --format=fix bin/* lib/**/*.sh 2>/dev/null || true
    agnix --fix

# Run all lints
lint:
    @echo "Linting shell scripts..."
    @command -v shellcheck >/dev/null 2>&1 && shellcheck bin/* lib/**/*.sh || echo "⚠️  shellcheck not installed"
    @command -v shellcheck >/dev/null 2>&1 && shellcheck --shell=bash tests/*.bats || true
    agnix .
    rumdl check .

# Lint with strict mode
lint-strict:
    @echo "Linting shell scripts (strict mode)..."
    @shellcheck -S warning bin/* lib/**/*.sh tests/*.bats

# ============================================================
# Testing
# ============================================================

# Run unit tests
test:
    @echo "Running tests..."
    @command -v bats >/dev/null 2>&1 && bats tests/ || echo "⚠️  bats not installed"

# Run tests with verbose output
test-verbose:
    @echo "Running tests (verbose)..."
    @bats --tap tests/

# Run specific test file
test-file file:
    @echo "Running tests in {{file}}..."
    @bats {{file}}

# Run BDD scenarios
bdd:
    @echo "BDD not configured yet. Add Gherkin features under features/"

# Run both TDD and BDD suites
test-all:
    @bats tests/

# Run tests with coverage (if kcov is installed)
test-coverage:
    @echo "Running tests with coverage..."
    @kcov --include-path=lib/ coverage/ bats tests/

# ============================================================
# Full Checks
# ============================================================

# Run all checks (format, lint, test)
check: format-check lint test

# Full CI check
ci: lint test-all

# ============================================================
# Application
# ============================================================

# Run the application
run *args:
    @echo "Running audit-report..."
    @bin/audit-report {{args}}

# Build for production
build:
    @echo "Building audit-report..."
    @rm -rf dist
    @mkdir -p dist/bin dist/lib/audit-report
    @cp bin/audit-report dist/bin/
    @cp lib/audit-report/*.sh dist/lib/audit-report/
    @chmod +x dist/bin/audit-report

# Install the application system-wide
install-app:
    @echo "Installing audit-report..."
    @install -m755 bin/audit-report /usr/local/bin/audit-report
    @install -d /usr/local/lib/audit-report
    @install -m644 lib/audit-report/*.sh /usr/local/lib/audit-report/

# ============================================================
# Maintenance & Tools
# ============================================================

# Clean build artifacts
clean:
    @echo "Cleaning..."
    @rm -rf dist/ coverage/ .bats/
    @find . -type f -name "*.log" -delete 2>/dev/null || true

# Install all required development tools
setup:
    @echo "Installing development tools..."
    @command -v shfmt >/dev/null 2>&1 || { echo "Installing shfmt..."; go install mvdan.cc/sh/v3/cmd/shfmt@latest; }
    @command -v shellcheck >/dev/null 2>&1 || { echo "Installing shellcheck..."; brew install shellcheck; }
    @command -v bats >/dev/null 2>&1 || { echo "Installing bats-core..."; brew install bats-core; }
    @command -v git-cliff >/dev/null 2>&1 || { echo "Installing git-cliff..."; brew install git-cliff; }

# Generate changelog
changelog:
    @echo "Generating changelog..."
    @git-cliff -o CHANGELOG.md

# Check for Chinese characters
check-cn:
    @rg --line-number --column "\p{Han}" || echo "No Chinese characters found"

# Watch for changes and run tests
watch:
    @echo "Watching for changes..."
    @while true; do \
        inotifywait -q -e modify bin/ lib/ tests/ 2>/dev/null || sleep 2; \
        just check; \
    done

# Show help
help:
    @echo "Bash Template - Available Commands:"
    @echo ""
    @echo "  format       - Format code with shfmt"
    @echo "  lint         - Lint code with shellcheck"
    @echo "  test         - Run tests with bats"
    @echo "  check        - Run all checks (format, lint, test)"
    @echo "  ci           - Full CI check"
    @echo "  run          - Run the application"
    @echo "  build        - Build for production"
    @echo "  clean        - Clean build artifacts"
    @echo "  setup        - Install development tools"
    @echo "  changelog    - Generate changelog"
