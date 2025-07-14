import * as admin from 'firebase-admin';
import { Debt } from '../models/debt';

const db = admin.firestore();
const debtsCollection = db.collection('debts');

type DebtData = Omit<Debt, 'id'>;


export const createDebt = async (userId: string, data: Partial<Debt>): Promise<Debt> => {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...debtData } = data;
    const debtRef = debtsCollection.doc();
    const newDebtData: DebtData = {
        name: debtData.name!,
        type: debtData.type!,
        balance: debtData.balance!,
        interestRate: debtData.interestRate!,
        minimumPayment: debtData.minimumPayment!,
        userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    };
    await debtRef.set(newDebtData);
    const doc = await debtRef.get();
    const docData = doc.data() as DebtData;
    return { id: doc.id, ...docData };
};

export const getDebts = async (userId: string): Promise<Debt[]> => {
    const snapshot = await debtsCollection.where('userId', '==', userId).get();
    return snapshot.docs.map(doc => {
        const data = doc.data() as DebtData;
        return { id: doc.id, ...data };
    });
};

export const getDebtById = async (debtId: string, userId: string): Promise<Debt | null> => {
    const doc = await debtsCollection.doc(debtId).get();
    if (!doc.exists) {
        return null;
    }
    const debtData = doc.data() as DebtData;
    if (debtData.userId !== userId) {
        return null;
    }
    return { id: doc.id, ...debtData };
};

export const updateDebt = async (debtId: string, userId: string, data: Partial<Debt>): Promise<Debt | null> => {
    const debtRef = debtsCollection.doc(debtId);
    const doc = await debtRef.get();

    if (!doc.exists || (doc.data() as DebtData).userId !== userId) {
        return null;
    }
    
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, ...updateData } = data;

    const finalUpdateData = {
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await debtRef.update(finalUpdateData);
    const updatedDoc = await debtRef.get();
    const updatedData = updatedDoc.data() as DebtData;
    return { id: updatedDoc.id, ...updatedData };
};


export const deleteDebt = async (debtId: string, userId: string): Promise<boolean> => {
    const debtRef = debtsCollection.doc(debtId);
    const doc = await debtRef.get();

    if (!doc.exists || (doc.data() as DebtData).userId !== userId) {
        return false;
    }

    await debtRef.delete();
    return true;
}; 