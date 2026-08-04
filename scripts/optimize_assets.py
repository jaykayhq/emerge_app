#!/usr/bin/env python3
"""Recompress and prune bundled image assets to shrink the release AAB.

Every policy here is grounded in how the asset renders in the app (see the
asset-size audit in the repo history): each group either sits behind a dark
overlay/tint (masking compression artifacts) or is displayed far smaller
than its source resolution.

NOTE: generate_assets.js (Pollinations) regenerates assets/worlds at full
size — re-running it undoes this compression.

Usage:
  python scripts/optimize_assets.py --dry-run   # preview only, no writes
  python scripts/optimize_assets.py             # apply in place
"""

import os
import re
import sys
import tempfile
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
Image.MAX_IMAGE_PIXELS = None  # some sources exceed the default guard


def _resize(im, max_side):
    """Shrink to fit max_side on the long edge; never upscale."""
    longest = max(im.size)
    if longest <= max_side:
        return im
    scale = max_side / longest
    return im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)


def _has_alpha(im):
    return "A" in im.getbands()


def _flatten_alpha(im, background=(0, 0, 0)):
    """JPEG has no alpha: composite onto a solid background."""
    rgba = im.convert("RGBA")
    bg = Image.new("RGB", im.size, background)
    bg.paste(rgba, mask=rgba.getchannel("A"))
    return bg


def _quantize(im):
    """256-color palette for photo-like RGB PNGs (keeps alpha images as-is)."""
    if _has_alpha(im):
        return im
    return im.convert("RGB").quantize(colors=256, method=Image.Quantize.FASTOCTREE)


