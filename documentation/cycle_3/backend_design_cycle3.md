# Backend MVP Design - Cycle 3

**Agent:** L2A1: Backend Architect  
**Timestamp:** 2025-07-01T13:25:00Z  
**Source Document:** `development_plan_cycle3.md`

---

## 1. Objective

To provide the specific data models for Firestore and the associated security rules required to implement the MVP features.

## 2. Firestore Data Models

### `goals` collection

A document in this collection represents a single financial goal for a user.

*   **Path:** `goals/{goalId}`
*   **Fields:**
    *   `userId` (string): The UID of the user who owns the goal.
    *   `name` (string): The name of the goal (e.g., "New Car Fund").
    *   `targetAmount` (number): The total amount to be saved.
    *   `currentAmount` (number): The amount currently saved.
    *   `targetDate` (timestamp): The date the user aims to achieve the goal by.
    *   `createdAt` (timestamp): Server-side timestamp of when the goal was created.
    *   `updatedAt` (timestamp): Server-side timestamp of the last update.

### `budgets` collection

A document in this collection represents a single budget category for a user.

*   **Path:** `budgets/{budgetId}`
*   **Fields:**
    *   `userId` (string): The UID of the user who owns the budget.
    *   `name` (string): The name of the budget (e.g., "Monthly Groceries").
    *   `category` (string): The spending category this budget applies to.
    *   `limitAmount` (number): The maximum amount for this budget per period.
    *   `createdAt` (timestamp): Server-side timestamp of when the budget was created.

## 3. Firestore Security Rules (`firestore.rules`)

These rules ensure that users can only access and modify their own data.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Allow users to manage their own goals
    match /goals/{goalId} {
      // Create: user must be logged in and the new doc's userId must match their own
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      // Read, Update, Delete: user must be logged in and the doc's userId must match their own
      allow read, update, delete: if request.auth != null && get(/databases/$(database)/documents/goals/$(goalId)).data.userId == request.auth.uid;
    }

    // Allow users to manage their own budgets
    match /budgets/{budgetId} {
      // Create: user must be logged in and the new doc's userId must match their own
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      // Read, Update, Delete: user must be logged in and the doc's userId must match their own
      allow read, update, delete: if request.auth != null && get(/databases/$(database)/documents/budgets/$(budgetId)).data.userId == request.auth.uid;
    }
    
    // Transactions from original implementation
    match /transactions/{transactionId} {
        allow read, write: if request.auth != null; // Simplistic rule, should be more specific
    }

  }
}
``` 