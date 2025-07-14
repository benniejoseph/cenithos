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

interface Transaction {
  id: string;
  userId: string;
  amount: number;
  date: admin.firestore.Timestamp | { _seconds: number; _nanoseconds: number } | string;
  description?: string;
  ref_id?: string;
  source?: string;
  createdAt?: admin.firestore.Timestamp;
}

const findDuplicateTransactions = async () => {
  console.log("Fetching all transactions from the database...");
  const transactionsSnapshot = await db.collection("transactions").get();
  const transactions: Transaction[] = transactionsSnapshot.docs.map(
    (doc) => ({ id: doc.id, ...doc.data() } as Transaction)
  );

  console.log(`Found ${transactions.length} total transactions. Analyzing for duplicates...`);

  const groups = new Map<string, Transaction[]>();

  for (const tx of transactions) {
    // Normalize date to a consistent string format (YYYY-MM-DD)
    let dateString: string;
    if (typeof tx.date === 'string') {
        dateString = tx.date.substring(0, 10);
    } else if (tx.date instanceof admin.firestore.Timestamp) {
        dateString = tx.date.toDate().toISOString().substring(0, 10);
    } else if (tx.date && typeof tx.date === 'object' && '_seconds' in tx.date) {
        dateString = new Date(tx.date._seconds * 1000).toISOString().substring(0, 10);
    } else {
        console.warn(`Skipping transaction ${tx.id} due to invalid date format.`);
        continue;
    }
    
    // Create a unique key to identify potential duplicates
    const key = `${tx.userId}-${dateString}-${tx.amount}-${(tx.description || tx.ref_id || "").trim()}`;

    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key)!.push(tx);
  }

  const duplicateIdsToDelete: string[] = [];
  let potentialDuplicateGroups = 0;

  console.log("\n--- Potential Duplicate Groups ---");
  for (const [key, group] of groups.entries()) {
    if (group.length > 1) {
      potentialDuplicateGroups++;
      // Sort by createdAt timestamp, newest first. Keep the newest one.
      group.sort((a, b) => {
        const timeA = a.createdAt?.toMillis() ?? 0;
        const timeB = b.createdAt?.toMillis() ?? 0;
        return timeB - timeA;
      });

      const transactionToKeep = group[0];
      const transactionsToDelete = group.slice(1);

      console.log(`\nGroup Key: ${key}`);
      console.log(`  Keeping: ${transactionToKeep.id} (Created at: ${transactionToKeep.createdAt?.toDate().toISOString()})`);
      transactionsToDelete.forEach(tx => {
        console.log(`  Marking for deletion: ${tx.id} (Created at: ${tx.createdAt?.toDate().toISOString()})`);
        duplicateIdsToDelete.push(tx.id);
      });
    }
  }

  if (potentialDuplicateGroups === 0) {
    console.log("\nNo duplicate transaction groups found.");
  } else {
    console.log(`\nFound ${potentialDuplicateGroups} groups with potential duplicates.`);
    console.log(`A total of ${duplicateIdsToDelete.length} transactions have been marked for deletion.`);
    console.log("\n--- IDs to Delete ---");
    console.log(JSON.stringify(duplicateIdsToDelete, null, 2));
    console.log("\nTo delete these transactions, run the delete-duplicates script with this list.");
  }

};

findDuplicateTransactions().catch(console.error); 