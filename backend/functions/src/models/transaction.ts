export interface Transaction {
  id: string;
  userId: string;
  amount: number;
  type: "income" | "expense";
  date: any; // Can be a string or a Firestore Timestamp
  createdAt?: any;
  updatedAt?: any;

  // Manual Entry Fields
  description?: string;
  category?: string;

  // Imported Fields
  vendor?: string;
  bank?: string;
  currency?: string;
  merchant?: string;
  ref_id?: string;
  source?: string;
}

// NEW: Predefined categories type for validation
export type TransactionCategory = 
  | 'Income'
  | 'Groceries'
  | 'Transport'
  | 'Bills'
  | 'Entertainment'
  | 'Shopping'
  | 'Other';

// NEW: Filter parameters interface
export interface TransactionFilters {
  category?: string;
  startDate?: Date;
  endDate?: Date;
} 