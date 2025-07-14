import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import * as logger from "firebase-functions/logger";
import {Transaction} from "../models/transaction";

const transactionsCollection = () => getFirestore().collection("transactions");

export const getTransactions = async (
  userId: string,
  filters?: { category?: string; type?: string; startDate?: string; endDate?: string }
): Promise<Transaction[]> => {
  logger.info(`Fetching transactions for user ${userId} with filters:`, filters);
  let query: FirebaseFirestore.Query = transactionsCollection().where(
    "userId",
    "==",
    userId
  );

  if (filters) {
    if (filters.category) {
      query = query.where("category", "==", filters.category);
    }
    if (filters.type) {
      query = query.where("type", "==", filters.type);
    }
    if (filters.startDate) {
      query = query.where("date", ">=", filters.startDate);
    }
    if (filters.endDate) {
      query = query.where("date", "<=", filters.endDate);
    }
  }

  // Order by date after filtering
  query = query.orderBy("date", "desc");

  const snapshot = await query.get();

  if (snapshot.empty) {
    return [];
  }
  return snapshot.docs.map((doc) => {
        const data = doc.data();

        const toISOString = (field: any): string | null => {
            if (!field) return null;
            // If it has a toDate method, it's a Timestamp
            if (typeof field.toDate === 'function') {
                return field.toDate().toISOString();
            }
            // If it's a string, assume it's already in ISO format
            if (typeof field === 'string') {
                return field;
            }
            // Otherwise, it's an unknown format, return null
            return null;
        };

        return {
            id: doc.id,
            userId: data.userId,
            amount: data.amount ?? 0,
            currency: data.currency,
            merchant: data.merchant,
            vendor: data.vendor,
            bank: data.bank,
            date: toISOString(data.date),
            type: data.type ?? "expense",
            ref_id: data.ref_id,
            source: data.source ?? "manual",
            description: data.description ?? "",
            category: data.category ?? "Uncategorized",
            createdAt: toISOString(data.createdAt),
            updatedAt: toISOString(data.updatedAt),
        } as Transaction;
    });
};

export const createTransaction = async (
    userId: string,
    amount: number,
    description: string,
    date: string,
    type: "income" | "expense",
    category: string
): Promise<Transaction> => {
    logger.info(`Creating new transaction for user ${userId}`);
    const collectionRef = transactionsCollection();

    // De-duplication for manual entries
    const thirtySecondsAgo = Timestamp.fromMillis(Date.now() - 30000);
    const existingTxQuery = await collectionRef
        .where("userId", "==", userId)
        .where("amount", "==", amount)
        .where("description", "==", description)
        .where("createdAt", ">=", thirtySecondsAgo)
        .limit(1)
        .get();

    if (!existingTxQuery.empty) {
        const doc = existingTxQuery.docs[0];
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { id, ...existingTx } = doc.data() as Transaction;
        logger.warn("Duplicate manual transaction detected within 30 seconds. Returning existing.", {
            existingId: doc.id,
            userId,
        });
        return {
            ...existingTx,
            id: doc.id,
            description: existingTx.description ?? "",
            category: existingTx.category ?? "Uncategorized",
            createdAt: existingTx.createdAt ? (existingTx.createdAt as Timestamp).toDate().toISOString() : null,
            updatedAt: existingTx.updatedAt ? (existingTx.updatedAt as Timestamp).toDate().toISOString() : null,
        } as unknown as Transaction;
    }

    const docRef = collectionRef.doc();
    const newTransaction: Omit<Transaction, "id"> = {
        userId,
        amount,
        description,
        date,
        type,
        category,
        createdAt: FieldValue.serverTimestamp() as Timestamp,
        updatedAt: FieldValue.serverTimestamp() as Timestamp,
        source: "manual",
    };
    await docRef.set(newTransaction);

    const newDoc = await docRef.get();
    const newDocData = newDoc.data() as Transaction;

    return {
        ...newDocData,
        id: newDoc.id,
        description: newDocData.description ?? "",
        category: newDocData.category ?? "Uncategorized",
        createdAt: newDocData.createdAt ? (newDocData.createdAt as Timestamp).toDate().toISOString() : null,
        updatedAt: newDocData.updatedAt ? (newDocData.updatedAt as Timestamp).toDate().toISOString() : null,
    } as unknown as Transaction;
};

