#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 2 ]]; then
  echo "Usage: $0 <input-image> <output-image>" >&2
  exit 1
fi

input_image="$1"
output_image="$2"

if [[ ! -f "$input_image" ]]; then
  echo "Input image not found: $input_image" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_image")"

if command -v magick >/dev/null 2>&1; then
  magick "$input_image" \
    -filter Lanczos \
    -resize 1440x2560^ \
    -gravity center \
    -extent 1440x2560 \
    "$output_image"

  echo "$output_image"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Either ImageMagick 'magick' or 'python3' is required." >&2
  exit 1
fi

python3 - "$input_image" "$output_image" <<'PY'
from PIL import Image
import sys

src_path, dst_path = sys.argv[1], sys.argv[2]
target_w, target_h = 1440, 2560

with Image.open(src_path) as im:
    im = im.convert("RGBA")
    scale = max(target_w / im.width, target_h / im.height)
    resized = im.resize(
        (round(im.width * scale), round(im.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = max((resized.width - target_w) // 2, 0)
    top = max((resized.height - target_h) // 2, 0)
    cropped = resized.crop((left, top, left + target_w, top + target_h))
    cropped.save(dst_path)
PY

echo "$output_image"
