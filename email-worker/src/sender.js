import nodemailer from "nodemailer";

/**
 * SMTP sender — replaces the Resend API. Configured via env vars:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
 *   EMAIL_FROM          sender address. IMPORTANT: must be the same account
 *                       that authenticates via SMTP_USER (e.g. a Gmail
 *                       address) — otherwise the mail is not DKIM-signed,
 *                       fails DMARC, and lands in spam. Defaults to the
 *                       authenticated SMTP user, else joeukpai55@gmail.com
 *                       (see resolveFrom).
 *   EMAIL_OVERRIDE_TO   optional — when set, EVERY email is routed to this
 *                       single inbox instead of the recipient (test mode /
 *                       "send everything to my account").
 *   EMAIL_SMTP_SECURE   "true" to force TLS (defaults to true on 465).
 */

/**
 * Picks the From address. EMAIL_FROM wins when set; otherwise the
 * authenticated SMTP user (so Gmail DKIM-signs it); last resort is the
 * owner Gmail (the parked emerge.app domain was removed — it had no DNS
 * records, so mail sent from it always landed in spam). An empty EMAIL_FROM
 * (unset GitHub secret) counts as unset.
 */
export function resolveFrom(env = process.env) {
  const explicit = env.EMAIL_FROM?.trim();
  if (explicit) {
    return explicit;
  }
  const user = env.SMTP_USER?.trim();
  if (user) {
    return `Emerge <${user}>`;
  }
  return "Emerge <joeukpai55@gmail.com>";
}

export function sendEmail({ to, subject, html }) {
  const host = process.env.SMTP_HOST;
  if (!host) {
    throw new Error("SMTP_HOST not configured");
  }
  const port = Number(process.env.SMTP_PORT ?? "587");
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const override = process.env.EMAIL_OVERRIDE_TO;
  const from = resolveFrom(process.env);

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: process.env.EMAIL_SMTP_SECURE === "true" || port === 465,
    auth: user && pass ? { user, pass } : undefined,
  });

  return transporter.sendMail({
    from,
    to: override || to,
    subject,
    html,
  });
}
