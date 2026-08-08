/**
 * Sends a transactional email via Resend. The calling Cloud Function MUST
 * declare `secrets: ["RESEND_API_KEY"]` or the key will be undefined here.
 * RESEND_API_KEY lives in function secrets — never client-visible.
 */
import axios from "axios";

export interface EmailPayload {
  to: string;
  subject: string;
  html: string;
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
      timeout: 10_000,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    }
  );
}
