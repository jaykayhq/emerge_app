# Evolution Overlay Textures — MixBoard Generation Prompts

> **Output path:** `assets/images/avatars/evolved/{phase}/overlay.png`
> **Canvas:** 512 × 614 px — must match character render dimensions exactly
> **Compositing:** These PNGs are layered ON TOP of the code-painted silhouette in Flutter Stack()
> **Critical:** Interior of the character shape MUST be transparent. Only edges/texture visible.
> **Tool:** MixBoard → GPT Image model

---

## 1. evolved/construct/overlay.png

Paste this entire block into MixBoard:

```
Transparent PNG texture overlay designed to be composited over a human silhouette shape,
512 x 614 pixels. Black or dark background with the texture elements only — will be
processed for transparency in post.

CONTENT: A geometric wireframe mesh pattern in the shape and proportions of a standing
human figure. The wireframe consists of thin lines 1–2px wide forming a triangular
polygon mesh — the style of a 3D low-poly wireframe render. Lines are electric-blue
#7AA2F7. The mesh is DENSE at the outer silhouette edge and fades to SPARSE or absent
toward the center of the figure. The outer 20–30px of the silhouette edge should have
the most contrast wireframe lines, the inner body area should be very faint or empty.

Color: electric-blue #7AA2F7 wireframe lines on a fully black #000000 background.
The black background will be removed via chroma keying — do not add any gradients or
non-black background colors. No fill areas. No solid shapes. Lines only.
No text. No watermark. No decorative border.
```

---

## 2. evolved/incarnate/overlay.png

Paste this entire block into MixBoard:

```
Transparent PNG texture overlay designed to be composited over a human silhouette shape,
512 x 614 pixels. Black background with the texture elements only — will be processed
for transparency in post.

CONTENT: A soft inner-edge glow effect in the shape and proportions of a standing human
figure. The effect is a bright edge band 10–14px wide that traces the entire outline of
the human form — head, shoulders, arms, torso, legs, feet. The edge band color is
soft white #FFFFFF fading to the archetype midtone outward. At the very center of the
body shape, there is a faint single vertical highlight streak — a 4px wide bright white
line running from upper chest to lower abdomen at center-left of torso, suggesting
reflected environmental light. Everything else is black.

Color: bright white #FFFFFF edge band on fully black #000000 background.
The black background will be removed via chroma keying. No fill areas. No gradients
across the background. Edge glow only. No text. No watermark.
```

---

## 3. evolved/radiant/overlay.png

Paste this entire block into MixBoard:

```
Transparent PNG texture overlay designed to be composited over a human silhouette shape,
512 x 614 pixels. Black background with the texture elements only — will be processed
for transparency in post.

CONTENT: A kintsugi gold crack network mapped to the shape and proportions of a standing
human figure. Kintsugi is the Japanese art of repairing broken pottery with gold —
the cracks become the most beautiful part. The cracks are irregular branching lines
3–4px wide in bright gold #E0AF68 with a white-gold #FFF8E1 bright center line.
Each crack has a soft outer glow of gold suggesting inner light bleeding through.

The crack origin point is the center of the chest area. From this origin, main cracks
branch outward in 6–8 directions reaching: both hands and forearms, the neck and jaw,
both knees, and the outer hip area. Secondary cracks branch off the main ones.
The cracks follow the contour of the human figure — they do not extend outside the
silhouette shape. Total coverage: approximately 30–40% of the silhouette surface.

Color: gold #E0AF68 and white-gold #FFF8E1 cracks on fully black #000000 background.
The black background will be removed. No filled areas between cracks. No text. No watermark.
```

---

## 4. evolved/ascended/overlay.png

Paste this entire block into MixBoard:

