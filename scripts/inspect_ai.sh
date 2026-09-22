#!/usr/bin/env bash
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: inspect_ai.sh SOURCE.ai [OUTPUT_DIR]" >&2
  exit 2
fi

src="$1"
out="${2:-./ai_inspect}"
mkdir -p "$out"

if [ ! -f "$src" ]; then
  echo "Source not found: $src" >&2
  exit 2
fi

file "$src" > "$out/file.txt" 2>&1 || true

if command -v pdfinfo >/dev/null 2>&1; then
  pdfinfo "$src" > "$out/pdfinfo.txt" 2>&1 || true
fi

if command -v pdftotext >/dev/null 2>&1; then
  pdftotext -layout "$src" "$out/text.txt" 2> "$out/pdftotext.err" || true
  pdftotext -bbox-layout "$src" "$out/bbox.html" 2>> "$out/pdftotext.err" || true
fi

if command -v pdftoppm >/dev/null 2>&1; then
  pdftoppm -png -r 72 "$src" "$out/artboard" > "$out/render.out" 2> "$out/render.err" || true
fi

printf 'Inspection output: %s\n' "$out"
find "$out" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || ls -1 "$out"
