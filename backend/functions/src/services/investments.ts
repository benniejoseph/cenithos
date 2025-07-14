import * as admin from 'firebase-admin';
import { Investment } from '../models/investment';

const db = admin.firestore();
const investmentsCollection = db.collection('investments');

type InvestmentData = Omit<Investment, 'id'>;

export const createInvestment = async (userId: string, data: Partial<Investment>): Promise<Investment> => {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...investmentData } = data;
    const investmentRef = investmentsCollection.doc();
    const newInvestmentData: InvestmentData = {
        name: investmentData.name!,
        type: investmentData.type!,
        currentValue: investmentData.currentValue!,
        investedAmount: investmentData.investedAmount!,
        quantity: investmentData.quantity,
        userId,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
        createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    };
    await investmentRef.set(newInvestmentData);
    const doc = await investmentRef.get();
    const docData = doc.data() as InvestmentData;
    return { id: doc.id, ...docData };
};

export const getInvestments = async (userId: string): Promise<Investment[]> => {
    const snapshot = await investmentsCollection.where('userId', '==', userId).get();
    return snapshot.docs.map(doc => {
        const data = doc.data() as InvestmentData;
        return { id: doc.id, ...data };
    });
};

export const getInvestmentById = async (investmentId: string, userId: string): Promise<Investment | null> => {
    const doc = await investmentsCollection.doc(investmentId).get();
    if (!doc.exists) {
        return null;
    }
    const investmentData = doc.data() as InvestmentData;
    if (investmentData.userId !== userId) {
        return null;
    }
    return { id: doc.id, ...investmentData };
};

export const updateInvestment = async (investmentId: string, userId: string, data: Partial<Investment>): Promise<Investment | null> => {
    const investmentRef = investmentsCollection.doc(investmentId);
    const doc = await investmentRef.get();

    if (!doc.exists || (doc.data() as InvestmentData).userId !== userId) {
        return null;
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...updateData } = data;

    const finalUpdateData = {
        ...updateData,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await investmentRef.update(finalUpdateData);
    const updatedDoc = await investmentRef.get();
    const updatedData = updatedDoc.data() as InvestmentData;
    return { id: updatedDoc.id, ...updatedData };
};

export const deleteInvestment = async (investmentId: string, userId: string): Promise<boolean> => {
    const investmentRef = investmentsCollection.doc(investmentId);
    const doc = await investmentRef.get();

    if (!doc.exists || (doc.data() as InvestmentData).userId !== userId) {
        return false;
    }

    await investmentRef.delete();
    return true;
}; 