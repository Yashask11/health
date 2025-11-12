const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyDonorOnRequest = onDocumentCreated("requests/{requestId}", async (event) => {
  const requestData = event.data?.data();
  const donorId = requestData?.donorUid;
  const requestId = event.params.requestId;

  if (!donorId) {
    console.log("❌ No donorUid found in request");
    return;
  }

  const db = getFirestore();
  const donorSnap = await db.collection("users").doc(donorId).get();
  const donorData = donorSnap.data();
  const fcmToken = donorData?.fcmToken;

  const messageText = `You have a new donation request from ${requestData.receiverName || "a receiver"}`;

  // 🔹 Create Firestore notification (this powers your NotificationScreen)
  await db.collection("notifications").add({
    title: "New Donation Request",
    message: messageText,
    toUid: donorId,
    timestamp: FieldValue.serverTimestamp(),
    requestId: requestId,
  });

  // 🔹 Send FCM notification
  if (fcmToken) {
    try {
      const response = await getMessaging().sendToDevice(fcmToken, {
        notification: {
          title: "New Donation Request",
          body: messageText,
        },
      });
      console.log("✅ FCM notification sent:", response);
    } catch (error) {
      console.error("❌ Error sending FCM:", error);
    }
  } else {
    console.log("⚠ No FCM token found for donor:", donorId);
  }
});
