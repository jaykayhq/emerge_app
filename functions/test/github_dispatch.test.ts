import {
  decideDispatchEvent,
  dispatchGitHubEvent,
} from "../src/github_dispatch";

const axiosPost = jest.fn().mockResolvedValue({ status: 204 });

jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

describe("decideDispatchEvent", () => {
  it("dispatches user-signed-up on account creation", () => {
    expect(decideDispatchEvent(undefined, { email: "a@b.com" })).toBe(
      "user-signed-up",
    );
  });

  it("skips system/seed and admin accounts", () => {
    expect(
      decideDispatchEvent(undefined, { creatorUserId: "system" }),
    ).toBeNull();
    expect(decideDispatchEvent(undefined, { isAdmin: true })).toBeNull();
  });

  it("dispatches verification-requested when the marker is set", () => {
    expect(
      decideDispatchEvent(
        { email: "a@b.com" },
        { email: "a@b.com", verificationRequestedAt: { _seconds: 1 } },
      ),
    ).toBe("verification-requested");
  });

  it("ignores unrelated updates", () => {
    expect(
      decideDispatchEvent({ email: "a@b.com" }, { email: "a@b.com" }),
    ).toBeNull();
  });

  it("ignores deletions", () => {
    expect(decideDispatchEvent({ email: "a@b.com" }, undefined)).toBeNull();
  });
});

describe("dispatchGitHubEvent", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    axiosPost.mockResolvedValue({ status: 204 });
  });

  it("POSTs a repository_dispatch event with the PAT", async () => {
    await dispatchGitHubEvent("jaykayhq/emerge_app", "ghp_123", "user-signed-up");

    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [url, body, config] = axiosPost.mock.calls[0];
    expect(url).toBe("https://api.github.com/repos/jaykayhq/emerge_app/dispatches");
    expect(body).toEqual({ event_type: "user-signed-up" });
    expect(config.headers.Authorization).toBe("Bearer ghp_123");
    expect(config.timeout).toBe(10_000);
  });
});
