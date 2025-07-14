# Backend Technical Design - Cycle 4

**Date:** 2025-07-01
**Author:** L2A1 (Backend Architect)
**Based on:** `development_plan_cycle4.md`

---

## 1. Overview

This document specifies the technical implementation details for the new Transaction Management service.

---

## 2. Data Model

A new Firestore collection `transactions` will be created.

**File:** `backend/functions/src/models/transaction.ts`

```typescript
export interface Transaction {
  id: string;
  userId: string;
  description: string;
  amount: number;
  type: 'income' | 'expense';
  date: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## 3. Service Layer

**File:** `backend/functions/src/services/transactions.ts`

The `TransactionsService` will contain two primary methods:

- `createTransaction(userId: string, data: Omit<Transaction, 'id' | 'userId' | 'createdAt' | 'updatedAt'>): Promise<Transaction>`
  - Validates input data.
  - Adds a new document to the `transactions` collection.
  - Returns the newly created transaction object.

- `listTransactions(userId: string): Promise<Transaction[]>`
  - Queries the `transactions` collection for all documents where `userId` matches.
  - Orders the results by `date` in descending order.
  - Returns an array of transaction objects.

---

## 4. API Endpoints

**File:** `backend/functions/src/index.ts`

Two new endpoints will be added under the `/transactions` route:

- **`POST /transactions`**
  - **Description:** Creates a new transaction.
  - **Auth:** Requires authenticated user (verifies JWT).
  - **Body:** `{ description: string, amount: number, type: 'income' | 'expense', date: string }`
  - **Response:** `201 Created` with the new `Transaction` object.

- **`GET /transactions`**
  - **Description:** Retrieves all transactions for the authenticated user.
  - **Auth:** Requires authenticated user.
  - **Response:** `200 OK` with an array of `Transaction` objects.

---

## 5. Firestore Security Rules

**File:** `backend/firestore.rules`

The following rules will be added to secure the `transactions` collection:

```
match /transactions/{transactionId} {
  allow read, write: if request.auth.uid == resource.data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
}
``` 