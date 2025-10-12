#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "⚠️  SwiftLint not installed. Skipping."
  exit 0
fi

echo "🔍 Running SwiftLint with strict mode..."
swiftlint --strict
