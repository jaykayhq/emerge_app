"""
Removes the white/near-white background from splash_logo.png using Pillow.
Replaces it with full transparency so the logo sits cleanly on any
background colour (e.g. the #121214 dark native splash).

Strategy: pixels with high luminance AND low colour saturation are background.
Pixels that are bright but highly saturated are part of the glowing flame.

Usage:
    python scripts/remove_splash_bg.py
"""

from pathlib import Path
from PIL import Image
import numpy as np

SRC = Path(__file__).parent.parent / "assets" / "icons" / "splash_logo.png"
DST = Path(__file__).parent.parent / "assets" / "icons" / "splash_logo_clean.png"

# --- tuneable thresholds -------------------------------------------------
LIGHT_THRESHOLD = 200     # pixels brighter than this are candidates
SATURATION_THRESHOLD = 40 # candidate must also have saturation < this (0-255)
FRINGE_RANGE = 40         # pixels in [LIGHT-FRINGE .. LIGHT] get blended
# -------------------------------------------------------------------------


def remove_light_background(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    data = np.array(img, dtype=np.float32)   # shape (H, W, 4)

    r, g, b, a = data[..., 0], data[..., 1], data[..., 2], data[..., 3]

    # Luminance (perceptual weighting)
    luma = 0.299 * r + 0.587 * g + 0.114 * b

    # Saturation in RGB space: max(r,g,b) - min(r,g,b)
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    saturation = cmax - cmin   # 0 = grey/white, 255 = vivid colour

    # A pixel is "background" if it's light AND desaturated
    is_bg = (luma >= LIGHT_THRESHOLD) & (saturation < SATURATION_THRESHOLD)

    # Fringe zone: light but not fully desaturated — blend out smoothly
    in_fringe = (luma >= LIGHT_THRESHOLD - FRINGE_RANGE) & ~is_bg & (saturation < SATURATION_THRESHOLD * 2)
    fringe_factor = ((luma - (LIGHT_THRESHOLD - FRINGE_RANGE)) / FRINGE_RANGE)
    fringe_alpha = a * (1.0 - np.clip(fringe_factor, 0, 1) * 0.85)

    new_alpha = np.where(is_bg, 0.0, np.where(in_fringe, fringe_alpha, a))

    data[..., 3] = np.clip(new_alpha, 0, 255)
    result = Image.fromarray(data.astype(np.uint8), "RGBA")
    result.save(dst, "PNG")
    print(f"DONE: Saved clean logo to: {dst}")


if __name__ == "__main__":
    remove_light_background(SRC, DST)



if __name__ == "__main__":
    remove_light_background(SRC, DST)
