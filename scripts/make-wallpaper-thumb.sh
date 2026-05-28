#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <input-image> <output-webp> [quality]" >&2
  exit 1
fi

input_image="$1"
output_webp="$2"
quality="${3:-82}"

if [[ ! -f "$input_image" ]]; then
  echo "Input image not found: $input_image" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_webp")"

if command -v magick >/dev/null 2>&1 && command -v cwebp >/dev/null 2>&1; then
  tmp_png="$(mktemp /tmp/wallpaper-thumb.XXXXXX.png)"
  cleanup() {
    rm -f "$tmp_png"
  }
  trap cleanup EXIT

  magick "$input_image" \
    -resize 900x1600^ \
    -gravity center \
    -extent 900x1600 \
    "$tmp_png"

  cwebp -quiet -q "$quality" "$tmp_png" -o "$output_webp"
  echo "$output_webp"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Either ImageMagick+cwebp or 'python3' with Pillow is required." >&2
  exit 1
fi

python3 - "$input_image" "$output_webp" "$quality" <<'PY'
from PIL import Image
import sys

src_path, dst_path, quality = sys.argv[1], sys.argv[2], int(sys.argv[3])
target_w, target_h = 900, 1600

with Image.open(src_path) as im:
    im = im.convert("RGB")
    scale = max(target_w / im.width, target_h / im.height)
    resized = im.resize(
        (round(im.width * scale), round(im.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = max((resized.width - target_w) // 2, 0)
    top = max((resized.height - target_h) // 2, 0)
    cropped = resized.crop((left, top, left + target_w, top + target_h))
    cropped.save(dst_path, format="WEBP", quality=quality, method=6)
PY

echo "$output_webp"
