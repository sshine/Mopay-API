# Default recipe: list available commands
default:
    @just --list

# Format all code (Rust + Nix + Markdown)
fmt:
    treefmt

# Check formatting (Rust + Nix + Markdown)
fmt-check:
    treefmt --fail-on-change --no-cache

# Run clippy lints
lint:
    cargo clippy --all-targets --all-features -- -D warnings

# Run all tests
test:
    cargo test --all-features

# Run tests with verbose output
test-verbose:
    cargo test --all-features -- --nocapture

# Build release
build:
    cargo build --release --all-features

# Generate documentation
doc *args='':
    cargo doc --no-deps --all-features {{args}}

readme_args := "--project-root crates/mopay-mcp --input src/main.rs --template ../../README.tpl"

# Regenerate README.md from README.tpl and the CLI docs
readme:
    cargo readme {{readme_args}} | mdformat - > README.md

# Check README.md is in sync with README.tpl and the CLI docs
readme-check:
    cargo readme {{readme_args}} | mdformat - | diff - README.md

# Run CI checks locally
ci: fmt-check lint test doc readme-check build
    @echo "All CI checks passed!"

# Watch for changes and run tests
watch:
    cargo watch -x test

# Clean build artifacts
clean:
    cargo clean

# Review snapshot test changes
snap:
    cargo insta test --review
