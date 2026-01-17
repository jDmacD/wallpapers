#!/usr/bin/env nix-shell
#!nix-shell -i bash -p imagemagick

set -euo pipefail

# Accept input directory as argument, default to "unsorted"
INPUT_DIR="${1:-unsorted}"

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' does not exist"
    echo "Usage: $0 [input_directory]"
    exit 1
fi

processed=0
failed=0

# Collect all image files into an array first
image_files=()
for img in "$INPUT_DIR"/*; do
    [ -f "$img" ] && image_files+=("$img")
done

# Process each image
for img in "${image_files[@]}"; do
    filename=$(basename "$img")

    # Get image dimensions using ImageMagick
    dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null || echo "")

    if [ -z "$dimensions" ]; then
        echo "Warning: Could not read dimensions for $filename"
        failed=$((failed + 1))
        continue
    fi

    # Create directory if it doesn't exist
    if [ ! -d "$dimensions" ]; then
        echo "Creating directory: $dimensions/"
        mkdir -p "$dimensions"
    fi

    # Move the image
    echo "Moving $filename -> $dimensions/"
    mv "$img" "$dimensions/"
    processed=$((processed + 1))
done

echo ""
echo "Done! Processed: $processed, Failed: $failed"
