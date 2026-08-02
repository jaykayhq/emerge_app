# Freemium Model Design

This document outlines the monetization strategy for Emerge, balancing a generous free tier to build habit usage (acquisition) with compelling premium features to drive revenue (conversion).

## 1. Strategy Overview

The strategy follows the "Hook Model":
1.  **Free Tier:** Allows users to build the core habit loop and experience the value of the "Atomic Habits" methodology.
2.  **Premium Tier ("Emerge Pro"):** Focuses on *scaling*, *insights*, and *customization*. It removes friction (Ads) and adds depth (Unlimited Stacks, Advanced Stats).

## 2. Feature Comparison Matrix

| Feature Category | Free Tier (Standard) | Premium Tier (Emerge Pro) | Rationale |
| :--- | :--- | :--- | :--- |
| **Habit Capacity** | Max 5 Active Habits | **Unlimited Habits** | 5 is enough to start, but power users need more. |
| **Habit Stacks** | 1 Morning Routine Stack | **Unlimited Stacks** (Morning, Noon, Night) | Encourages upgrading as the user's routine becomes more complex. |
| **Analytics** | Current Streak only | **Full Heatmap, Trend Lines, Success Rate %** | "Data nerds" are highly likely to pay. |
| **Gamification** | Basic Avatar | **Exclusive Skins, Aura Effects, Pets** | Vanity items are a strong monetization driver in gamified apps. |
| **Social** | Join 1 Tribe | **Unlimited Tribes** | The free tier can join 1 tribe; premium joins unlimited. |
| **Integrations** | Manual Entry only | **Auto-sync (Apple Health, Google Fit)** | Convenience is a premium feature. |
| **Experience** | Banner Ads active | **Ad-Free Experience** | Standard removal of annoyance. |
| **Backups** | Local only | **Cloud Backup & Sync** | Security of data is worth paying for. |
| **AI Coach** | 3 Coach Asks / Day | **Unlimited Coach Asks** | Grounded in the user's own habit data. |
| **World Themes** | 1 Theme (Cosmic Nebula) | **All 6 Themes** | 5 more themes coming soon (SP-C). |

## 3. Technical Implementation

### RevenueCat Integration
*   **Entitlement ID:** `premium`
*   **Offerings:**
    *   `monthly_sub`: $4.99/month
    *   `annual_sub`: $39.99/year (2 months free)
    *   `lifetime`: $99.99 (One-time)

### AdMob Integration
*   **Banner Ads:** Placed at the bottom of the `dashboard__timeline_of_cues` screen.
*   **Interstitial Ads:** Shown after completing a "Level Up" animation (high engagement moment) - frequency capped to once per day.
*   **Logic:**
    ```dart
    // Pseudo-code for Ad Widget
    if (user.isPremium) {
      return SizedBox.shrink(); // Hide Ad
    } else {
      return AdMobBannerWidget();
    }
    ```

### Paywall Locations (implemented gates)
*   **Trigger 1:** Creating a 6th active habit (free limit = 5; Remote Config `free_habit_limit`, default 5; onboarding/anchor habits bypass).
*   **Trigger 2:** Joining a 2nd club (free limit = 1; `clubJoinBlockedByFreeTier` in `tribes_provider.dart`).
*   **Trigger 3:** 4th coach ask in a day (free limit = 3/day; `CoachAskQuota`).
*   **Not a paywall trigger:** World themes — locked as "coming soon" (SP-C), 1 theme free.
*   **Web:** Paywall uses external Paystack Payment Pages (₦15,000/yr, ₦2,500/mo); premium activates via the `paystackWebhook` → `users/{uid}.isPremium` Firestore flag streamed by `isPremiumProvider`.
