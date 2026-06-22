"""Preview the cleaned logo composited on the splash background colour."""
from pathlib import Path
from PIL import Image

LOGO = Path(__file__).parent.parent / "assets" / "icons" / "splash_logo_clean.png"
OUT  = Path(__file__).parent.parent / "assets" / "icons" / "splash_logo_preview.png"
BG   = (18, 18, 20, 255)  # #121214

logo = Image.open(LOGO).convert("RGBA")
bg = Image.new("RGBA", logo.size, BG)
bg.paste(logo, (0, 0), logo)
bg.save(OUT, "PNG")
print(f"Preview saved to: {OUT}")
