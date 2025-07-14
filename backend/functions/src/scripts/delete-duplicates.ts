import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

// Initialize the Firebase Admin SDK
// IMPORTANT: Make sure your GOOGLE_APPLICATION_CREDENTIALS environment variable
// is set correctly to point to your service account key file.
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  if (error instanceof Error && error.message.includes("already exists")) {
    // This is fine, means we're probably in an environment where it's already initialized.
  } else {
    throw error;
  }
}

const db = getFirestore();

// The list of duplicate transaction IDs identified by the find-duplicates.ts script.
const idsToDelete: string[] = [
  "bFheWvk4SnJCuS2XXWSL",
  "3TmySkzXDc1Q64rEpmRe",
  "zpqhWkkxlKgwW7J4XPpt",
  "91H33ZB0nh4qx0HhcCsb",
  "4uplcVBiTLIBvET5PlGA",
  "6LrP0dAh1Zx6G9w94785",
  "7dDiu4fw6sGDOrRgdKr9",
  "APtVwrddBQS69OcxKqAK",
  "AbPgarhUr85mYrWBmTnN",
  "Mt6lSqxmVqglt0pdx9Dq",
  "g3CS1a6hD0mY3CRbVNDS",
  "gK02EONwdM6flVuG7t28"
];


const deleteTransactions = async () => {
  if (idsToDelete.length === 0) {
    console.log("No transaction IDs provided for deletion.");
    return;
  }

  console.log(`Starting deletion of ${idsToDelete.length} transactions...`);

  const batch = db.batch();
  const transactionsCollection = db.collection("transactions");

  idsToDelete.forEach(id => {
    const docRef = transactionsCollection.doc(id);
    batch.delete(docRef);
  });

  try {
    await batch.commit();
    console.log("Successfully deleted all specified transactions.");
    console.log("The database has been cleaned.");
  } catch (error) {
    console.error("Error committing batch deletion:", error);
    console.error("Some transactions may not have been deleted.");
  }
};

deleteTransactions().catch(console.error); 