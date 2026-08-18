#!/usr/bin/env node
// Publish a release AAB to Google Play via the Play Developer API v3.
//
// One-time setup (browser, ~10 min):
//   1. Play Console -> Create app for com.emerge.emerge_app (the API can't do this)
//   2. Enable the "Play Developer API" on the GCP project linked to Play
//   3. Play Console -> Setup -> API access -> create a service account with the
//      "Release manager" role, download its JSON key to scripts/service-account-key.json
//
// Usage:
//   flutter build appbundle --release --target-platform android-arm64
//   python scripts/strip_aab.py
//   node scripts/play_deploy.mjs [flags]
//
// --target-platform android-arm64: release bundles ship arm64-only (Play's
// 64-bit requirement; minSdk 26 excludes nearly all 32-bit devices). Debug
// and flutter run keep all ABIs, so emulators are unaffected.
//
// Flags (defaults in parens):
//   --key <json>     service account key file (scripts/service-account-key.json)
//   --aab <path>     release bundle (build/app/outputs/bundle/release/app-release.aab)
//   --package <id>   application id (com.emerge.emerge_app)
//   --track <name>   internal | alpha | beta | production (internal)
//   --status <name>  draft | inProgress | completed | halted (completed; use draft for a first release)
//   --notes <text>   release notes (falls back to the pubspec version)
//   --countries <cc> comma-separated region codes (e.g. US,NG,GB); defaults to
//                   all countries (includeRestOfWorld)
//   --help           show this message

