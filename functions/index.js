const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const vision = require("@google-cloud/vision");

admin.initializeApp();
const db = admin.firestore();
const client = new vision.ImageAnnotatorClient();

exports.verifyDonationImage = onObjectFinalized(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (event) => {
    try {
      const bucket = event.data.bucket;
      const filePath = event.data.name;
      const fileUri = `gs://${bucket}/${filePath}`;

      logger.info(`🖼️ Image uploaded: ${fileUri}`);

      // Vision API label detection
      const [result] = await client.labelDetection(fileUri);
      const labels = result.labelAnnotations.map((l) => l.description.toLowerCase());
      logger.info("Labels detected:", labels);

      // Check valid donation types
      const validItems = ["medicine", "tablet", "strip", "wheelchair", "mobility aid"];
      const isValid = labels.some((label) => validItems.includes(label));

      // ✅ Use safe Firestore doc ID
      const safeId = filePath.replace(/\//g, "_");

      await db.collection("uploads").doc(safeId).set({
        filePath,
        verified: isValid,
        labels,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`✅ Verification result for ${filePath}: ${isValid}`);
    } catch (error) {
      logger.error("❌ Error verifying image:", error.message, error.stack);
    }
  }
);
