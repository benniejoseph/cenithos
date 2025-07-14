import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { Budget } from "../models/budget";
import { BudgetDTO } from "../models/budget.dto";
import * as logger from "firebase-functions/logger";

const db = getFirestore();
const budgetsCollection = () => db.collection("budgets");

// Helper to convert budget data for client
const toClientObject = (id: string, data: Budget): BudgetDTO => {
    const now = new Date().toISOString();

    const getDateString = (date: Date | Timestamp | undefined | null): string => {
        if (date && typeof (date as any).toDate === 'function') {
            return (date as Timestamp).toDate().toISOString();
        }
        if (date instanceof Date) {
            return date.toISOString();
        }
        // Fallback for null, undefined, or other malformed data
        return now;
    };

    return {
        id,
        userId: data.userId,
        category: data.category ?? "Uncategorized",
        budgetedAmount: data.budgetedAmount ?? 0,
        spentAmount: data.spentAmount ?? 0,
        startDate: getDateString(data.startDate),
        endDate: getDateString(data.endDate),
        createdAt: getDateString(data.createdAt),
        updatedAt: getDateString(data.updatedAt),
    };
};


export const createBudget = async (userId: string, budgetData: Omit<Budget, "id" | "userId" | "spentAmount" | "createdAt" | "updatedAt">): Promise<BudgetDTO> => {
    logger.info(`Creating budget for user ${userId}`, { budgetData });
    const budgetRef = budgetsCollection().doc();
    const now = new Date();
    const newBudget: Omit<Budget, "id"> = {
        ...budgetData,
        userId,
        spentAmount: 0,
        createdAt: Timestamp.fromDate(now),
        updatedAt: Timestamp.fromDate(now),
    };
    await budgetRef.set(newBudget);

    // Don't re-fetch, build DTO directly to avoid race condition with serverTimestamp
    return toClientObject(budgetRef.id, newBudget as Budget);
};

export const getBudgets = async (userId: string): Promise<BudgetDTO[]> => {
    logger.info(`Fetching budgets for user ${userId}`);
    const snapshot = await budgetsCollection().where("userId", "==", userId).get();
    if (snapshot.empty) {
        return [];
    }
    return snapshot.docs.map(doc => toClientObject(doc.id, doc.data() as Budget));
};

export const getBudgetById = async (userId: string, budgetId: string): Promise<BudgetDTO | null> => {
    logger.info(`Fetching budget ${budgetId} for user ${userId}`);
    const doc = await budgetsCollection().doc(budgetId).get();
    if (!doc.exists || doc.data()?.userId !== userId) {
        return null;
    }
    const data = doc.data() as Budget;
    return toClientObject(doc.id, data);
};

export const updateBudget = async (userId: string, budgetId: string, updates: Partial<Budget>): Promise<BudgetDTO | null> => {
    logger.info(`Updating budget ${budgetId} for user ${userId}`, { updates });
    const budgetRef = budgetsCollection().doc(budgetId);

    const doc = await budgetRef.get();
    if (!doc.exists || doc.data()?.userId !== userId) {
        logger.warn(`User ${userId} attempted to access unauthorized budget ${budgetId}`);
        return null;
    }

    const now = new Date();
    const updatePayload = {
        ...updates,
        updatedAt: Timestamp.fromDate(now),
    };
    await budgetRef.update(updatePayload);

    // Don't re-fetch, build DTO directly by merging old and new data
    const existingData = doc.data() as Budget;
    const updatedData = { ...existingData, ...updatePayload };

    return toClientObject(budgetId, updatedData as Budget);
};

export const deleteBudget = async (userId: string, budgetId: string): Promise<boolean> => {
    logger.info(`Deleting budget ${budgetId} for user ${userId}`);
    const budgetRef = budgetsCollection().doc(budgetId);

    const doc = await budgetRef.get();
    if (!doc.exists || doc.data()?.userId !== userId) {
        logger.warn(`User ${userId} attempted to access unauthorized budget ${budgetId}`);
        return false;
    }

    await budgetRef.delete();
    return true;
}; 