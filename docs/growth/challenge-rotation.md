# Emerge — Challenge Rotation Config Guide

The server-published challenge feed is rotated by `scripts/rotation/index.js` (run by the daily GitHub Actions workflow, or manually). This guide covers how to control it **without an app release**.

## What runs when

- **GitHub Actions** (`.github/workflows/ai-rotation.yml`): daily `0 6 * * *` UTC via a headless Kilo agent executing `docs/growth/challenge-rotation-runbook.md`; manual trigger via the **Run workflow** button.
- **Manually** (local): `GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json node scripts/rotation/index.js` after `npm --prefix scripts/rotation install`.

## Control rotation without code changes

Set the `config/challengeRotation` doc in Firestore:

```json
{
  "enabled": true,
  "featuredLimit": 3,
  "imagePool": ["https://.../img1.jpg", "https://.../img2.jpg", "https://.../img3.jpg"]
}
```

| Field | Effect |
|---|---|
| `enabled` | `false` makes the run a no-op. |
| `featuredLimit` | How many templates get `status: featured`; the rest are `active`. |
| `imagePool` | Fallback images (rotated weekly per template index) used only for templates without a local image or template `imageUrl`. |

## Change challenge images (polli workflow, all in this workspace)

1. Generate: `polli gen image "<prompt>" --output scripts/rotation/images/morning_protocol.jpg`
2. The filename must match the template's `imageFile` in `scripts/rotation/templates.js`.
3. Commit the image; the next run uploads it to Storage (`challenges/images/<id>/<week>.jpg`) and repoints `imageUrl`.

Priority: local polli file → template `imageUrl` → `imagePool` rotation.

## Change affiliate links (this is how you get paid)

Put **your real tagged links** in the `affiliatePartners/{id}` Firestore doc under `affiliateUrl` (e.g. Amazon `?tag=yourname-20`, your CJ/ShareASale tracking link, your Jumia publisher link, or a direct brand deal). The rotation copies them onto every challenge for that partner. Never use a bare storefront URL — without your tag no purchase is attributed.

**Payout model:** networks pay commission on purchases attributed to your tag (Amazon/Jumia ~24h attribution; Impact/CJ/ShareASale ~30 days), on their schedule once you cross their minimum (Amazon $10; CJ/ShareASale ~$50). `direct` = you invoice brands yourself (Paystack for NGN). At current scale expect ≈$0; the mechanic is the C-track pitch asset.

## Deployment notes

- **Storage rules** (one-time): `firebase deploy --only storage` after the rules change, so uploaded images are publicly readable.
- **Service account**: the GitHub secret `FIREBASE_SERVICE_ACCOUNT_TRADEFLASH_L2966` needs `roles/storage.objectAdmin` (or `objectCreator` + `objectViewer`) if the upload step 403s.
- **No scheduled functions** are involved — the workflow uses the Admin SDK directly (zero function invocations; batched writes; unchanged challenges are skipped).

## Security

Never commit service-account JSONs. `scripts/service-account-key.json` must not be tracked (see `docs/growth/challenge-rotation-runbook.md` security note).
