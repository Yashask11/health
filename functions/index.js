/**
 * Firebase Cloud Functions Entry Point
 *
 * This version includes a working test function to verify deployment.
 */

const {setGlobalOptions} = require("firebase-functions/v2/options");
const {onRequest} = require("firebase-functions/v2/https");

// Optional: limit concurrent instances for cost control
setGlobalOptions({maxInstances: 10});

// ✅ A simple test function you can open in your browser after deployment
exports.helloWorld = onRequest((request, response) => {
  response.send("✅ Hello from Firebase Cloud Functions!");
});
