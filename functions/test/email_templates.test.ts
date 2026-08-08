import {
  buildWelcomeHtml,
  buildReengagementHtml,
} from "../src/email_templates";

describe("email templates", () => {
  it("welcome html includes the display name and CTA", () => {
    const html = buildWelcomeHtml("Aria");
    expect(html).toContain("Aria");
    expect(html).toContain("Start exploring");
    expect(html).toContain("Your journey begins now");
  });

  it("reengagement html includes the name and a nudge", () => {
    const html = buildReengagementHtml("Aria");
    expect(html).toContain("Aria");
    expect(html).toContain("Coming back");
  });

  it("handles a missing name gracefully", () => {
    expect(buildWelcomeHtml(undefined)).toContain("friend");
    expect(buildWelcomeHtml("")).toContain("friend");
    expect(buildWelcomeHtml("   ")).toContain("friend");
    expect(buildWelcomeHtml("")).not.toContain("undefined");
  });

  it("escapes special characters in the display name", () => {
    const html = buildWelcomeHtml("<script>alert(1)</script>");
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
  });
});
