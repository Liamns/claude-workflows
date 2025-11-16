#!/bin/bash
# .claude/lib/reusability/__tests__/benchmark-find-optimization.sh

echo "=== Find Optimization Benchmark ==="
echo ""

# Before (중복 find)
echo "Before (중복 find 실행):"
time bash -c '
for i in {1..5}; do
  find . -name "*.tsx" -o -name "*.ts" > /dev/null
done
' 2>&1 | grep real

# After (캐싱)
echo "After (캐싱 후 재사용):"
time bash -c '
all_tsx_ts_files=$(find . -name "*.tsx" -o -name "*.ts")
for i in {1..5}; do
  echo "$all_tsx_ts_files" > /dev/null
done
' 2>&1 | grep real

echo ""
echo "=== Benchmark Complete ==="
