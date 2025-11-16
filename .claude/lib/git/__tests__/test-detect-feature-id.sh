#!/bin/bash
# .claude/lib/git/__tests__/test-detect-feature-id.sh

# Test suite for detect-feature-id.sh

# Source the function
source .claude/lib/git/detect-feature-id.sh

# Test 1: Feature ID 있음
test_feature_id_exists() {
  echo "- Feature ID: 007" > /tmp/test-spec.md
  result=$(detect_feature_id "/tmp/test-spec.md")
  if [ "$result" == "007" ]; then
    echo "✓ Test 1 passed: Feature ID detected"
  else
    echo "✗ Test 1 failed: Expected '007', got '$result'"
    return 1
  fi
  rm /tmp/test-spec.md
}

# Test 2: Feature ID 없음
test_feature_id_missing() {
  echo "No Feature ID" > /tmp/test-spec.md
  result=$(detect_feature_id "/tmp/test-spec.md")
  if [ -z "$result" ]; then
    echo "✓ Test 2 passed: Empty string for missing Feature ID"
  else
    echo "✗ Test 2 failed: Expected '', got '$result'"
    return 1
  fi
  rm /tmp/test-spec.md
}

# Test 3: 파일 없음
test_file_not_found() {
  result=$(detect_feature_id "/tmp/nonexistent-spec.md")
  if [ -z "$result" ]; then
    echo "✓ Test 3 passed: Empty string for missing file"
  else
    echo "✗ Test 3 failed: Expected '', got '$result'"
    return 1
  fi
}

# Test 4: 다른 경로의 spec.md
test_different_path() {
  mkdir -p /tmp/test-feature
  echo "- Feature ID: 001" > /tmp/test-feature/spec.md
  result=$(detect_feature_id "/tmp/test-feature/spec.md")
  if [ "$result" == "001" ]; then
    echo "✓ Test 4 passed: Feature ID from different path"
  else
    echo "✗ Test 4 failed: Expected '001', got '$result'"
    return 1
  fi
  rm -rf /tmp/test-feature
}

# Run all tests
echo "Running detect-feature-id.sh tests..."
test_feature_id_exists && \
test_feature_id_missing && \
test_file_not_found && \
test_different_path

if [ $? -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
