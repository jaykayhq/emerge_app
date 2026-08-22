/**
 * Pure decision logic for the notification-push worker.
 *
 * Separated from Firestore/ FCM drivers so it can be unit-tested without
 * credentials. The worker entry (index.js) only orchestrates I/O.
 */

export const SPLASH_ICON = 'push_notification_icon';
export const SPLASH_COLOR = '#4850AE';

/**
 * Whether the notification at `notifData` should be pushed to the device
 * described by `userData`, given `now`.
 *
 * Mirrors `NotificationGate.shouldShow` for the `community` channel plus the
 * master switch and DND window. `notifData` and `userData` are the raw
 * Firestore document maps (not domain entities) so the worker does not need
 * the Dart model.
 *
 * @param {Record<string,any>} notifData
 * @param {Record<string,any>|null} userData
 * @param {Date} [now]
 * @returns {boolean}
 */
export function shouldPush(notifData, userData, now = new Date()) {
  if (!userData) return false;
  // If notifications are globally off, never push.
  const settings = userData.settings ?? {};
  const master = settings.notificationsEnabled ?? userData.notificationsEnabled ?? true;
  if (master === false) return false;
  // Social notifications are community kind — require communityUpdates.
  const community = settings.communityUpdates ?? userData.communityUpdates ?? true;
  // Default for communityUpdates in UserSettings is `false`.
  if (community === false) return false;
  // DND (22-07) is enforced client-side where the device's local clock is
  // available. The server runs in UTC and cannot reliably map the user's
  // quiet-hours window without a stored timezone, so it does not enforce DND
  // here — otherwise a UTC 23:00 runner would incorrectly suppress a user
  // in PST at 15:00.
  // Don't push already-read notifications (user already saw them in-app).
  if (notifData.read === true) return false;
  // Respect optional per-notification expiration.
  if (notifData.expiresAt) {
    const exp = toDate(notifData.expiresAt);
    if (exp && exp < now) return false;
  }
  return true;
}

function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v.toDate === 'function') return v.toDate();
  if (typeof v === 'string') {
    const d = new Date(v);
    return isNaN(d) ? null : d;
  }
  if (typeof v.seconds === 'number') return new Date(v.seconds * 1000);
  return null;
}

/**
 * Build an FCM `Message` for a social notification.
 *
 * Large-icon badge distinction (splash vs archetype) is handled by local
 * habit notifications on-device; all server-pushed social notifications use
 * the splash badge (blue circle + black flame) as the small status icon
 * (`push_notification_icon`) plus `notification_accent` color, which matches
 * the "general = splash, archetype = per-archetype color" spec.
 *
 * @param {Record<string,any>} notifData
 * @param {string} fcmToken
 * @returns {import("firebase-admin/messaging").Message}
 */
export function buildFcmMessage(notifData, fcmToken) {
  const title = notifData.title ?? 'Emerge';
  const body = notifData.body ?? '';
  const data = notifData.data ?? {};
  const route = data.route ?? (notifData.type === 'friendRequest' || notifData.type === 'friendRequestAccepted' ? '/social/accountability' : '/social');
  return {
    token: fcmToken,
    notification: { title, body },
    data: {
      type: String(notifData.type ?? 'system'),
      route: String(route),
      notificationId: String(notifData.id ?? ''),
    },
    android: {
      notification: {
        icon: SPLASH_ICON,
        color: SPLASH_COLOR,
        channelId: 'general',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: { aps: { sound: 'default' } },
    },
  };
}
