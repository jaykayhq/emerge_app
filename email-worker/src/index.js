import { initDb } from "./db.js";
import { sendEmail } from "./sender.js";
import { runWelcomeTask } from "./tasks/welcome.js";
import { runDripTask } from "./tasks/drip.js";
import { runGraceTask } from "./tasks/grace.js";

/**
 * Emerge email worker — runs in GitHub Actions (see
 * .github/workflows/emails.yml). Usage:
 *   node src/index.js [--task welcome|drip|grace|all] [--dry-run]
 *
 * Env:
 *   FIREBASE_SERVICE_ACCOUNT  path to the service-account JSON
 *   SMTP_HOST/PORT/USER/PASS  SMTP credentials (sender.js)
 *   EMAIL_OVERRIDE_TO         optional: route every email to one inbox
 */
const args = process.argv.slice(2);
const taskArg = args.includes("--task")
  ? args[args.indexOf("--task") + 1]
  : "all";
const dryRun = args.includes("--dry-run");

const TASKS = {
  welcome: (db, auth) => runWelcomeTask(db, { send: sendEmail, dryRun }),
  drip: (db, auth) => runDripTask(db, { send: sendEmail, dryRun }),
  grace: (db, auth) => runGraceTask(db, auth, { dryRun }),
};

async function main() {
  if (dryRun) {
    console.log("=== DRY RUN — no emails sent, no documents written ===");
  }
  const { db, auth } = initDb();

  const tasks = taskArg === "all" ? Object.keys(TASKS) : [taskArg];
  const errors = [];
  for (const task of tasks) {
    if (!TASKS[task]) {
      throw new Error(`Unknown task "${task}" (expected welcome|drip|grace|all)`);
    }
    try {
      console.log(`--- Running task: ${task} ---`);
      await TASKS[task](db, auth);
    } catch (err) {
      console.error(`[${task}] task failed:`, err);
      errors.push(task);
    }
  }

  if (errors.length > 0) {
    console.error(`Failed tasks: ${errors.join(", ")}`);
    process.exit(1);
  }
  console.log("Email worker finished.");
}

main().catch((err) => {
  console.error("Email worker failed:", err);
  process.exit(1);
});
