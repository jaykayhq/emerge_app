const axiosPost = jest.fn().mockResolvedValue({ status: 200 });

jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

import { sendEmail } from "../src/email";

describe("sendEmail", () => {
  beforeEach(() => {
    process.env.RESEND_API_KEY = "re_test_123";
  });

  afterEach(() => jest.clearAllMocks());

  it("throws when RESEND_API_KEY is missing", async () => {
    delete process.env.RESEND_API_KEY;
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toThrow("RESEND_API_KEY not configured");
  });

  it("POSTs to the Resend API with auth header", async () => {
    await sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" });
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [url, body, config] = axiosPost.mock.calls[0];
    expect(url).toBe("https://api.resend.com/emails");
    expect(body).toMatchObject({
      from: "Emerge <no-reply@emerge.app>",
      to: "a@b.com",
      subject: "Hi",
      html: "<p>Hi</p>",
    });
    expect(config.headers.Authorization).toBe("Bearer re_test_123");
  });

  it("uses the default 10s timeout when not provided", async () => {
    await sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" });
    const [, , config] = axiosPost.mock.calls[0];
    expect(config.timeout).toBe(10_000);
  });

  it("applies a custom timeout when provided", async () => {
    await sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>", timeoutMs: 5000 });
    const [, , config] = axiosPost.mock.calls[0];
    expect(config.timeout).toBe(5000);
  });

  it("propagates API errors", async () => {
    axiosPost.mockRejectedValueOnce(
      Object.assign(new Error("Request failed with status code 429"), {
        isAxiosError: true,
        name: "AxiosError",
        response: { data: { message: "rate limited" }, status: 429 },
      })
    );
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toMatchObject({ isAxiosError: true, name: "AxiosError" });
  });
});