import { createReadStream, existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { google } from 'googleapis';

const SCOPE = ['https://www.googleapis.com/auth/androidpublisher'];
const TRACKS = new Set(['internal', 'alpha', 'beta', 'production']);
const STATUSES = new Set(['draft', 'inProgress', 'completed', 'halted']);
const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const DEFAULTS = {
  key: path.join(REPO_ROOT, 'scripts', 'service-account-key.json'),
  aab: path.join(REPO_ROOT, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'),
  package: 'com.emerge.emerge_app',
  track: 'internal',
  status: 'completed',
};

function usage() {
  console.log(`Publish a release AAB to Google Play via the Play Developer API v3.

Usage:
  node scripts/play_deploy.mjs [flags]

Flags:
  --key <json>     service account key file (${DEFAULTS.key})
  --aab <path>     release bundle (${DEFAULTS.aab})
  --package <id>   application id (${DEFAULTS.package})
  --track <name>   ${[...TRACKS].join(' | ')} (${DEFAULTS.track})
  --status <name>  ${[...STATUSES].join(' | ')} (${DEFAULTS.status})
  --notes <text>   release notes (falls back to the pubspec version)
  --countries <cc> comma-separated region codes (e.g. US,NG,GB); defaults to
                   all countries (includeRestOfWorld)
  --help           show this message

Build the bundle first:
  flutter build appbundle --release`);
}

function parseArgs(argv) {
  const args = { ...DEFAULTS };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    let flag = arg;
    let value;
    const eq = arg.indexOf('=');
    if (eq !== -1) {
      flag = arg.slice(0, eq);
      value = arg.slice(eq + 1);
    }
    if (flag === '--help') {
      args.help = true;
    } else if (['--key', '--aab', '--package', '--track', '--status', '--notes', '--countries'].includes(flag)) {
      if (value === undefined) value = argv[++i];
      if (value === undefined) throw new Error(`Missing value for ${flag}`);
      args[flag.slice(2)] = value;
    } else {
      throw new Error(`Unknown flag: ${arg}`);
    }
  }
  return args;
}

function pubspecVersion() {
  try {
    const line = readFileSync(path.join(REPO_ROOT, 'pubspec.yaml'), 'utf8')
      .split('\n')
      .find((l) => l.startsWith('version:'));
    const match = line?.match(/version:\s*(\S+)/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

function fail(error) {
  const status = error?.response?.status;
  const message = error?.response?.data?.error?.message ?? error?.message ?? String(error);
  switch (status) {
    case 401:
      console.error(`Auth failed (401): ${message}\nIs the service account key valid?`);
      break;
    case 403:
      if (message.includes('Version code')) {
        console.error(`Upload rejected: ${message}\n` +
          'Version codes must be unique across all tracks. Bump the version in\n' +
          'pubspec.yaml (e.g. 1.0.6+11) and rebuild.');
      } else if (message.includes('targeting no countries')) {
        console.error(`Upload rejected: ${message}\n` +
          'The first production release must be created in the Play Console\n' +
          '(Release -> Production -> Create release) — the API cannot stage it\n' +
          'and a completed release requires availability that only the console\n' +
          'can declare on a first release. Afterwards, the script works.');
      } else {
        console.error(`Permission denied (403): ${message}\n` +
          'Enable the Play Developer API on the linked GCP project and give the service\n' +
          'account the "Release manager" role in Play Console -> Setup -> API access.');
      }
      break;
    case 404:
      console.error(`Not found (404): ${message}\n` +
        'Create the app entry for this package in Play Console first — the API cannot create apps.');
      break;
    default:
      console.error(`Play API error${status ? ` (${status})` : ''}: ${message}`);
  }
  process.exitCode = 1;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    usage();
    return;
  }
  if (!TRACKS.has(args.track)) throw new Error(`Unknown track "${args.track}" — use one of: ${[...TRACKS].join(', ')}`);
  if (!STATUSES.has(args.status)) throw new Error(`Unknown status "${args.status}" — use one of: ${[...STATUSES].join(', ')}`);
  if (!existsSync(args.key)) {
    throw new Error(`Service account key not found: ${args.key}\n` +
      'Download it from Play Console -> Setup -> API access and save it there.');
  }
  if (!existsSync(args.aab)) {
    throw new Error(`AAB not found: ${args.aab}\nBuild it first: flutter build appbundle --release`);
  }

  const auth = new google.auth.GoogleAuth({ keyFile: args.key, scopes: SCOPE });
  const api = google.androidpublisher({ version: 'v3', auth });

  const createEdit = async () => {
    const { data: edit } = await api.edits.insert({ packageName: args.package });
    console.log(`Edit created: ${edit.id}`);
    return edit.id;
  };
  const uploadBundle = async (editId) => {
    const { data: bundle } = await api.edits.bundles.upload({
      packageName: args.package,
      editId,
      media: { mimeType: 'application/octet-stream', body: createReadStream(args.aab) },
    });
    console.log(`Uploaded bundle versionCode ${bundle.versionCode}`);
    return bundle;
  };
  const setTrack = async (editId, status, targeting, fraction, notes, versionCode) => {
    await api.edits.tracks.update({
      packageName: args.package,
      editId,
      track: args.track,
      requestBody: {
        track: args.track,
        releases: [
          {
            versionCodes: [versionCode],
            status,
            ...(targeting ? { countryTargeting: targeting } : {}),
            ...(fraction !== undefined ? { userFraction: fraction } : {}),
            releaseNotes: [{ language: 'en-US', text: notes }],
          },
        ],
      },
    });
    console.log(`Track "${args.track}" set to ${status} with notes: "${notes}"`);
  };
  const commitEdit = async (editId) => {
    await api.edits.commit({ packageName: args.package, editId });
    console.log('Edit committed.');
  };

  const countryTargeting = args.countries
    ? {
        countries: args.countries
          .split(',')
          .map((code) => ({ language: 'en', regionCode: code.trim().toUpperCase() })),
        includeRestOfWorld: false,
      }
    : { countries: [], includeRestOfWorld: true };

  // The API only accepts countryTargeting on staged (inProgress) releases; a
  // completed release inherits the track's existing availability. The console
  // is required only for the FIRST production release (see fail() 403 branch).
  if (args.status === 'completed' && args.countries) {
    throw new Error(
      `--countries cannot be applied to a ${args.status} release: the API only accepts ` +
        "country targeting on staged releases, and a completed release inherits the track's " +
        'existing availability. Use --status inProgress for a staged rollout.',
    );
  }

  const editId = await createEdit();
  const bundle = await uploadBundle(editId);
  const notes = args.notes ?? pubspecVersion() ?? `Version ${bundle.versionCode}`;

  await setTrack(
    editId,
    args.status,
    args.status === 'completed' ? null : countryTargeting,
    undefined,
    notes,
    bundle.versionCode,
  );
  await commitEdit(editId);
  console.log(
    `Done. versionCode ${bundle.versionCode} live on "${args.track}" ` +
    `(https://play.google.com/console/developers, app ${args.package} -> Releases -> ${args.track})`
  );
}

try {
  await main();
} catch (error) {
  if (error instanceof Error && (error.response !== undefined || error.errors !== undefined)) {
    fail(error);
  } else {
    console.error(`Error: ${error.message}`);
    process.exitCode = 1;
  }
}
