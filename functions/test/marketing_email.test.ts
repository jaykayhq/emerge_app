const axiosPost = jest.fn().mockResolvedValue({ status: 200 });
jest.mock("axios", () => ({ post: (...args: unknown[]) => axiosPost(...args) }));

// firebase-functions-test's makeDocumentSnapshot must return a real admin
// DocumentSnapshot (the event generator checks instanceof), so firebase-admin
// is used unmocked — offline snapshot construction makes no network calls.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ft = require("firebase-functions-test")();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { sendWelcomeEmail } = require("../src/marketing_email");

beforeEach(() => {
  jest.clearAllMocks();
  process.env.RESEND_API_KEY = "re_test_123";
});

describe("sendWelcomeEmail", () => {
  it("sends a welcome email for a valid new user", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u1" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "a@b.com", displayName: "Aria" },
          "users/u1"
        ),
      }
    );
    expect(axiosPost).toHaveBeenCalledTimes(1);
    const [, body] = axiosPost.mock.calls[0];
    expect(body.to).toBe("a@b.com");
    expect(body.subject).toContain("Welcome to Emerge");
  });

  it("skips users without a valid email", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "u2" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "", displayName: "NoEmail" },
          "users/u2"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("skips system/seed creator docs", async () => {
    const wrapped = ft.wrap(sendWelcomeEmail);
    await wrapped(
      {
        params: { uid: "system" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "system@emerge.app", creatorUserId: "system" },
          "users/system"
        ),
      }
    );
    expect(axiosPost).not.toHaveBeenCalled();
  });

  it("swallows send failures without throwing", async () => {
    axiosPost.mockRejectedValueOnce(new Error("500 down"));
    const wrapped = ft.wrap(sendWelcomeEmail);
    await expect(
      wrapped({
        params: { uid: "u3" },
        data: ft.firestore.makeDocumentSnapshot(
          { email: "c@d.com", displayName: "C" },
          "users/u3"
        ),
      })
    ).resolves.toBeUndefined();
  });
});
