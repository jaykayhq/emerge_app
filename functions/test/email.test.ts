const axiosPost = jest.fn().mockResolvedValue({ status: 200 });

jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

import { sendEmail } from "../src/email";

describe("sendEmail", () => {
  afterEach(() => jest.clearAllMocks());

  it("throws when RESEND_API_KEY is missing", async () => {
    delete process.env.RESEND_API_KEY;
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toThrow("RESEND_API_KEY not configured");
  });

  it("POSTs to the Resend API with auth header", async () => {
    process.env.RESEND_API_KEY = "re_test_123";
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
    expect(config.timeout).toBe(10_000);
  });

  it("propagates API errors", async () => {
    process.env.RESEND_API_KEY = "re_test_123";
    axiosPost.mockRejectedValueOnce(new Error("429 too many"));
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>Hi</p>" })
    ).rejects.toThrow("429 too many");
  });
});
