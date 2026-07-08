# Design Spec: Behavioral Hardening & AI Elevation (2026-04-30)

## 1. Overview
This spec outlines the implementation of the final behavioral loops for the Emerge application, focusing on Social Contract enforcement, AI-driven habit adjustments, and visual representation of world entropy.

## 2. Social Contract Enforcement (Identity Stakes)
To reinforce the high-stakes nature of identity-defining habits, missing a habit with an active contract will trigger severe penalties.

### Backend Logic (Cloud Functions)
- **Momentum Penalty**:
  - Location: `functions/src/index.ts` -> `applyDailyMomentumDecay`.
  - Check: If `habit.contractActive == true`.
  - Penalty: `missDecay` = 15 (Standard is 5).
- **XP Penalty**:
  - Penalty Amount: -5% of the XP required for the user's current level.
  - Implementation: If a contract is broken, the function will subtract XP from `avatarStats.totalXp`.
  - Clamping: XP will not drop below the start of the current level (preventing forced level-down for UX compassion).

### Visual Feedback
- A "Contract Broken" world event is logged in `UserWorldState.activeEvents`.
- Triggers a specific "Red Alert" state in the `WorldBackground` for 24 hours.

## 3. AI-Driven Weekly Recap (Gen 2)
Elevating the recap from a simple summary to an intelligent coach that manages habit friction.

### AI Insight Engine
- **Platform**: Firebase Cloud Functions (Gen 2) with Groq/Vertex AI.
- **Analysis Inputs**:
  - 14-day completion velocity per habit.
  - Current streak and momentum scores.
  - Dominant attribute (Identity Votes).
- **Automatic Adjustments (Goldilocks Rule)**:
  - **High Velocity (>90%)**: Upgrade `HabitDifficulty` to the next tier (e.g., Medium -> Hard).
  - **Low Velocity (<30%)**: Downgrade to `Easy` (Two-Minute Rule version) to restore momentum.
- **Narrative**: Generates a 2-sentence "Identity Anchor" insight.

### UI Integration
- The `WeeklyRecap` screen will display a "Goldilocks Calibration" badge for habits that were automatically adjusted.

## 4. Visual Entropy Rendering (WorldBackground)
Visualizing the decay of the user's "World State" when habits are neglected.

### Shader Integration
- **uEntropyLevel**: Maps `UserWorldState.entropy` (0.0 to 1.0) to shader uniforms.
- **Visual Phases**:
  - **Level 0.0-0.3 (Thriving)**: Full vibrancy, high Nebula particle count.
  - **Level 0.4-0.7 (Unstable)**: Desaturation overlay, subtle chromatic aberration.
  - **Level 0.8-1.0 (Entropy)**: High "Fog" density, procedural vignette darkening, reduced particle velocity.

## 5. Security & Data Integrity
- **Firestore Rules**: Ensure `UserStats` and `UserWorldState` updates for entropy and XP loss are permitted via system-level triggers.
- **Immutability**: Maintain the audit trail of broken contracts in the `user_activity` collection.

## 6. Success Criteria
- [ ] Missed contracted habits result in 3x momentum loss and -5% XP.
- [ ] Weekly recaps provide AI insights and auto-adjust difficulties.
- [ ] Background visuals noticeably shift as world entropy increases.
