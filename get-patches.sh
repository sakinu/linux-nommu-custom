#!/bin/bash

project_DIR="$(cd "$(dirname "$0")/.." && pwd)"

buildroot_DIR="$project_DIR/buildroot-2026.02-rc2"
repo_DIR="$project_DIR/repo"

target=$1   # linux or buildroot

case "$target" in
    linux)
        target_DIR="$buildroot_DIR/output/build/linux-7.0.3"
        output_DIR="$repo_DIR/patches/linux"
        ;;
    buildroot)
        target_DIR="$buildroot_DIR"
        output_DIR="$repo_DIR/patches/buildroot"
        ;;
    *)
        echo "ERROR: no target $target"
        exit 1
        ;;
esac

echo "target_DIR = $target_DIR" 
echo "output_DIR = $output_DIR" 

cd "$target_DIR" || { echo "ERROR: cannot cd to $target_DIR"; exit 1; }

BASELINE=$(git rev-list --max-parents=0 HEAD 2>/dev/null)
if [ -z "$BASELINE" ]; then
    echo "ERROR: no baseline commit found"
    exit 1
fi
echo "baseline = $(git log --oneline -1 "$BASELINE")"

mkdir -p "$output_DIR"
rm -f "$output_DIR/*.patch"

git format-patch $(git rev-list --max-parents=0 HEAD) --output-directory="$output_DIR"

echo "=== Generated patches ==="
ls -la "$outputDIR"/