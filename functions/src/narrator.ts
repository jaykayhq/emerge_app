/**
 * Narrator Slot-Filling Cloud Function
 *
 * Called from the Flutter client when a Narrator trigger fires.
 * Fills template slots using Groq AI - lightweight, fast (<1.5s target),
 * max 15 words per slot. Falls back to static template defaults on failure.
 *
 * Trigger types handled:
 *   - morningBriefEarlyDays  → world overnight update + single focus
 *   - streakBreakFirstMiss   → compassionate reframe
 *   - onFireState            → world visual achievement + challenge
 *   - levelUp                → level narrative + world change description
 *   - weeklyRecap            → week narrative + pattern insight
 *   - longAbsence            → world state description + decay effect
 *   - newHabitCreation       → why this habit matters + suggested anchor
 *   - eveningReflection      → day narrative + focused question
 *   - dailyInsight           → pattern observation + action question
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";

interface SlotRequest {
  trigger: string;
  userId: string;
  slotKeys: string[];
  context?: Record<string, unknown>;
}

interface SlotResponse {
  slots: Record<string, string>;
}

// ── Trigger-specific prompt builders ──────────────────────────────────────

function buildPrompt(trigger: string, context: Record<string, unknown>): string {
  const archetype = (context.archetype as string) || "user";
  const habitName = (context.habitName as string) || "habit";

  switch (trigger) {
    case "morningBriefEarlyDays":
      return `User is a ${archetype}. Provide a 10-word world overnight update (what changed in their fantasy world) and a 12-word single focus for today. JSON: {"worldUpdate":"...","singleFocus":"..."}`;

    case "streakBreakFirstMiss":
      return `User skipped ${habitName}. Give a 15-word compassionate reframe in identity-language — make them feel strong, not shamed. JSON: {"compassionateReframe":"..."}`;

    case "onFireState":
      return `User is on a streak. Describe a visual achievement in their world (8 words) and suggest a challenge to raise the bar (12 words). JSON: {"visualAchievement":"...","challengeSuggestion":"..."}`;

    case "levelUp":
      return `User just leveled up as a ${archetype}. Tell a 2-sentence narrative (max 25 words total) about what this level means in their world. Describe one visible world change (8 words). JSON: {"levelNarrative":"...","worldChange":"..."}`;

    case "weeklyRecap":
      return `User is a ${archetype}. Write a 15-word narrative of their week using identity-language. Add one 10-word insight from behavior patterns. JSON: {"weekNarrative":"...","patternInsight":"..."}`;

    case "longAbsence":
      return `User returned after absence. Describe what decayed in their ${archetype} world (10 words). No shame. Frame it as recoverable. Name one decay effect (5 words). JSON: {"worldStateDesc":"...","decayEffect":"..."}`;

    case "newHabitCreation":
      return `User wants to build: ${context.habitGoal || "a new habit"}. In 12 words, identity-frame why this matters. Suggest one anchor habit from context. JSON: {"whyThisMatters":"...","suggestedAnchor":"..."}`;

    case "eveningReflection":
      return `User as ${archetype} did ${context.completedCount || "some"} of ${context.totalHabits || "their"} habits. Frame the day in 10 words. Ask one focused 8-word question that reflects on patterns. JSON: {"dayNarrative":"...","focusedQuestion":"...","suggestedResponseA":"...","suggestedResponseB":"..."}`;

    case "dailyInsight":
      return `Analyze habit patterns for a ${archetype}. Give a 15-word pattern observation using identity-language. Ask one 10-word action question. JSON: {"patternObservation":"...","actionQuestion":"...","actionA":"...","actionB":"..."}`;

    default:
      return `Generic context for trigger ${trigger}. Provide a short 10-word message. JSON: {"message":"..."}`;
  }
}

// ── Groq API caller ───────────────────────────────────────────────────────

async function callGroq(prompt: string): Promise<Record<string, string>> {
  const apiKey = process.env.GROQ_API_KEY;

  if (!apiKey) {
    console.warn("[narrator] GROQ_API_KEY not configured, using fallback");
    return {};
  }

  try {
    console.log("[narrator] Requesting Groq slot fill...");
    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "llama-3.1-8b-instant",
          messages: [
            {
              role: "system",
              content:
                "You fill template slots for a narrating AI in a habit-tracking game app. " +
                "Always respond with ONLY valid JSON, no extra text. Max 15 words per slot. " +
                "Use identity-language — make users feel like they're becoming someone, not just doing tasks. " +
                "Never shame. Always make the user feel strong and in control of their story.",
            },
            {
              role: "user",
              content: prompt,
            },
          ],
          response_format: { type: "json_object" },
          max_tokens: 200,
          temperature: 0.7,
        }),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[narrator] Groq API error (${response.status}):`, errorText);
      return {};
    }

    const data = (await response.json()) as any;
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      console.warn("[narrator] Empty Groq response");
      return {};
    }

    const parsed = JSON.parse(content);
    console.log("[narrator] Groq slots filled:", Object.keys(parsed));
    return parsed;
  } catch (err) {
    console.error("[narrator] Groq call failed:", err);
    return {};
  }
}

// ── Fallback slot values ─────────────────────────────────────────────────

const fallbackSlots: Record<string, Record<string, string>> = {
  morningBriefEarlyDays: {
    worldUpdate: "Your world stirred overnight. New energy hums beneath the surface.",
    singleFocus: "Today, do one thing that moves you closer to who you're becoming.",
  },
  streakBreakFirstMiss: {
    compassionateReframe:
      "You built something real. One missed day doesn't erase that. You're still the person who showed up.",
  },
  onFireState: {
    visualAchievement: "A golden aura now surrounds your world. The land is thriving.",
    challengeSuggestion: "Raise the bar: add one more minute, one more rep, one more page.",
  },
  levelUp: {
    levelNarrative:
      "You've crossed a threshold. The world remembers this moment. Your legend grows deeper.",
    worldChange: "New paths open. Old barriers dissolve. Your domain expands.",
  },
  weeklyRecap: {
    weekNarrative:
      "This week, you cast votes for the person you're becoming. Every habit was a ballot.",
    patternInsight: "You showed up when it mattered. That consistency is your real power.",
  },
  longAbsence: {
    worldStateDesc:
      "Your world grew quiet but not broken. The land waits patiently for your return.",
    decayEffect: "Minor overgrowth — easily cleared with one habit.",
  },
  newHabitCreation: {
    whyThisMatters:
      "This habit isn't a task — it's a vote for the person you're deciding to become.",
    suggestedAnchor: "Right after your morning routine",
  },
  eveningReflection: {
    dayNarrative:
      "Today was another page in your story. Some chapters are longer than others.",
    focusedQuestion: "What's one thing you did today that surprised you?",
    suggestedResponseA: "I pushed harder than expected",
    suggestedResponseB: "I learned something new about myself",
  },
  dailyInsight: {
    patternObservation:
      "You're building patterns that become identity. The small choices are adding up.",
    actionQuestion: "What's the one habit you're most proud of today?",
    actionA: "My morning routine",
    actionB: "Show me the data",
  },
};

// ── Exported callable ─────────────────────────────────────────────────────

/**
 * Fills Narrator template slots using Groq AI.
 *
 * Called from Flutter via `FirebaseFunctions.instance.httpsCallable('fillNarratorSlots')`.
 * Returns within ~1.5s. Falls back to static text if Groq is unavailable.
 */
export const fillNarratorSlots = onCall<SlotRequest, Promise<SlotResponse>>(
  {
    secrets: ["GROQ_API_KEY"],
    memory: "256MiB",
    cpu: 1,
    concurrency: 80,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in");
    }

    const { trigger, context = {} } = request.data;

    console.log(
      `[narrator] fillNarratorSlots called: trigger=${trigger}, userId=${request.auth.uid}`
    );

    const prompt = buildPrompt(trigger, context as Record<string, unknown>);
    const groqSlots = await callGroq(prompt);

    // Merge Groq response with fallbacks — Groq wins when available
    const triggerFallbacks = fallbackSlots[trigger] || {};
    const merged: Record<string, string> = {
      ...triggerFallbacks,
      ...groqSlots,
    };

    console.log(`[narrator] Returning ${Object.keys(merged).length} slots`);
    return { slots: merged };
  }
);
