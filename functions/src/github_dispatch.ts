/**
 * GitHub Actions dispatch bridge.
 *
 * Firebase cannot trigger GitHub Actions directly, so this single function
 * converts Firestore user events into GitHub `repository_dispatch` calls:
 *
 *   users/{uid} created            -> event_type "user-signed-up"
 *   users/{uid}.verificationRequestedAt set -> event_type "verification-requested"
 *
 * The email worker (GitHub Actions) reacts by sending the welcome /
 * verification emails via SMTP. This function NEVER sends email — it is a
 * tiny webhook only. The 5-minute welcome/verify cron remains as a fallback
 * so a failed dispatch (GitHub API down, PAT expired) never blocks email
 * delivery.
 *
 * Env: GITHUB_DISPATCH_TOKEN (a fine-grained PAT with Contents: write for
 * the repo — set via `firebase functions:set-env-vars`); GITHUB_REPO
 * (default "jaykayhq/emerge_app").
 */
import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import axios from "axios";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const GITHUB_REPO = process.env.GITHUB_REPO ?? "jaykayhq/emerge_app";

/** Testable dispatch call. */
export async function dispatchGitHubEvent(
  repo: string,
  token: string,
  eventType: string,
): Promise<void> {
  await axios.post(
    `https://api.github.com/repos/${repo}/dispatches`,
    { event_type: eventType },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
      },
      timeout: 10_000,
    },
  );
}

/**
 * Pure decision: which event (if any) a users/{uid} write should dispatch.
 * Mirrors the repo's testable-decision pattern.
 */
export function decideDispatchEvent(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): string | null {
  if (!after) return null;
  // Seed/system and admin accounts never receive marketing emails.
  if (after.creatorUserId === "system" || after.isAdmin === true) return null;

  const isCreate = before === undefined;
  const verificationRequested =
    before?.verificationRequestedAt == null &&
    after.verificationRequestedAt != null;

  if (isCreate) return "user-signed-up";
  if (verificationRequested) return "verification-requested";
  return null;
}

export const dispatchEmailWorkflow = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const token = process.env.GITHUB_DISPATCH_TOKEN;
    const eventType = decideDispatchEvent(
      event.data?.before?.data(),
      event.data?.after?.data(),
    );
    if (!eventType) return;
    if (!token) {
      console.warn("GITHUB_DISPATCH_TOKEN not set — skipping dispatch");
      return;
    }
    try {
      await dispatchGitHubEvent(GITHUB_REPO, token, eventType);
      console.log(`[dispatch] sent ${eventType} for ${event.params.uid}`);
    } catch (err) {
      // Never throw across the boundary: the cron fallback covers delivery.
      console.error(`[dispatch] ${eventType} failed:`, err);
    }
  },
);