```
Transparent PNG texture overlay designed to be composited over a human character image,
512 x 614 pixels. Black background with the texture elements only — will be processed
for transparency in post.

CONTENT: A cyan-white transcendence energy aura effect surrounding the outline of a
standing human figure. The aura has three layers:

LAYER 1 — Inner rim: a 4px bright white #FFFFFF ring right at the edge of the silhouette,
60% opacity.

LAYER 2 — Mid glow: a soft diffuse glow in bright cyan #00F0FF spreading 20–30px outward
from the silhouette edge, fading from 70% opacity at the edge to 0% transparent at the
outer boundary.

LAYER 3 — Energy wisps: 8–12 thin wisp streaks of bright cyan-white #B2EBF2 rise upward
from the shoulders, the top of the head, and both forearms — like flames or energy
threads rising vertically. Each wisp is 2–3px wide at the base and tapers to a point,
length 40–60px.

The interior of the silhouette is entirely transparent/black — the aura only affects the
outer 30–40px beyond the body edge and the wisp elements above it.

Color: cyan #00F0FF and white on fully black #000000 background.
The black background will be removed. No filled background areas. No text. No watermark.
```

---

# Artifact Icons — MixBoard Generation Prompts

> **Output path:** `assets/images/avatars/shop/artifacts/{artifact_id}.png`
> **Canvas:** 128 × 128 px icon
> **Style:** 2D flat game icon, cel-shaded, dark background, clear silhouette readable at small sizes
> **Tool:** MixBoard → GPT Image model

---

## ARTIFACT ICON STYLE LOCK

```
STYLE: 2D flat game icon design, cel-shaded coloring, bold clean black ink outline 2px,
centered subject on a very dark near-black background #0D1117, icon must be readable
at 64x64px, single subject only, no text, no banner, no frame border, no watermark.
Flat fill plus one highlight accent. Zero gradients. Zero 3D rendering. Zero photorealism.
```

---

## 5. shop/artifacts/hermes_wings.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A pair of small feathered wings, symmetrical, lower-leg / ankle attachment style
as if worn on boots. Wings spread outward equally left and right. Each wing has 5–6
defined primary feathers in bright coral-red #F7768E with a white highlight on each
feather's upper edge. A faint coral glow aura #F7768E at 40% opacity surrounds the
entire icon. Wings face the viewer straight on. Wing span approximately 80% of the
icon width.
```

---

## 6. shop/artifacts/golden_shoes.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A single athletic shoe shown in a slight 3/4 angle. The shoe is entirely in bright
gold #E0AF68 with a white #FFFFFF highlight stripe along the top of the toe box. The sole
is a slightly darker gold #C8992A. Small bright gold spark marks #FFD700 — 4 point stars
size 4–6px — float off the heel and toe as if the shoe leaves sparks when stepping.
Shoe fills 70% of the icon area.
```

---

## 7. shop/artifacts/halo.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A perfect floating ring / halo shown in a slight perspective angle (ellipse, not full
circle from front). The ring is solid violet-purple #BB9AF7 with a bright white highlight
arc on the upper inner edge suggesting the ring is a solid luminous object. A soft
purple glow aura #BB9AF7 at 50% opacity radiates outward 8px from the ring. Three small
8-pointed star sparkles #FFFFFF float just outside the ring at the top, left, and right.
Ring diameter takes up 70% of the icon.
```

---

## 8. shop/artifacts/third_eye.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A single stylised eye shape, slightly almond / leaf shaped, centered in the icon.
The eye is oriented horizontally. Outer lid line is bold black 2px. Iris is a bright
cyan #00F0FF flat circle with a black pupil dot. Upper eyelid has a bright white
highlight crescent. The eye emits 6 straight rays outward in a starburst — 3 rays
up-left/up-right/straight-up, and 3 rays down, evenly spaced — each ray is 1px wide
in cyan #00F0FF, length 12–16px, fading to transparent at the tip. A cyan glow halo
#00F0FF at 40% surrounds the entire eye shape.
```

---

## 9. shop/artifacts/aegis.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A chest breastplate / pectoral shield piece, shown front-facing, symmetrical.
Shaped like a rounded rectangle with a slight v-notch at the center-top neckline.
The plate is in blue-grey #7AA2F7 with angular geometric seam lines across the surface
forming a 4-quadrant panel design. A bright white highlight runs diagonally across the
upper-left panel. A faint blue glow #7AA2F7 at 35% surrounds the entire breastplate.
The plate takes up 70% of the icon area.
```

---

## 10. shop/artifacts/core_glow.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A bright glowing orb or core energy gem, centered. The shape is a slightly irregular
organic circle — not a perfect sphere. The fill color is bright green #9ece6a with a
bright white highlight point in the upper-left quadrant. The outer edge of the orb pulses:
three concentric glow rings in green #9ece6a at 60%, 35%, 15% opacity expanding outward
from the orb edge at 8px, 16px, 24px distance. 4 short straight energy bolts extend from
the orb at 90 degree intervals, each 10px long in bright white.
```

