import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

admin.initializeApp();

type NotificationDoc = {
  userId?: string;
  title?: string;
  body?: string;
  targetRoute?: string;
  type?: string;
  metadata?: Record<string, unknown>;
};

type DeviceDoc = {
  userId?: string;
  token?: string;
};

const db = admin.firestore();

export const sendNotificationPush = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const data = event.data?.data() as NotificationDoc | undefined;
    if (!data?.userId || !data.title || !data.body) return;

    await sendPushToUser(
      data.userId,
      data.title,
      data.body,
      data.targetRoute,
      data.type,
      data.metadata,
    );
  }
);

async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  targetRoute?: string,
  type?: string,
  metadata?: Record<string, unknown>,
) {
  const snapshot = await db.collection('user_devices').where('userId', '==', userId).get();
  if (snapshot.empty) return;

  const tokens = snapshot.docs
    .map((doc) => doc.data() as DeviceDoc)
    .map((doc) => doc.token)
    .filter((token): token is string => Boolean(token));

  if (tokens.length === 0) return;

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: {
      userId,
      targetRoute: targetRoute ?? '',
      type: type ?? '',
    },
  });
}
