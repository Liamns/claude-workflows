#!/bin/bash
#
# Architecture Compliance Check Wrapper
#
# This script executes the architecture validation and handles user interaction.
#

set -euo pipefail

echo "🏗️  Architecture Compliance Check..."
echo ""

# Determine project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# Path to validation script
VALIDATE_SCRIPT=".claude/architectures/tools/validate.ts"

if [ ! -f "$VALIDATE_SCRIPT" ]; then
  echo "❌ Error: Validation script not found at $VALIDATE_SCRIPT"
  exit 1
fi

# Try to run with different methods
RUN_SUCCESS=false

# Method 1: Try tsx (fastest, modern)
if command -v tsx &> /dev/null; then
  echo "🔧 Running with tsx..."
  if tsx "$VALIDATE_SCRIPT"; then
    RUN_SUCCESS=true
  fi
# Method 2: Try ts-node
elif command -v ts-node &> /dev/null; then
  echo "🔧 Running with ts-node..."
  if ts-node "$VALIDATE_SCRIPT"; then
    RUN_SUCCESS=true
  fi
# Method 3: Try node with --loader (Node 18+)
elif node --version | grep -qE 'v(1[8-9]|[2-9][0-9])'; then
  echo "🔧 Running with Node.js loader..."
  if node --loader ts-node/esm "$VALIDATE_SCRIPT" 2>/dev/null; then
    RUN_SUCCESS=true
  fi
# Method 4: Compile and run
else
  echo "⚠️  ts-node not found. Attempting to compile TypeScript..."

  # Check if tsc is available
  if command -v tsc &> /dev/null; then
    TEMP_OUT="/tmp/validate-$(date +%s).js"
    if tsc --skipLibCheck --esModuleInterop --module commonjs --target es2020 "$VALIDATE_SCRIPT" --outFile "$TEMP_OUT"; then
      if node "$TEMP_OUT"; then
        RUN_SUCCESS=true
      fi
      rm -f "$TEMP_OUT"
    fi
  else
    echo "❌ Error: No TypeScript execution environment found"
    echo "   Please install one of: tsx, ts-node, or tsc"
    exit 1
  fi
fi

# Check result
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "❌ Architecture violations detected!"
  echo ""

  # Check if running in interactive mode
  if [ -t 0 ]; then
    echo "Do you want to continue despite violations? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "🛑 Aborting due to architecture violations..."
      exit 1
    fi
    echo "⚠️  Continuing with violations (not recommended)..."
  else
    # Non-interactive mode - fail
    echo "🛑 Aborting in non-interactive mode..."
    exit 1
  fi
fi

echo ""
echo "✅ Architecture compliance check completed"
exit 0
