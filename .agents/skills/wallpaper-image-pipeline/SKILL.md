---
name: wallpaper-image-pipeline
description: Use when generating or packaging wallpaper library assets for this project, including selecting category folders under `img/`, enforcing the 1440x2560 original size, creating the 900x1600 webp thumbnail, and writing the companion json metadata file.
---

# Wallpaper Image Pipeline

Use this skill for any wallpaper asset generation task in this repo.

Skill-local helpers:

- batch processor: `scripts/process-wallpaper-batch.mjs`
- daily manifest template: `templates/daily-batch-manifest.json`

## Output contract

Every wallpaper asset set must include:

- original image: `1440x2560`
- thumbnail image: `900x1600` webp
- json metadata file

Path layout:

```text
img/<一级分类>/<二级分类>/<YYYYMMDD>/
  pN.png
  pN.webp
  pN.json
```

Use `img/category.md` for folder taxonomy and `img/README.md` for asset rules when those files exist.
If they are absent in the current checkout, infer the taxonomy from the existing `img/<一级分类>/<二级分类>/` folders and follow the established naming pattern.

## Required workflow

1. Confirm the category path from `img/category.md`.
2. Generate the wallpaper with the built-in `image_gen` tool.
3. Copy the chosen source image into the target date folder.
4. Normalize the generated image with the project resize script:

```bash
bash scripts/upscale-wallpaper.sh <source.png> <target>/pN.png
```

5. Create the thumbnail with the project script:

```bash
bash scripts/make-wallpaper-thumb.sh <target>/pN.png <target>/pN.webp
```

6. Write `pN.json` with at least:
   - `id`
   - `title`
   - `category.primary`
   - `category.secondary`
   - `scene`
   - `prompt`
   - `tags.emotion`
   - `tags.style`
   - `tags.color`
   - `files.original`
   - `files.thumbnail`
   - `size.original`
   - `size.thumbnail`
   - `date`
   - `status`

## Batch workflow

For a daily category-wide run, keep the batch logic inside this skill instead of ad hoc repo-root files:

1. Start from `templates/daily-batch-manifest.json`.
2. If needed, copy it to a dated working file under a temp path and adjust prompts, titles, or tags for that day.
3. Generate one source image per manifest item with the built-in `image_gen` tool.
4. Record the generated source image paths in the same order, one path per line, into a temp text file.
5. Run the skill-local processor:

```bash
node .agents/skills/wallpaper-image-pipeline/scripts/process-wallpaper-batch.mjs \
  <manifest.json> \
  <source-list.txt> \
  <YYYYMMDD>
```

6. Verify counts and dimensions after the batch finishes.

Recommended validation:

```bash
find img -path "*/<YYYYMMDD>/*.json" | wc -l
magick identify -format '%wx%h' img/<一级分类>/<二级分类>/<YYYYMMDD>/pN.png
magick identify -format '%wx%h' img/<一级分类>/<二级分类>/<YYYYMMDD>/pN.webp
```

If `magick` or `cwebp` are unavailable on the local machine, the repo scripts may fall back to `python3` with Pillow for the same resize, crop, and webp-output steps.

Rules for batch mode:

- The manifest order and source-list order must match exactly.
- Keep dated working manifests and source lists outside the skill directory; only the reusable template and processor live in the skill.
- Do not overwrite existing assets unless explicitly asked.
- For `文字` categories, preserve the no-visible-text rule unless the user explicitly changes that requirement.
- If the user explicitly wants readable text in a `文字` wallpaper, prefer a two-step pipeline:
  1. generate a clean background with a centered text-safe area
  2. overlay the final Chinese copy programmatically after resize so the delivered wallpaper contains reliable readable text

## Prompt rules

- Default target is a premium mobile wallpaper.
- Keep all key elements inside the middle 70% to 80% area.
- Reserve a 10% to 15% safe margin on all sides.
- Do not include faces, hands, visible text, watermark, or logos.
- Ask for a clean 9:16 portrait composition suitable for `1440x2560`.

Exception for `文字` categories:

- If the user explicitly requests visible copy, ask the model for a no-text background with typography-safe negative space, then add the final text during post-processing.

## Notes

- The current project baseline is the `p2` approach: use ImageMagick Lanczos resize directly to normalize to `1440x2560`.
- Do not use the previous Real-ESRGAN ncnn path as the default pipeline. It produced visible block artifacts on this project machine.
- Do not overwrite an existing asset unless the user explicitly asks for replacement.
