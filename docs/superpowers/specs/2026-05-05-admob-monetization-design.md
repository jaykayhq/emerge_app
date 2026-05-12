# Design Spec: Identity-First AdMob Monetization

## 1. Context & Goals
Integrate Google AdMob into the Emerge application using the "Identity Fuel" model. The goal is to generate revenue from free users without degrading the core behavioral habit loop. Ads are treated as strategic friction (interstitials) or value exchanges (rewarded), strictly gated behind the `isPremiumProvider` (RevenueCat).

## 2. Ad Unit Configuration
The following production IDs will be integrated via `AppConfig` (falling back from Firebase Remote Config -> `.env` -> `--dart-define`):
*   **App ID:** `ca-app-pub-5049162599848475~2869117515`
*   **Banner Unit:** `ca-app-pub-5049162599848475/3295552257`
*   **Interstitial Unit:** `ca-app-pub-5049162599848475/7186785099`
*   **Rewarded Unit:** `ca-app-pub-5049162599848475/1076583020`

## 3. Psychological Integration (The "Identity Fuel" Model)
*   **Rewarded Ads (Value Exchange):**
    *   *AI Recap Generation:* Free users must watch an ad to generate their Weekly AI Recap.
    *   *Streak Forgiveness:* Watch an ad to repair a broken streak (limit: 1/week).
*   **Interstitial Ads (Strategic Friction):**
    *   *Trigger:* Only upon returning to the Home tab after completing a major loop (e.g., finishing a Challenge). Never during the habit logging flow.
    *   *Rate Limit:* Maximum 1 per 12 hours (managed via SharedPreferences).
*   **Banner Ads (Environmental Noise):**
    *   *Placement:* Anchored at the bottom of utility screens only (Settings, Stats, Tribes). Excluded from immersive screens (Home, WorldMap).

## 4. Technical Architecture
1.  **Consent First (UMP SDK):** `init_app.dart` will be updated to enforce GDPR/ATT consent checks *before* calling `MobileAds.instance.initialize()`.
2.  **State Gating:** All ad requests will be downstream of the `isPremiumProvider`. If true, ad initialization and loading are bypassed completely.
3.  **AdManagerService (Riverpod):** A dedicated service to handle pre-warming of Interstitial and Rewarded ads so they are ready instantly without blocking the UI thread.
4.  **Platform Manifests:** 
    *   Update `AndroidManifest.xml` with the App ID and `AD_ID` permission.
    *   Update `Info.plist` with `GADApplicationIdentifier`, `NSUserTrackingUsageDescription`, and Google's `SKAdNetworkIdentifier`.
5.  **Layout Stability:** Banners will be wrapped in `RepaintBoundary` and fixed `SizedBox` constraints to prevent Cumulative Layout Shift (CLS) when loading.

## 5. Production Requirements
*   **app-ads.txt:** The string `google.com, pub-5049162599848475, DIRECT, f08c47fec0942fa0` must be published to the root of the developer website linked in the app stores.
*   **Android 15:** Ensure UI overlays do not conflict with Edge-to-Edge enforcement.

## 6. Self-Review Notes
*   *Placeholder Scan:* No TBDs. Exact IDs provided.
*   *Scope Check:* This encompasses the full setup (Manifests -> Consent -> AdManager -> UI implementation). It is scoped perfectly for a single implementation plan.
*   *Ambiguity Check:* Rate limits (1 per 12 hours) and specific triggers (AI Recap) are explicitly defined.
