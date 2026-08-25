const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const CHANNEL_ID = "ability_link_alerts";

/**
 * When NotificationService.notify() writes a document with `push` in
 * `channels`, fan it out to every FCM token stored under the recipient.
 * Invalid tokens are deleted so a replaced device does not keep failing.
 */
exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{id}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const channels = Array.isArray(data.channels) ? data.channels : [];
    if (!channels.includes("push")) return;

    const uid = typeof data.uid === "string" ? data.uid : "";
    if (!uid) return;

    const tokensSnap = await getFirestore()
      .collection("users")
      .doc(uid)
      .collection("fcmTokens")
      .get();

    const entries = tokensSnap.docs
      .map((doc) => ({ id: doc.id, token: doc.data().token }))
      .filter((e) => typeof e.token === "string" && e.token.length > 0);
    if (entries.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens: entries.map((e) => e.token),
      notification: {
        title: String(data.title || "Ability Link"),
        body: String(data.body || ""),
      },
      data: {
        type: String(data.type || ""),
        relatedId: String(data.relatedId || ""),
        notificationId: event.params.id,
      },
      android: {
        notification: { channelId: CHANNEL_ID },
      },
      apns: {
        payload: { aps: { sound: "default" } },
      },
    });

    const stale = [];
    response.responses.forEach((res, i) => {
      if (res.success) return;
      const code = res.error?.code || "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        stale.push(entries[i].id);
      }
    });
    await Promise.all(
      stale.map((id) =>
        getFirestore()
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .doc(id)
          .delete(),
      ),
    );
  },
);
