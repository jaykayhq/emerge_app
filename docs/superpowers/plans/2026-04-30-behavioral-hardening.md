# Behavioral Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement high-stakes social contract penalties, AI-driven habit difficulty calibration, and visual entropy rendering.

**Architecture:** Enhances existing Cloud Functions (Gen 1 & Gen 2) for backend enforcement and integrates entropy-driven shaders into the `WorldBackground` UI.

**Tech Stack:** TypeScript (Firebase Functions), Dart (Flutter), GLSL (Shaders), Groq/Vertex AI.

---

### Task 1: Social Contract Enforcement (Backend)

**Files:**
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Implement 3x Momentum Decay for Contracts**
Update the scheduled `applyDailyMomentumDecay` function to check the `contractActive` flag.

```typescript
// functions/src/index.ts

// Inside applyDailyMomentumDecay loop (around line 465)
const contractActive = (data.contractActive as boolean) ?? false;
const currentMomentum = (data.momentumScore as number) ?? 0;
const consecutiveMisses = (data.consecutiveMisses as number) ?? 0;

// Penalty: 15 for missed contract, else standard (5 for miss, 2 for idle)
const missDecay = contractActive ? 15 : (consecutiveMisses > 0 ? 5 : 2);
const newMomentum = Math.max(0, currentMomentum - missDecay);
```

- [ ] **Step 2: Implement XP Penalty for Broken Contracts**
Add logic to deduct XP when a habit with an active contract is missed.

```typescript
// functions/src/index.ts

// Logic to be added to the decay loop within the transaction:
if (contractActive && consecutiveMisses === 0) { // First day missed
  const statsRef = firestore.collection("user_stats").doc(data.userId);
  const statsDoc = await transaction.get(statsRef);
  if (statsDoc.exists) {
    const statsData = statsDoc.data()!;
    const level = statsData.avatarStats?.level ?? 1;
    const xpLoss = Math.floor(level * 500 * 0.05); // 5% of level XP
    const currentXp = statsData.avatarStats?.totalXp ?? 0;
    const levelMinXp = (level - 1) * 500;
    const newXp = Math.max(levelMinXp, currentXp - xpLoss);
    
    transaction.update(statsRef, {
      "avatarStats.totalXp": newXp,
      "worldState.entropy": admin.firestore.FieldValue.increment(0.1)
    });
  }
}
```

- [ ] **Step 3: Deploy Functions**
Run: `firebase deploy --only functions:applyDailyMomentumDecay`

---

### Task 2: AI-Driven Weekly Recap (Gen 2)

**Files:**
- Create: `functions/src/ai_recap.ts`
- Modify: `lib/features/gamification/domain/services/weekly_recap_service.dart`

- [ ] **Step 1: Create Gen 2 AI Insight Function**
Implement the AI coach that analyzes velocity and updates difficulty.

```typescript
// functions/src/ai_recap.ts
import { onCall } from "firebase-functions/v2/https";

export const generateAiRecap = onCall(async (request) => {
  const { userId, habitVelocity } = request.data;
  // AI Logic: If velocity > 0.9, set difficulty = 'hard'
  // If velocity < 0.3, set difficulty = 'easy'
  // Update Firestore habits collection automatically
});
```

- [ ] **Step 2: Update Flutter Recap Service to trigger AI**
Modify `WeeklyRecapService` to call the new Gen 2 function.

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: add ai-driven difficulty calibration"`

---

### Task 3: Visual Entropy Rendering

**Files:**
- Modify: `lib/core/presentation/widgets/world_background.dart`
- Modify: `lib/core/domain/models/app_world_theme.dart`

- [ ] **Step 1: Pass Entropy to WorldBackground**
Update `WorldBackground` to read entropy from `UserProfile` and pass it to the shader.

```dart
// lib/core/presentation/widgets/world_background.dart

// Inside build method:
final entropy = ref.watch(userStatsProvider).value?.worldState.entropy ?? 0.0;
return ShaderMask(
  shaderCallback: (rect) => nebulaShader.setFloat(0, entropy), // Pass entropy to uEntropy
  child: const NebulaBackground(),
);
```

- [ ] **Step 2: Update Shader for Visual Decay**
Modify the GLSL shader to apply desaturation and noise based on `uEntropy`.

- [ ] **Step 3: Verify Visuals**
Run the app and manually set entropy to 1.0 in Firestore to verify the "Fog" and "Static" effects.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: visual entropy shader rendering"`
