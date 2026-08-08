import { buildWelcomeHtml, buildReengagementHtml } from "../src/email_templates";

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
    expect(buildWelcomeHtml(undefined)).toContain("Welcome");
    expect(buildWelcomeHtml("")).not.toContain("undefined");
  });
});
