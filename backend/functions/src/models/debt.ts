export interface Debt {
  id: string;
  userId: string;
  name: string;
  type: 'loan' | 'credit_card' | 'mortgage' | 'other';
  balance: number;
  interestRate: number;
  minimumPayment: number;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
} 