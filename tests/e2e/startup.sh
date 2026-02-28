#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QEMU_TIMEOUT_SECONDS=8
cd "$REPO_ROOT"

make build

qemu_log="$(mktemp)"
set +e
script -q -e -c "timeout ${QEMU_TIMEOUT_SECONDS}s qemu-system-i386 \
  -drive format=raw,file=boot.bin,if=floppy \
  -nographic -monitor none -serial stdio" "$qemu_log" >/dev/null 2>&1
qemu_status=$?
set -e
qemu_output="$(cat "$qemu_log")"
rm -f "$qemu_log"

if [[ "$qemu_status" -ne 124 ]]; then
  echo "$qemu_output"
  echo "QEMU exited unexpectedly with status $qemu_status"
  exit 1
fi

qemu_output="$(printf '%s' "$qemu_output" | tr -d '\r')"

echo "$qemu_output" | grep -Fq "Booting from Floppy..." || { echo "Missing BIOS floppy boot message."; exit 1; }
echo "$qemu_output" | grep -Fq "hello-os terminal" || { echo "Missing hello-os terminal banner."; exit 1; }
echo "$qemu_output" | grep -Fq "type 'help' or 'clear'" || { echo "Missing startup help text."; exit 1; }

echo "QEMU startup e2e passed."
