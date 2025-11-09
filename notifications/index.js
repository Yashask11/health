const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Trigger when a new request document is created in Firestore
exports.notifyDonorOnRequest = onDocumentCreated("requests/{requestId}", async (event) => {
  const requestData = event.data.data();
  const requestId = event.params.requestId;

  const donorId = requestData.donorId;
  if (!donorId) {
    console.log("No donorId in request.");
    return null;
  }

  const db = getFirestore();

  // ✅ Get donor details
  const donorDoc = await db.collection("users").doc(donorId).get();
  const donorData = donorDoc.data();
  const fcmToken = donorData?.fcmToken;

  if (!fcmToken) {
    console.log("⚠ No FCM token found for donor:", donorId);
  }

  // Create notification message
  const messageText = ${requestData.receiverName} requested your donation: ${requestData.itemName};

  // ✅ Store the notification in Firestore (UPDATED)
  try {
    await db.collection("notifications").add({
      title: "New Donation Request",                         // ✅ Added title
      message: messageText,                                   // Already correct
      timestamp: FieldValue.serverTimestamp(),               // Already correct
      donorUid: donorId,                                      // Already correct
      receiverUid: requestData.receiverUid ?? "",            // ✅ Added receiverUid
      requestId: requestId                                    // Already correct
    });

    console.log("✅ Notification stored for donor:", donorId);
  } catch (err) {
    console.error("❌ Error storing notification:", err);
  }

  // ✅ Send push notification
  if (fcmToken) {
    const payload = {
      notification: {
        title: "New Donation Request",   // ✅ Updated title to match Firestore
        body: messageText,
      },
      data: {
        donorId: donorId,
        requestId: requestId,
      },
    };

    try {
      await getMessaging().sendToDevice(fcmToken, payload);
      console.log("📩 Push notification sent to donor:", donorId);
    } catch (error) {
      console.error("❌ Error sending FCM notification:", error);
    }
  }

  return null;
});