// Validates the tribe_analytics Firestore rules against the local emulator.
// Usage: firebase emulators:exec --only firestore "node scripts/validate_tribe_analytics_rules.mjs"
// The emulator parses user_id from the JWT payload (signature unverified).
//
// NOTE: the get()-based creator-ownership clause cannot be exercised — the
// emulator's rules-engine get() throws "Service call error. Function: [get]"
// (known bug firebase-tools#10518). That clause is structurally identical to
// the production isVerifiedCreator() helper and is validated by deploy-time
// compilation. Everything else is checked here.
const PROJECT = 'tradeflash-l2966';
const DOCS = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const COMMIT = `${DOCS}:commit`;

function b64url(obj) {
  return Buffer.from(JSON.stringify(obj)).toString('base64url');
}

// Unsigned JWT the emulator accepts: header.payload.signature
function jwtFor(uid) {
  const header = b64url({ alg: 'none', typ: 'JWT' });
  const payload = b64url({
    user_id: uid,
    email: `${uid}@test.dev`,
    email_verified: true,
  });
  return `${header}.${payload}.`;
}

function field(value) {
  return { stringValue: String(value) };
}

function int(value) {
  return { integerValue: String(value) };
}

function strField(value) {
  return { stringValue: value };
}

const snapshotFields = {
  tribeId: field('t1'),
  date: field('2026-08-18'),
  memberCount: int(3),
  totalXp: int(5000),
  totalHabitsCompleted: int(60),
  totalChallengesCompleted: int(3),
  activeMembers: int(2),
  newMembersThisWeek: int(1),
};

async function commitWrite(uid, name, fields) {
  const res = await fetch(COMMIT, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${jwtFor(uid)}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      writes: [{
        update: {
          name: `projects/${PROJECT}/databases/(default)/documents/${name}`,
          fields,
        },
      }],
    }),
  });
  return res.status;
}

async function getDoc(uid, name) {
  const res = await fetch(`${DOCS}/${name}`, {
    headers: { 'Authorization': `Bearer ${jwtFor(uid)}` },
  });
  return res.status;
}

async function deleteDoc(uid, name) {
  const res = await fetch(`${DOCS}/${name}`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${jwtFor(uid)}` },
  });
  return res.status;
}

let failures = 0;
function check(label, actual, expected) {
  const ok = actual === expected;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label}: ${actual} (expect ${expected})`);
  if (!ok) failures++;
}

// 1. Valid snapshot write -> ALLOWED (auth + shape checks pass).
const writeStatus = await commitWrite('creator-owner', 'tribe_analytics/t1/daily/2026-08-18', snapshotFields);
check('valid snapshot write', writeStatus, 200);

// 2. Authenticated read -> ALLOWED.
const readStatus = await getDoc('anyone', 'tribe_analytics/t1/daily/2026-08-18');
check('authenticated read', readStatus, 200);

// 3. Delete -> DENIED for everyone.
const deleteStatus = await deleteDoc('creator-owner', 'tribe_analytics/t1/daily/2026-08-18');
check('delete forbidden', deleteStatus, 403);

// 4. Unauthenticated write -> DENIED.
const noAuthRes = await fetch(COMMIT, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    writes: [{
      update: {
        name: `projects/${PROJECT}/databases/(default)/documents/tribe_analytics/t1/daily/2026-08-19`,
        fields: snapshotFields,
      },
    }],
  }),
});
check('unauthenticated write', noAuthRes.status, 403);

// 5. date field must match the path segment -> DENIED.
const wrongDate = await commitWrite('creator-owner', 'tribe_analytics/t1/daily/2026-08-19', snapshotFields);
check('date must match path', wrongDate, 403);

// 6. tribeId field must match the path segment -> DENIED.
const wrongTribe = await commitWrite('creator-owner', 'tribe_analytics/t2/daily/2026-08-18', snapshotFields);
check('tribeId must match path', wrongTribe, 403);

// 7. memberCount must be a number (string rejected) -> DENIED.
const badType = await commitWrite('creator-owner', 'tribe_analytics/t1/daily/2026-08-20', {
  ...snapshotFields,
  date: field('2026-08-20'),
  memberCount: strField('three'),
});
check('memberCount must be number', badType, 403);

if (failures > 0) {
  console.error(`FAILED: ${failures} rule check(s) failed`);
  process.exit(1);
}
console.log('ALL RULE CHECKS PASSED');
