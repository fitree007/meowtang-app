"""Turn the 3D mascot renders into app assets.

For every source image (white background, 1024x1536):
  1. match it to a mascot id by comparing with labelled thumbnails,
  2. make the white background transparent (flood fill from the borders,
     so white fur inside the character is kept) with a soft edge,
  3. resize to 512x768 and save as WebP with alpha in assets/mascots/<id>.webp.

Usage:
  python tool/mascots/process_mascots.py <downloads_dir> <thumbs_dir> [--default <default_image>]
  python tool/mascots/process_mascots.py <downloads_dir> <thumbs_dir> --accessories

--accessories writes assets/mascots/acc/<id>.webp instead, trimmed to the
object and at most 384 px on the long side, keeping its own aspect ratio.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "mascots"
OUT_SIZE = (512, 768)


def remove_white_background(img: Image.Image) -> Image.Image:
    rgb = np.asarray(img.convert("RGB")).astype(np.int16)
    min_c = rgb.min(axis=2)
    chroma = rgb.max(axis=2) - min_c
    near_white = (min_c >= 236) & (chroma <= 14)

    # Flood fill from every border pixel that is near-white: only background
    # connected to the edge is removed, so white fur inside the outline stays.
    h, w = near_white.shape
    bg = np.zeros_like(near_white)
    stack = [(y, x) for x in range(w) for y in (0, h - 1) if near_white[y, x]]
    stack += [(y, x) for y in range(h) for x in (0, w - 1) if near_white[y, x]]
    while stack:
        y, x = stack.pop()
        if bg[y, x] or not near_white[y, x]:
            continue
        bg[y, x] = True
        if y > 0:
            stack.append((y - 1, x))
        if y < h - 1:
            stack.append((y + 1, x))
        if x > 0:
            stack.append((y, x - 1))
        if x < w - 1:
            stack.append((y, x + 1))

    alpha = np.where(bg, 0, 255).astype(np.uint8)
    # Soft edge: blur the hard mask a little, but never make the subject
    # more transparent than a light 2px ramp.
    a = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(1.2))
    rgba = img.convert("RGBA")
    rgba.putalpha(a)
    return rgba


def signature(img: Image.Image) -> np.ndarray:
    # Flatten transparent pictures onto white so they compare with the
    # white-background thumbnails.
    flat = Image.new("RGBA", img.size, (255, 255, 255, 255))
    flat.alpha_composite(img.convert("RGBA"))
    return np.asarray(flat.convert("RGB").resize((24, 36), Image.BILINEAR)).astype(np.float32)


def match(src: Image.Image, thumbs: dict) -> tuple:
    s = signature(src)
    scored = sorted((float(np.abs(s - t).mean()), k) for k, t in thumbs.items())
    return scored[0]


def already_transparent(img: Image.Image) -> bool:
    if img.mode not in ("RGBA", "LA", "PA") and "transparency" not in img.info:
        return False
    a = np.asarray(img.convert("RGBA"))[..., 3]
    return (a < 10).mean() > 0.05


ACC_DIR = OUT_DIR / "acc"
ACC_MAX = 384


def process(src_path: Path, mascot_id: str, accessory: bool = False) -> Path:
    img = Image.open(src_path)
    cut = img.convert("RGBA") if already_transparent(img) else remove_white_background(img)
    if accessory:
        # Trim to the object so the app can place it by its own bounds.
        box = cut.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
        cut = cut.crop(box)
        scale = ACC_MAX / max(cut.size)
        if scale < 1:
            cut = cut.resize((round(cut.width * scale), round(cut.height * scale)), Image.LANCZOS)
        out_dir = ACC_DIR
    else:
        cut = cut.resize(OUT_SIZE, Image.LANCZOS)
        out_dir = OUT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{mascot_id}.webp"
    cut.save(out, "WEBP", quality=88, method=6)
    return out


def main():
    args = sys.argv[1:]
    accessory = "--accessories" in args
    if accessory:
        args.remove("--accessories")
    default = None
    if "--default" in args:
        i = args.index("--default")
        default = Path(args[i + 1])
        del args[i : i + 2]
    downloads, thumbs_dir = (Path(a) for a in args[:2]) if len(args) >= 2 else (None, None)

    if default:
        out = process(default, "cat_meowtang")
        print(f"cat_meowtang <- {default.name}  ({out.stat().st_size // 1024} KB)")

    if downloads:
        thumbs = {
            p.stem: signature(Image.open(p))
            for p in thumbs_dir.iterdir()
            if p.suffix.lower() in {".png", ".jpg", ".jpeg"}
        }
        used = {}
        for p in sorted(downloads.iterdir()):
            if p.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
                continue
            score, mid = match(Image.open(p), thumbs)
            if mid in used:
                print(f"SKIP {p.name}: also matches {mid} (already {used[mid]})")
                continue
            used[mid] = p.name
            out = process(p, mid, accessory)
            print(f"{mid} <- {p.name}  diff={score:.1f}  ({out.stat().st_size // 1024} KB)")
        missing = sorted(set(thumbs) - set(used))
        if missing:
            print("MISSING:", ", ".join(missing))


if __name__ == "__main__":
    main()
