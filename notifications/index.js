const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notifyDonorOnRequest = onDocumentCreated("requests/{requestId}", async (event) => {
  console.log("Trigger fired for requests collection", { params: event.params });
  const requestData = event.data?.data();
  const requestId = event.params.requestId;

  console.log("Request data:", requestData);

  if (!requestData) {
    console.error("No request data available. Exiting.");
    return null;
  }

  // MATCH the field name your Flutter app writes:
  const donorId = requestData.donorUid; // <-- changed from donorId

  if (!donorId) {
    console.log("❌ No donorUid in request.");
    return null;
  }

  const db = getFirestore();
  const donorDoc = await db.collection("users").doc(donorId).get();
  const donorData = donorDoc.data();
  const fcmToken = donorData?.fcmToken;

  const messageText = `${requestData.receiverName} requested your donation: ${requestData.itemName}`;

  await db.collection("notifications").add({
    title: "New Donation Request",
    message: messageText,
    timestamp: FieldValue.serverTimestamp(),
    donorUid: donorId,
    receiverUid: requestData.receiverUid ?? "",
    requestId: requestId,
  });

  console.log("✅ Notification stored for donor:", donorId);

  if (fcmToken) {
    const payload = {
      notification: {
        title: "New Donation Request",
        body: messageText,
      },
      data: { donorId, requestId },
    };

    try {
      const res = await getMessaging().sendToDevice(fcmToken, payload);
      console.log("📩 Push result:", res);
    } catch (error) {
      console.error("❌ Error sending FCM notification:", error);
    }
  } else {
    console.warn("⚠ No FCM token found for donor:", donorId);
  }

  return null;
});
