import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { shouldPush, buildFcmMessage } from '../push.js';

describe('shouldPush', () => {
  const notif = { title: 't', body: 'b', type: 'friendRequest', read: false };
  it('requires communityUpdates', () => {
    assert.equal(shouldPush(notif, { settings: { notificationsEnabled: true, communityUpdates: false } }), false);
    assert.equal(shouldPush(notif, { settings: { notificationsEnabled: true, communityUpdates: true } }), true);
  });
  it('master off blocks all', () => {
    assert.equal(shouldPush(notif, { settings: { notificationsEnabled: false, communityUpdates: true } }), false);
  });
  it('DND does not suppress server pushes (client-enforced)', () => {
    const user = { settings: { notificationsEnabled: true, communityUpdates: true, doNotDisturb: true } };
    assert.equal(shouldPush(notif, user, new Date('2026-01-01T23:00:00')), true);
    assert.equal(shouldPush(notif, user, new Date('2026-01-01T12:00:00')), true);
  });
  it('read notifications are not pushed', () => {
    assert.equal(shouldPush({ ...notif, read: true }, { settings: { notificationsEnabled: true, communityUpdates: true } }), false);
  });
});

describe('buildFcmMessage', () => {
  it('routes friend requests to /social/accountability', () => {
    const m = buildFcmMessage({ title: 't', body: 'b', type: 'friendRequest', data: { route: '/social/accountability' } }, 'tok');
    assert.equal(m.data.route, '/social/accountability');
    assert.equal(m.android.notification.icon, 'push_notification_icon');
    assert.equal(m.android.notification.color, '#4850AE');
  });
});
