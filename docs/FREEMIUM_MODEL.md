# Freemium Model Design

This document outlines the monetization strategy for Emerge, balancing a generous free tier to build habit usage (acquisition) with compelling premium features to drive revenue (conversion).

## 1. Strategy Overview

The strategy follows the "Hook Model":
1.  **Free Tier:** Allows users to build the core habit loop and experience the value of the "Atomic Habits" methodology.
2.  **Premium Tier ("Emerge Pro"):** Focuses on *scaling*, *insights*, and *customization*. It removes friction (Ads) and adds depth (Unlimited Stacks, Advanced Stats).

## 2. Feature Comparison Matrix

| Feature Category | Free Tier (Standard) | Premium Tier (Emerge Pro) | Rationale |
| :--- | :--- | :--- | :--- |
| **Habit Capacity** | Max 3 Active Habits | **Unlimited Habits** | 3 is enough to start, but power users need more. |
| **Habit Stacks** | 1 Morning Routine Stack | **Unlimited Stacks** (Morning, Noon, Night) | Encourages upgrading as the user's routine becomes more complex. |
| **Analytics** | Current Streak only | **Full Heatmap, Trend Lines, Success Rate %** | "Data nerds" are highly likely to pay. |
| **Gamification** | Basic Avatar | **Exclusive Skins, Aura Effects, Pets** | Vanity items are a strong monetization driver in gamified apps. |
| **Social** | Join Public Tribes | **Create Private Tribes, Host Challenges** | Leaders/Influencers pay to manage their communities. |
| **Integrations** | Manual Entry only | **Auto-sync (Apple Health, Google Fit)** | Convenience is a premium feature. |
| **Experience** | Banner Ads active | **Ad-Free Experience** | Standard removal of annoyance. |
| **Backups** | Local only | **Cloud Backup & Sync** | Security of data is worth paying for. |
| **AI Coach** | Basic Chat (Limited Context) | **Advanced Coaching (Full History Analysis)** | Detailed personalized advice is a premium value. |

## 3. Technical Implementation

### RevenueCat Integration
*   **Entitlement ID:** `pro_access`
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

### Paywall Locations
*   **Trigger 1:** When trying to add a 4th Habit (Limit reached).
*   **Trigger 2:** When clicking on "Detailed Stats".
*   **Trigger 3:** When trying to equip a "Pro" avatar item.
