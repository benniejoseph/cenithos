export interface Investment {
  id: string;
  userId: string;
  name: string;
  type: 'stock' | 'bond' | 'mutual_fund' | 'etf' | 'crypto' | 'other';
  currentValue: number;
  quantity?: number;
  investedAmount: number;
  lastUpdated: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
} 