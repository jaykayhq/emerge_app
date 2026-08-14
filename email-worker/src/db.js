import { initializeApp, cert } from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import fs from "node:fs";

let app;

/**
 * Initializes firebase-admin. The service-account JSON comes from one of:
 *   FIREBASE_SERVICE_ACCOUNT_JSON  the JSON itself (GitHub Actions passes
 *                                  secrets via env vars — no shell escaping
 *                                  or newline mangling)
 *   FIREBASE_SERVICE_ACCOUNT       path to a service-account JSON file
 *                                  (local runs)
 */
export function initDb() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const path = process.env.FIREBASE_SERVICE_ACCOUNT;
  let serviceAccount;
  if (inline) {
    serviceAccount = JSON.parse(inline);
  } else if (path) {
    serviceAccount = JSON.parse(fs.readFileSync(path, "utf8"));
  } else {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON (inline JSON) or FIREBASE_SERVICE_ACCOUNT (file path) is required",
    );
  }
  if (!app) {
    app = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }
  return { db: getFirestore(app), auth: getAuth(app) };
}
