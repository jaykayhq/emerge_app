import admin from "firebase-admin";
import fs from "node:fs";

let app;

/**
 * Initializes firebase-admin from the service-account JSON path in
 * `FIREBASE_SERVICE_ACCOUNT` (GitHub Actions writes the secret JSON to a
 * temp file and points this env var at it).
 */
export function initDb() {
  const path = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!path) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT env var must point at the service-account JSON file",
    );
  }
  if (!app) {
    const serviceAccount = JSON.parse(fs.readFileSync(path, "utf8"));
    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }
  return { db: admin.firestore(), auth: admin.auth() };
}
