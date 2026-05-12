# Spec: Recap Hub & Gated AI Insights

**Date**: 2026-05-05
**Status**: Approved
**Goal**: Create a central "Recap Hub" for behavioral reflection, providing a mix of automated rewards (passive) and analytical exploration (active), while gating high-cost AI insights behind a Premium subscription.

---

## 1. Overview
The Recap system will transition from a single-screen experience to a two-tier "Hub" model.
- **Passive Path**: One-tap access to the current week's recap (Spotify Wrapped style).
- **Active Path**: Ability to browse previous weeks and generate custom date range reports.

## 2. Monetization Tiers (Option A: Gated Insights)

### Free Tier
- **Access**: Most recent 2 weeks of history.
- **Content**: Numerical stats only (XP, Streak, Habits).
- **AI**: AI-generated headlines and insights are "Locked" (blurred or replaced with generic motivation).
- **Customization**: No custom date range generation.

### Premium Tier
- **Access**: Unlimited history explorer.
- **Content**: Full AI-generated personality analysis and behavioral velocity insights.
- **Customization**: Generate recaps for any arbitrary date range (e.g., "My month of May").

## 3. Architecture & Data Flow

### Frontend: `RecapHubScreen`
- **Featured Card**: Large, high-visibility card for the current week (Automated range).
- **History List**: Vertical list of previous ISO weeks (Monday-Sunday blocks).
- **Custom Button**: Floating Action Button or Card to "Explore Custom Period" (triggers range picker).

### Service: `WeeklyRecapService`
- **Premium Check**: Consults `isPremiumProvider` before calling AI.
- **Call Logic**:
    - If Premium -> Call `generateAiRecap` Cloud Function.
    - If Free -> Skip function call; generate `localRecap` only.
- **Persistence**: Save generated recaps to Firestore at `users/{uid}/recaps/{recapId}` to avoid redundant AI costs.

### Backend: `generateAiRecap` (Functions)
- **Security**: Double-check `isPremium` status in user's profile before executing Groq/Vertex AI calls.
- **Velocity**: Use dynamic `diffInDays` for velocity calculations (already implemented).

## 4. UI Components

### `SpotifyWrappedRecap` Updates
- **Lock Overlay**: A "Frosted Glass" overlay on the AI Insight slide for free users.
- **Call-to-Action**: "Upgrade to Premium to see your persona analysis" button on locked slides.

### `RecapHubScreen`
- **Layout**: Minimalist, identity-first design using the `HexMeshBackground`.
- **Navigation**: Uses `go_router` for deep-linking into specific recap IDs.

---

## 5. Success Criteria
- [ ] Users can enter the Hub and see a list of available recaps.
- [ ] Tapping a card launches the "Wrapped" experience immediately.
- [ ] Free users see stats but find the AI insights locked with a clear upgrade path.
- [ ] Premium users can select any two dates and get a full AI report.
- [ ] No redundant AI calls are made for the same date range if a recap already exists in Firestore.
