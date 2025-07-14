import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { Goal } from '../models/goal';
import * as logger from "firebase-functions/logger";


const db = getFirestore();
const goalsCollection = db.collection('goals');

type GoalData = Omit<Goal, 'id'>;

export const createGoal = async (userId: string, data: Partial<Goal>): Promise<Goal> => {
    logger.info(`Creating goal for user ${userId}`, {data});
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...goalData } = data;
    const goalRef = goalsCollection.doc();
    const newGoalData: Omit<Goal, "id"> = {
        name: goalData.name!,
        targetAmount: goalData.targetAmount!,
        currentAmount: 0,
        targetDate: Timestamp.fromDate(new Date(goalData.targetDate as unknown as string)),
        userId,
        createdAt: FieldValue.serverTimestamp() as Timestamp,
        updatedAt: FieldValue.serverTimestamp() as Timestamp,
    };
    await goalRef.set(newGoalData);
    const doc = await goalRef.get();
    const docData = doc.data() as Goal;
    return {
        ...docData,
        id: doc.id,
        currentAmount: docData.currentAmount ?? 0,
        targetDate: (docData.targetDate as unknown as Timestamp).toDate().toISOString(),
        createdAt: (docData.createdAt as unknown as Timestamp).toDate().toISOString(),
        updatedAt: (docData.updatedAt as unknown as Timestamp).toDate().toISOString(),
    } as unknown as Goal;
};

export const getGoals = async (userId: string): Promise<Goal[]> => {
    logger.info(`Fetching goals for user ${userId}`);
    const snapshot = await goalsCollection.where('userId', '==', userId).get();
    return snapshot.docs.map(doc => {
        const data = doc.data() as Goal;
        return { 
            ...data,
            id: doc.id,
            currentAmount: data.currentAmount ?? 0,
            targetDate: (data.targetDate as unknown as Timestamp).toDate().toISOString(),
            createdAt: (data.createdAt as unknown as Timestamp).toDate().toISOString(),
            updatedAt: (data.updatedAt as unknown as Timestamp).toDate().toISOString(),
        } as unknown as Goal;
    });
};

export const getGoalById = async (goalId: string, userId: string): Promise<Goal | null> => {
    logger.info(`Fetching goal by id ${goalId} for user ${userId}`);
    const doc = await goalsCollection.doc(goalId).get();
    if (!doc.exists) {
        return null;
    }
    const goalData = doc.data() as Goal;
    if (goalData.userId !== userId) {
        return null;
    }
    return {
        ...goalData,
        id: doc.id,
        currentAmount: goalData.currentAmount ?? 0,
        targetDate: (goalData.targetDate as unknown as Timestamp).toDate().toISOString(),
        createdAt: (goalData.createdAt as unknown as Timestamp).toDate().toISOString(),
        updatedAt: (goalData.updatedAt as unknown as Timestamp).toDate().toISOString(),
    } as unknown as Goal;
};

export const updateGoal = async (goalId: string, userId: string, data: Partial<Goal>): Promise<Goal | null> => {
    logger.info(`Updating goal ${goalId} for user ${userId}`, {data});
    const goalRef = goalsCollection.doc(goalId);
    const doc = await goalRef.get();

    if (!doc.exists || (doc.data() as GoalData).userId !== userId) {
        return null;
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...updateData } = data;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const finalUpdateData: {[key: string]: any} = {
        ...updateData,
        updatedAt: FieldValue.serverTimestamp(),
    };

    if (updateData.targetDate) {
        finalUpdateData.targetDate = Timestamp.fromDate(new Date(updateData.targetDate as unknown as string));
    }

    await goalRef.update(finalUpdateData);
    const updatedDoc = await goalRef.get();
    const updatedData = updatedDoc.data() as Goal;
    return {
        ...updatedData,
        id: updatedDoc.id,
        currentAmount: updatedData.currentAmount ?? 0,
        targetDate: (updatedData.targetDate as unknown as Timestamp).toDate().toISOString(),
        createdAt: (updatedData.createdAt as unknown as Timestamp).toDate().toISOString(),
        updatedAt: (updatedData.updatedAt as unknown as Timestamp).toDate().toISOString(),
    } as unknown as Goal;
};

export const deleteGoal = async (goalId: string, userId: string): Promise<boolean> => {
    logger.info(`Deleting goal ${goalId} for user ${userId}`);
    const goalRef = goalsCollection.doc(goalId);
    const doc = await goalRef.get();

    if (!doc.exists || (doc.data() as GoalData).userId !== userId) {
        return false;
    }

    await goalRef.delete();
    return true;
}; 