import { firestore } from "firebase-admin";

export interface Budget {
  id: string;
  userId: string;
  category: string;
  budgetedAmount: number;
  spentAmount: number;
  startDate: Date | firestore.Timestamp;
  endDate: Date | firestore.Timestamp;
  createdAt: firestore.Timestamp;
  updatedAt: firestore.Timestamp;
} 