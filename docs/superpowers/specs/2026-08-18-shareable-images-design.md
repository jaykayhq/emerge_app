# Shareable Images — Design

**Date:** 2026-08-18
**Status:** Approved for planning
**Feature area:** Shared export system (`lib/core`) + recap hub (`lib/features/gamification`) + creator dashboard (`lib/features/social`)
**Companion spec:** `2026-08-18-creator-analytics-design.md` (planned in the same session)

## 1. Context & Problem

The growth spec (`2026-08-07-growth-monetization-gtm-design.md` §6 P0) calls for a
**"Branded 9:16 recap export"** — render recap cards into branded vertical
image(s) users save and share to TikTok/IG/WhatsApp Status, feeding the viral
loop: content → shareable recap → UGC.

Today the recap hub's "Share Your Recap" button (`spotify_wrapped_recap.dart`)
only shares **plain text** via `Share.share(shareText)`. There is no image
export, and creators have no way to promote their tribe with a branded stat card.

## 2. Decisions (from brainstorming)

- **Two surfaces:** (1) user weekly recap export, (2) creator tribe share card.
- **Format:** static 9:16 PNGs. The **video slideshow is a documented follow-up**
  (needs an `ffmpeg_kit_flutter` native-dependency decision — not built here).
- **Architecture:** one shared `ShareableCard` branded template + a
  `ShareableImageExporter` reusing the existing RepaintBoundary → PNG → share
  pattern from `timeline_share_preview.dart`.

## 3. Shared system

### `ShareableCardData` — pure data struct

```dart
// lib/core/presentation/widgets/shareable/shareable_card_data.dart
class ShareableCardData {
  final String headline;                 // e.g. "MY WEEK IN EMERGE"
  final String? subheadline;             // e.g. "Week of Aug 10 – 16"
  final List<ShareableStat> stats;       // label + value + color + optional icon
  final String? footer;                  // e.g. "Join my tribe on Emerge"
}

class ShareableStat {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
}
```

### `ShareableCard` — the 9:16 branded canvas

- Fixed **9:16** aspect ratio (360×640 logical → 1080×1920 @3x).
- Cosmic gradient background from the `docs/design.md` palette (`EmergeColors`).
- Emerge flame logo (static variant of `AnimatedFlameLogo` — no animation in export).
- Headline, optional subheadline, stat rows, optional footer.
- Uses the bundled fonts (SplineSans / Outfit / Poppins) — no runtime font fetch.

### `ShareableImageExporter`

```dart
// lib/core/presentation/services/shareable_image_exporter.dart
Future<Uint8List> renderPng(
  ShareableCardData data, {
  double pixelRatio = 3.0,
});
```

- Builds the `ShareableCard`, inserts it into an offscreen `OverlayEntry`
  (invisible — never flashes on screen), waits a frame, captures via
  `RepaintBoundary` → `toImage(pixelRatio: 3.0)` → PNG bytes, removes the entry.
  Mirrors `timeline_share_preview.dart:44`.
- **Native:** write temp file via `path_provider`, share via `share_plus`
  `Share.shareXFiles([...])` (optionally with a text caption).
- **Web (`kIsWeb`):** fall back to a browser download of the PNG.

## 4. Surface 1 — User weekly recap export

- In the recap hub outro, "Share Your Recap" opens a new `RecapShareSheet`:
  **"Current slide"** or **"All slides"**.
- Each selected slide's content is re-rendered through `ShareableCard`
  (headline = slide title, stats = that slide's numbers) with the Emerge logo +
  footer, then exported + shared. The existing text caption accompanies the files.
- Pure logic: `recapToShareableCards(UserWeeklyRecap)` →
  `List<ShareableCardData>` — unit-testable without Flutter.

**Files:**
```
lib/features/gamification/presentation/widgets/recap_share_sheet.dart
lib/features/gamification/presentation/services/recap_to_shareable_cards.dart  // pure
```

## 5. Surface 2 — Creator tribe share card

- On the analytics tab (and reachable from Tribe Management), a "Share tribe
  card" action exports one branded PNG: tribe name, members, tribe XP, habits
  done, challenges done, footer "Join my tribe on Emerge".
- Pure logic: `tribeToShareableCard(TribeStats, tribeName, creatorName)` →
  `ShareableCardData` — unit-testable.

**Files:**
```
lib/features/social/presentation/services/tribe_to_shareable_card.dart  // pure
lib/features/social/presentation/widgets/creator_tribe_share_card.dart  // button + export flow
```

## 6. Error handling

- Export failure → `SnackBar` with retry; never crashes the recap flow.
- Empty stats → card renders with zeros / omits empty rows.
- Web download failure → `SnackBar`; no crash.
- Video slideshow (stretch) documented in this spec as a follow-up requiring an
  `ffmpeg_kit_flutter` decision — **not built here**.

## 7. Testing (TDD)

- **Unit — pure functions:** `recapToShareableCards` and `tribeToShareableCard`
  (correct stat rows, empty handling, headline/footer).
- **Widget — `ShareableCard`:** renders at 9:16 without overflow (long text,
  many stats, empty stats).
- **Unit — exporter:** emits valid PNG bytes (magic header `\x89PNG`) at the
  requested pixel ratio; web branch returns download bytes.
- **Widget — `RecapShareSheet`:** shows the two options; analytics tab share
  button triggers an export.

## 8. Success criteria

- Users can export their weekly recap as branded 9:16 PNGs and share to
  TikTok/IG/WhatsApp Status.
- Creators can share a branded tribe stat card.
- Export never blocks or crashes the recap flow; failures surface as snackbars.
- Video slideshow is scoped as a defined follow-up, not silently dropped.
