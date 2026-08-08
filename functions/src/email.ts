/**
 * Shared transactional/marketing email helper (Resend). Used by the welcome
 * trigger and the re-engagement drip (marketing_email.ts). RESEND_API_KEY is a
 * function secret — never client-visible.
 */
import axios from "axios";

export interface EmailPayload {
  to: string;
  subject: string;
  html: string;
  timeoutMs?: number;
}

export async function sendEmail(payload: EmailPayload): Promise<void> {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    throw new Error("RESEND_API_KEY not configured");
  }
  await axios.post(
    "https://api.resend.com/emails",
    {
      from: "Emerge <no-reply@emerge.app>",
      to: payload.to,
      subject: payload.subject,
      html: payload.html,
    },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      timeout: payload.timeoutMs ?? 10_000,
    }
  );
}
