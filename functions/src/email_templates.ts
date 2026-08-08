/**
 * Inline-styled, mobile-friendly HTML for the marketing emails. No template
 * engine — the strings are small and versioned in code.
 */

const baseStyles =
  "font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;" +
  "background:#0A0A1A;color:#F5F0E8;padding:32px 16px;text-align:center";

const buttonStyles =
  "display:inline-block;margin-top:20px;padding:14px 28px;border-radius:12px;" +
  "background:#2DD4BF;color:#0A0A1A;font-weight:bold;text-decoration:none";

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function safeName(name: string | undefined): string {
  const trimmed = (name ?? "").trim();
  return trimmed.length > 0 ? escapeHtml(trimmed) : "friend";
}

export function buildWelcomeHtml(name?: string): string {
  const displayName = safeName(name);
  return `
    <div style="${baseStyles}">
      <h1 style="color:#2DD4BF;">Welcome to Emerge, ${displayName}.</h1>
      <p style="font-size:16px;line-height:1.6;">
        Your journey begins now. Build one small habit, earn XP, and watch
        your avatar evolve into the person you're becoming.
      </p>
      <a href="https://emerge.app/timeline" style="${buttonStyles}">
        Start exploring
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        Your journey begins now — one habit at a time.
      </p>
    </div>`;
}

export function buildReengagementHtml(name?: string): string {
  const displayName = safeName(name);
  return `
    <div style="${baseStyles}">
      <h1 style="color:#2DD4BF;">We miss you, ${displayName}.</h1>
      <p style="font-size:16px;line-height:1.6;">
        Your identity is built in small moments. Even one habit today keeps
        the streak alive — and your avatar keeps evolving.
      </p>
      <a href="https://emerge.app/timeline" style="${buttonStyles}">
        Coming back
      </a>
      <p style="font-size:12px;color:#8B8B8B;margin-top:28px;">
        A small step is still a step forward.
      </p>
    </div>`;
}