# Each policy: (pattern, name, transform -> (image, fmt, save kwargs)).
# transform returns an image ready for `fmt`; PNG keeps alpha, JPEG flattens it.
POLICIES = [
    (
        re.compile(r"^assets/worlds/.*\.jpe?g$"), "worlds",
        lambda im: (_flatten_alpha(_resize(im, 900)), "JPEG", dict(quality=65, optimize=True, progressive=True)),
    ),
    (
        re.compile(r"^assets/images/challenges/.*\.png$"), "challenges",
        lambda im: _challenge(im),
    ),
    (
        re.compile(r"^assets/images/.*_silhouette\.png$"), "silhouettes",
        lambda im: (_resize(im, 384), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/images/avatars/.*\.png$"), "avatars",
        lambda im: (_resize(im, 384), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/images/world_sanctuary_base\.png$"), "sanctuary",
        lambda im: (_resize(im, 768), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/images/welcome_cosmic_silhouette\.png$"), "cosmic",
        lambda im: (_quantize(_resize(im, 512)), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/images/archetype_.*\.png$"), "archetypes",
        lambda im: (_quantize(_resize(im, 512)), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/icons/attribute_.*\.png$"), "attribute-icons",
        lambda im: (_resize(im, 256), "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/icons/app_icon\.png$"), "app-icon",
        lambda im: (im, "PNG", dict(optimize=True)),
    ),
    (
        re.compile(r"^assets/icons/splash_logo_flame\.png$"), "splash-logo",
        lambda im: (im, "PNG", dict(optimize=True)),
    ),
]


def _challenge(im):
    """Full-width header images; JPEG unless transparency exists (keep PNG then)."""
    im = _resize(im, 1024)
    if _has_alpha(im):
        return im, "PNG", dict(optimize=True)
    return _flatten_alpha(im), "JPEG", dict(quality=78, optimize=True, progressive=True)


# Explicit deletions — zero references in lib/, web/, test/ (verified in the
# asset audit; all git-tracked so `git checkout -- <path>` restores them).
DELETIONS = [
    "assets/images/levels",                 # 150 PNG level images, unreferenced
    "assets/images/splash_background.png",  # unreferenced
    "assets/icons/athlete_icon.png",
    "assets/icons/creator_icon.png",
    "assets/icons/scholar_icon.png",
    "assets/icons/stoic_icon.png",
    "assets/icons/zealot_icon.png",         # unreferenced archetype icons
    "assets/icons/splash_logo_clean.png",
    "assets/icons/splash_logo_nobg.png",
    "assets/icons/splash_logo_preview.png",  # script artifacts
]


def _match(rel):
    for pattern, name, *_ in POLICIES:
        if pattern.match(rel):
            return name
    return None


def _dir_size(path):
    return sum(
        os.path.getsize(os.path.join(r, f))
        for r, _, fs in os.walk(path)
        for f in fs
    )


def main():
    dry_run = "--dry-run" in sys.argv
    if "--help" in sys.argv:
        print(__doc__)
        return 0

    deleted = []  # (rel, size)
    groups = {}   # name -> [before, after]
    failures = []
    rewritten = 0

    # --- deletions ---
    for target in DELETIONS:
        full = os.path.join(REPO, target)
        if os.path.isdir(full):
            size = _dir_size(full)
            files = [os.path.join(r, f) for r, _, fs in os.walk(full) for f in fs]
        elif os.path.isfile(full):
            size = os.path.getsize(full)
            files = [full]
        else:
            continue
        deleted.append((target, size))
        if not dry_run:
            for f in files:
                os.remove(f)
            try:
                os.removedirs(full)
            except OSError:
                pass  # dir not empty or already gone

    # --- recompression ---
    for root, dirs, files in os.walk(os.path.join(REPO, "assets")):
        rel_root = os.path.relpath(root, REPO).replace("\\", "/")
        deleted_roots = {d for d, _ in deleted}
        dirs[:] = [d for d in dirs if f"{rel_root}/{d}" not in deleted_roots]
        for fname in files:
            rel = os.path.relpath(os.path.join(root, fname), REPO).replace("\\", "/")
            name = _match(rel)
            if name is None:
                continue
            full = os.path.join(REPO, rel)
            before = os.path.getsize(full)
            try:
                with Image.open(full) as im:
                    im.load()
                    transform = next(p[2] for p in POLICIES if p[0].match(rel))
                    out, fmt, save_kwargs = transform(im)
            except Exception as exc:  # noqa: BLE001 - one bad file must not abort the batch
                failures.append(f"{rel}: {exc}")
                continue

            new_rel = rel[:-4] + ".jpg" if fmt == "JPEG" and rel.lower().endswith(".png") else rel
            new_full = os.path.join(REPO, new_rel)

            if dry_run:
                # Encode to a temp file to project the real after-size.
                fd, tmp = tempfile.mkstemp(suffix=".dryrun")
                os.close(fd)
                try:
                    out.save(tmp, fmt, **save_kwargs)
                    after = os.path.getsize(tmp)
                finally:
                    os.remove(tmp)
                groups.setdefault(name, [0, 0])
                groups[name][0] += before
                groups[name][1] += after
                continue

            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(new_full), suffix=".tmp")
            os.close(fd)
            try:
                out.save(tmp, fmt, **save_kwargs)
                after = os.path.getsize(tmp)
                if after >= before:
                    os.remove(tmp)  # no win — keep the original
                    continue
                os.replace(tmp, new_full)
                if new_rel != rel:
                    os.remove(full)
                rewritten += 1
            except Exception as exc:  # noqa: BLE001
                failures.append(f"{rel}: {exc}")
                try:
                    os.remove(tmp)
                except OSError:
                    pass
                continue
            groups.setdefault(name, [0, 0])
            groups[name][0] += before
            groups[name][1] += after

    # --- report ---
    print("DRY RUN — no files were written" if dry_run else "Applied.")
    tb = ta = 0
    for name in sorted(groups):
        b, a = groups[name]
        saved = (1 - a / b) * 100 if b else 0
        print(f"  {name:<16} {b/1e6:8.1f}MB -> {a/1e6:8.1f}MB  ({saved:5.1f}% saved)")
        tb += b
        ta += a
    for rel, size in deleted:
        print(f"  DELETED       {rel} ({size/1e6:.1f}MB)")
        tb += size
    print(f"TOTAL: {tb/1e6:.1f}MB -> {ta/1e6:.1f}MB  (saved {(tb-ta)/1e6:.1f}MB)")
    if not dry_run:
        print(f"Rewrote {rewritten} files.")
    if failures:
        print(f"FAILURES ({len(failures)}):")
        for f in failures:
            print(f"  {f}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
