import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

// Initialize the Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  if (error instanceof Error && error.message.includes("already exists")) {
    // Already initialized
  } else {
    throw error;
  }
}

const db = getFirestore();

async function analyzeTransactionSchema() {
  logger.info("Starting transaction schema analysis...");
  const transactionsSnapshot = await db.collection("transactions").get();

  if (transactionsSnapshot.empty) {
    logger.warn("No transactions found.");
    return;
  }

  const fieldSets = new Set<string>();

  transactionsSnapshot.forEach((doc) => {
    const data = doc.data();
    const fields = Object.keys(data).sort().join(", ");
    fieldSets.add(fields);
  });

  logger.info("Found the following unique field combinations in your transactions:");
  fieldSets.forEach((fieldSet) => {
    console.log(`- [ ${fieldSet} ]`);
  });
  logger.info(`Analysis complete. Found ${fieldSets.size} unique schemas.`);
}

analyzeTransactionSchema().catch((error) => {
  logger.error("Error during schema analysis:", error);
}); 