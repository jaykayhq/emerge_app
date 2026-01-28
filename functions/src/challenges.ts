import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

// Initialize admin if not already done (handled in index.ts usually, but good to be safe or use shared instance)
// We will assume admin is initialized in index.ts, but inside functions we need access to it.
// Best practice: pass app or get specific instance. Here we'll just use admin.

const getDb = () => admin.firestore();

/**
 * Trigger: When a new challenge request is created.
 * Action: Send a push notification to the recipient (e.g., "Mike challenged you!").
 */
export const onChallengeRequestCreated = functions.firestore
  .document('challenge_requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    const request = snapshot.data();
    if (!request) return null;

    const { senderId, senderName, recipientId, challengeName, message } = request;

    console.log(`New challenge request from ${senderId} to ${recipientId}`);

    try {
      // 1. Get Recipient's FCM Token
      // Assuming tokens are stored in `users/{userId}/fcm_tokens/{tokenId}` or just a field in user profile.
      // Adjust this path based on actual DB schema.
      const tokensSnapshot = await getDb()
        .collection('users')
        .doc(recipientId)
        .collection('fcm_tokens')
        .get();

      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

      if (tokens.length === 0) {
        console.log(`No tokens found for user ${recipientId}`);
        return null;
      }

      // 2. Construct Notification
      // Fix: Ensure challengeName is used to strict TS check and provide better context
      const bodyText = message
        ? `${senderName}: "${message}"`
        : `${senderName} challenged you to: ${challengeName}`;

      // 3. Send via FCM (Multicast)
      // Fix: sendToDevice is deprecated/removed. Use sendEachForMulticast.
      const messagePayload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title: '🔥 New Challenge!',
          body: bodyText,
        },
        data: {
          type: 'challenge_request',
          requestId: context.params.requestId,
          senderId: senderId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK', // Legacy support
        },
        android: {
          notification: {
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        },
        apns: {
          payload: {
            aps: {
              category: 'FLUTTER_NOTIFICATION_CLICK',
            }
          }
        }
      };

      await admin.messaging().sendEachForMulticast(messagePayload);
      console.log(`Notification sent to ${recipientId}`);

    } catch (error) {
      console.error('Error sending challenge notification:', error);
    }

    return null;
  });

/**
 * Trigger: When a challenge request is updated (Accepted/Declined).
 * Action: Notify the original sender.
 */
export const onChallengeRequestUpdated = functions.firestore
  .document('challenge_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    if (!newData || !oldData) return null;

    // Only trigger on status change
    if (newData.status === oldData.status) return null;

    const { senderId, recipientName, challengeName, status } = newData;

    console.log(`Challenge request ${context.params.requestId} updated to ${status}`);

    try {
      // 1. Get Sender's FCM Token
      const tokensSnapshot = await getDb()
        .collection('users')
        .doc(senderId)
        .collection('fcm_tokens')
        .get();

      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

      if (tokens.length === 0) return null;

      // 2. Notification Content
      let title = '';
      let body = '';

      if (status === 'accepted') {
        title = 'Challenge Accepted! ⚔️';
        body = `${recipientName} accepted "${challengeName}". Game on!`;
      } else if (status === 'declined') {
        title = 'Challenge Declined 😢';
        body = `${recipientName} declined "${challengeName}".`;
      } else {
        return null;
      }

      const messagePayload: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: {
          title,
          body,
        },
        data: {
          type: 'challenge_update',
          requestId: context.params.requestId,
          status: status,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          }
        },
      };

      await admin.messaging().sendEachForMulticast(messagePayload);

      // 3. If Accepted, we might want to ensure an 'active_challenge' document exists.
      if (status === 'accepted') {
        await createActiveChallenge(newData, context.params.requestId);
      }

    } catch (error) {
      console.error('Error handling challenge update:', error);
    }

    return null;
  });

async function createActiveChallenge(requestData: any, requestId: string) {
  // Create a document in 'challenges' collection
  try {
    await getDb().collection('challenges').add({
      title: requestData.challengeName,
      type: 'hybrid_1vs1',
      participants: [requestData.senderId, requestData.recipientId],
      status: 'active',
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      endDate: admin.firestore.FieldValue.serverTimestamp(), // TODO: Calculate based on duration
      wager: requestData.wager,
      sourceRequestId: requestId,
      metadata: {
        senderName: requestData.senderName,
        recipientName: requestData.recipientName
      }
    });
    console.log('Active challenge created automatically.');
  } catch (e) {
    console.error('Failed to create active challenge:', e);
  }
}