export const createImportedTransactions = async (
    userId: string,
    transactions: Omit<Transaction, "id" | "userId" | "createdAt" | "updatedAt">[]
): Promise<{ created: number; duplicates: number; errors: number }> => {
    logger.info(`Received ${transactions.length} transactions to import for user ${userId}`);
    const collectionRef = transactionsCollection();
    const report = { created: 0, duplicates: 0, errors: 0 };

    // 1. Fetch all existing ref_ids for the user in a single query.
    const refIdsToCheck = transactions.map((tx) => tx.ref_id).filter((id) => id);
    if (refIdsToCheck.length === 0) {
        logger.info("No transactions with ref_id to import.");
        report.errors = transactions.length;
        return report;
    }
    
    logger.info(`Checking for ${refIdsToCheck.length} potential new transactions.`);

    const existingTxQuery = await collectionRef
        .where("userId", "==", userId)
        .where("ref_id", "in", refIdsToCheck)
        .get();

    const existingRefIds = new Set(existingTxQuery.docs.map((doc) => doc.data().ref_id).filter(id => id));
    logger.info(`Found ${existingRefIds.size} existing ref_ids in the database.`);
    report.duplicates = existingRefIds.size;

    // 2. Filter out duplicates and prepare the batch write.
    const batch = getFirestore().batch();

    for (const tx of transactions) {
        if (!tx.ref_id) {
            logger.warn("Skipping imported transaction with no ref_id:", tx);
            report.errors++;
            continue;
        }

        if (!existingRefIds.has(tx.ref_id)) {
            const docRef = collectionRef.doc();
            const newTransaction: Omit<Transaction, "id"> = {
                ...tx,
                userId,
                createdAt: FieldValue.serverTimestamp() as Timestamp,
                updatedAt: FieldValue.serverTimestamp() as Timestamp,
                description: tx.description ?? tx.vendor ?? "Imported Transaction",
                category: tx.category ?? "Uncategorized",
                source: tx.source ?? "sms-ai",
            };
            batch.set(docRef, newTransaction);
            report.created++;
            // Add the new ref_id to our set to handle duplicates within the same batch
            existingRefIds.add(tx.ref_id);
        } else {
            logger.info(`Skipping duplicate transaction with ref_id: ${tx.ref_id}`);
        }
    }

    // Adjust duplicate count based on initial check vs what's in the batch
    report.duplicates = transactions.length - report.created - report.errors;

    if (report.created > 0) {
        try {
            await batch.commit();
            logger.info(`Successfully committed batch with ${report.created} new transactions.`);
        } catch (error) {
            logger.error("Error committing batch:", error);
            // If the batch fails, all attempted creations are now errors
            report.errors += report.created;
            report.created = 0;
        }
    } else {
        logger.info("No new transactions to import.");
    }

    logger.info(`Import report for user ${userId}: ${JSON.stringify(report)}`);
    return report;
};

export const handleCategoryFeedback = async (
    userId: string,
    transactionId: string,
    description: string,
    oldCategory: string,
    newCategory: string
): Promise<void> => {
    logger.info(`Storing category feedback for user ${userId} on transaction ${transactionId}`);
    try {
        const feedback = {
            userId,
            transactionId,
            description,
            oldCategory,
            newCategory,
            createdAt: FieldValue.serverTimestamp(),
        };
        await getFirestore().collection("ai_category_corrections").add(feedback);
        logger.info(`Successfully stored category feedback for user ${userId}.`);
    } catch (error) {
        logger.error(`Failed to store category feedback for user ${userId}:`, error);
        throw new Error("Failed to save feedback.");
    }
};

export const updateTransaction = async (
    transactionId: string,
    updates: Partial<Transaction>
): Promise<Transaction> => {
    logger.info(`Updating transaction ${transactionId}`);
    const docRef = transactionsCollection().doc(transactionId);

    // Create a mutable copy of updates to modify the date field
    const finalUpdates: { [key: string]: any } = { ...updates };

    // If date is a string, convert it to a Date object for Firestore
    if (finalUpdates.date && typeof finalUpdates.date === 'string') {
        finalUpdates.date = new Date(finalUpdates.date);
    }
    
    // Ensure `updatedAt` is always set
    finalUpdates.updatedAt = FieldValue.serverTimestamp();

    await docRef.update(finalUpdates);

    const updatedDoc = await docRef.get();
    if (!updatedDoc.exists) {
        throw new Error("Transaction not found after update.");
    }

    const updatedData = updatedDoc.data() as Transaction;

    const toISOString = (field: any): string | null => {
        if (!field) return null;
        if (typeof field.toDate === 'function') {
            return field.toDate().toISOString();
        }
        if (typeof field === 'string') {
            return field;
        }
        return null;
    };

    return {
        ...updatedData,
        id: updatedDoc.id,
        // Handle potential Timestamps
        date: toISOString(updatedData.date),
        createdAt: toISOString(updatedData.createdAt),
        updatedAt: toISOString(updatedData.updatedAt),
    } as unknown as Transaction;
};

export const deleteTransaction = async (transactionId: string): Promise<void> => {
    logger.info(`Deleting transaction ${transactionId}`);
    const docRef = transactionsCollection().doc(transactionId);
    await docRef.delete();
}; 