---

## 11. shop/artifacts/midas_touch.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: An open hand shown palm-facing-viewer, fingers together and slightly spread.
The entire hand is gold #E0AF68 as if turned to solid gold. The palm center has a
bright white-gold highlight spot #FFF8E1. Small 4-pointed gold star sparkles — 5 of them —
float off the fingertips in various directions. The wrist fades downward into a soft
golden mist. Hand takes up 65% of the icon area.
```

---

## 12. shop/artifacts/floating_tools.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: Three objects arranged in a loose triangle orbiting a center point as if floating
in a circular pattern. The three objects are: (1) top-center: a feather quill in amber
#E0AF68; (2) bottom-left: a small paintbrush in orange #FF9E64 with a bright magenta
paint tip #E040FB; (3) bottom-right: a small amber crystal shard #E0AF68.
Each object has a faint orbit arc trail behind it in the matching color at 30% opacity.
Each object emits a small point glow.
```

---

## 13. shop/artifacts/the_flow.png

```
STYLE: 2D flat game icon, cel-shaded, bold 2px black ink outline, dark background #0D1117,
no text, no border, readable at 64x64px.

ICON: A stylised human torso silhouette (neck to hip, no arms shown) with glowing vein-lines
visible beneath the surface like bioluminescent rivers. The silhouette outline is dark
grey #263238. The veins are flowing curved lines in bright aqua #73DACA, 2px wide,
branching out from a central core point at the sternum to both sides of the chest,
up toward the neck, and down toward the hips. The vein lines glow with a soft aqua
#73DACA aura at 40% opacity. The torso silhouette interior is slightly lighter dark
#1E2A3A to separate it from the background.
```

---

# Effect PNGs — MixBoard Generation Prompts

> **Output path:** `assets/images/avatars/effects/{effect}.png`
> **Canvas:** 512 × 614 px (matches avatar render size)
> **Note:** These are additive overlay effects — generate on black background, use Screen/Add blend mode in code
> **Tool:** MixBoard → GPT Image model

---

## 14. effects/glow_soft.png

```
Pure black background #000000, 512 x 614 pixels. A soft radial glow effect centered
in the frame, elliptical in shape, taller than wide approximately 300 x 420 px.
Color: archetype-neutral warm white #FFFFFF fading from 25% opacity at the very center
hotspot to 0% fully transparent at the ellipse boundary. This is a subtle ambient
fill light — not a bright spotlight. No hard edges anywhere. No shapes. No outlines.
No text. No watermark. This PNG will be rendered in Flutter using BlendMode.screen
or BlendMode.plus so the black areas will disappear automatically.
```

---

## 15. effects/glow_strong.png

```
Pure black background #000000, 512 x 614 pixels. A strong radial glow effect centered
in the frame, elliptical in shape, taller than wide approximately 320 x 480 px.
Color: bright white-gold #FFF8E1 at the center hotspot at 70% opacity, transitioning
to warm gold #E0AF68 at 40% opacity at mid-radius, fading to fully transparent at the
ellipse boundary. The transition should be very smooth and radial. No hard edges.
No shapes. No outlines. No text. No watermark. This PNG will be rendered in Flutter
using BlendMode.screen or BlendMode.plus so the black areas disappear automatically.
```

---

## 16. effects/sparkles.png

```
Pure black background #000000, 512 x 614 pixels. A field of 20–28 small sparkle glints
scattered across the upper 70% of the frame — concentrated around the head and shoulder
area of where a character would be, with some trailing down. Each sparkle is a classic
4-point star shape (a cross with diagonal accent lines) in bright white #FFFFFF,
sizes varying: small 6px, medium 10px, large 14px, mixed randomly. Each star sparkle
has a very soft white glow halo 4–6px around it. Sparkles are not evenly distributed —
cluster more at upper-center and upper-left, fewer at lower areas. No text. No watermark.
This PNG will be rendered in Flutter using BlendMode.screen so the black background
disappears automatically.
```
