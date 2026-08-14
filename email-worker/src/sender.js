import nodemailer from "nodemailer";

/**
 * SMTP sender — replaces the Resend API. Configured via env vars:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
 *   EMAIL_FROM          (default "Emerge <no-reply@emerge.app>")
 *   EMAIL_OVERRIDE_TO   optional — when set, EVERY email is routed to this
 *                       single inbox instead of the recipient (test mode /
 *                       "send everything to my account").
 *   EMAIL_SMTP_SECURE   "true" to force TLS (defaults to true on 465).
 */
export function sendEmail({ to, subject, html }) {
  const host = process.env.SMTP_HOST;
  if (!host) {
    throw new Error("SMTP_HOST not configured");
  }
  const port = Number(process.env.SMTP_PORT ?? "587");
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const override = process.env.EMAIL_OVERRIDE_TO;
  const from = process.env.EMAIL_FROM ?? "Emerge <no-reply@emerge.app>";

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
