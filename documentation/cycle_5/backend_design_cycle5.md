# Backend Technical Design - Cycle 5

**Date:** 2025-07-02
**Author:** L2A1 (Backend Architect)
**Based on:** `development_plan_cycle5.md`

---

## 1. Overview

This document specifies the backend changes required to support transaction categorization and filtering capabilities.

---

## 2. Data Model Changes

### 2.1. Transaction Interface Update

**File:** `backend/functions/src/models/transaction.ts`

```typescript
export interface Transaction {
  id: string;
  userId: string;
  description: string;
  amount: number;
  type: 'income' | 'expense';
  category: string; // NEW: Category field
  date: Date;
  createdAt: Date;
  updatedAt: Date;
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
```

---

## 3. Service Layer Changes

### 3.1. Transaction Service Updates

**File:** `backend/functions/src/services/transactions.ts`

```typescript
import * as admin from 'firebase-admin';
import { Transaction, TransactionFilters } from '../models/transaction';

const db = admin.firestore();
const transactionsCollection = db.collection('transactions');

export const createTransaction = async (
  userId: string,
  data: Omit<Transaction, 'id' | 'userId' | 'createdAt' | 'updatedAt'>
): Promise<Transaction> => {
  const newTransactionRef = transactionsCollection.doc();
  const now = new Date();
  const newTransaction: Transaction = {
    id: newTransactionRef.id,
    userId,
    ...data,
    category: data.category || 'Other', // Default category
    date: new Date(data.date),
    createdAt: now,
    updatedAt: now,
  };
  await newTransactionRef.set(newTransaction);
  return newTransaction;
};

export const listTransactions = async (
  userId: string,
  filters?: TransactionFilters
): Promise<Transaction[]> => {
  let query = transactionsCollection
    .where('userId', '==', userId) as admin.firestore.Query;

  // Apply category filter
  if (filters?.category) {
    query = query.where('category', '==', filters.category);
  }

  // Apply date range filters
  if (filters?.startDate) {
    query = query.where('date', '>=', filters.startDate);
  }
  if (filters?.endDate) {
    query = query.where('date', '<=', filters.endDate);
  }

  // Order by date (most recent first)
  query = query.orderBy('date', 'desc');

  const snapshot = await query.get();

  if (snapshot.empty) {
    return [];
  }

  return snapshot.docs.map((doc) => doc.data() as Transaction);
};
```

---

## 4. API Layer Changes

### 4.1. Route Handler Updates

**File:** `backend/functions/src/index.ts`

```typescript
// Update the existing transactions routes

// POST /v1/transactions (Enhanced to handle category)
v1.post("/transactions", async (req, res) => {
  try {
    const newTransaction = await transactionsService.createTransaction(
      req.user!.uid, 
      req.body
    );
    res.status(201).send(newTransaction);
  } catch (error) {
    res.status(400).send({ error: 'Failed to create transaction' });
  }
});

// GET /v1/transactions (Enhanced with filtering)
v1.get("/transactions", async (req, res) => {
  try {
    const filters: any = {};
    
    // Parse query parameters
    if (req.query.category) {
      filters.category = req.query.category as string;
    }
    
    if (req.query.startDate) {
      filters.startDate = new Date(req.query.startDate as string);
    }
    
    if (req.query.endDate) {
      filters.endDate = new Date(req.query.endDate as string);
    }

    const transactions = await transactionsService.listTransactions(
      req.user!.uid,
      Object.keys(filters).length > 0 ? filters : undefined
    );
    res.status(200).send(transactions);
  } catch (error) {
    res.status(500).send({ error: 'Failed to fetch transactions' });
  }
});
```

---

## 5. API Contract

### 5.1. Request/Response Specifications

**POST /v1/transactions**
- **Request Body:**
  ```json
  {
    "description": "Coffee shop",
    "amount": 5.50,
    "type": "expense",
    "category": "Entertainment",
    "date": "2025-07-02T10:30:00Z"
  }
  ```
- **Response:** 201 Created with full Transaction object

**GET /v1/transactions**
- **Query Parameters:**
  - `category` (optional): Filter by category name
  - `startDate` (optional): Filter transactions from this date (ISO 8601)
  - `endDate` (optional): Filter transactions up to this date (ISO 8601)
- **Example:** `/v1/transactions?category=Groceries&startDate=2025-07-01&endDate=2025-07-31`
- **Response:** 200 OK with array of Transaction objects

---

## 6. Database Considerations

### 6.1. Firestore Index Requirements

The following composite indexes should be created in Firestore:

1. **Collection:** `transactions`
   - **Fields:** `userId` (Ascending), `category` (Ascending), `date` (Descending)
   
2. **Collection:** `transactions`
   - **Fields:** `userId` (Ascending), `date` (Descending), `category` (Ascending)

### 6.2. Migration Strategy

- Existing transactions without a `category` field will be handled gracefully
- The service will default missing categories to "Other"
- No database migration script is required due to Firestore's flexible schema

---

## 7. Error Handling

### 7.1. Validation Rules

- `category` must be one of the predefined values
- Date filters must be valid ISO 8601 dates
- `startDate` must be before or equal to `endDate`

### 7.2. Error Responses

```json
{
  "error": "Invalid category. Must be one of: Income, Groceries, Transport, Bills, Entertainment, Shopping, Other"
}
```

```json
{
  "error": "Invalid date format. Use ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ)"
}
``` 