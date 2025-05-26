_default:
  @just --list

# Static analysis
lint:
  dart format --set-exit-if-changed .
  flutter analyze .

# Generate test entrypoint
generate-test-entrypoints:
  dart run tool/generate_test_entrypoints.dart
  dart format test/_test.dart

# Runs all unit and widget tests (with coverage)
test: generate-test-entrypoints
  flutter test test/_test.dart --test-randomize-ordering-seed=random --branch-coverage --coverage-path=coverage/unit_test_lcov.info -j 4

# Generate code for test mocks
generate-code:
  dart run build_runner build --delete-conflicting-outputs
  dart format test/utils/test_mocks.mocks.dart

# Install the project dependencies
get-dependencies:
  flutter pub get

