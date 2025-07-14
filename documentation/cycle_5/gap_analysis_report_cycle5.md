# Gap Analysis Report - Cycle 5

**Date:** 2025-07-02
**Author:** L1A2 (Gap Analysis Agent)
**Based on:** `product_vision_summary_cycle5.md`

---

## 1. Introduction

This report identifies the gap between the current codebase and the desired state outlined in the product vision for Cycle 5. The focus is on implementing transaction categorization, filtering, and enhanced AI interaction.

---

## 2. Gap Analysis by Domain

### 2.1. Backend (`/backend/functions/src`)

-   **Goal:** Add category support and filtering capabilities to the transactions API.
-   **Current State:** Transactions have no category field. The API can only list all transactions for a user.
-   **Required Changes:**
    -   **`models/transaction.ts`**:
        -   **[MODIFICATION]** Add a `category: string` field to the `Transaction` interface.
    -   **`services/transactions.ts`**:
        -   **[MODIFICATION]** Update `createTransaction` to accept and save the `category`.
        -   **[MODIFICATION]** Update `listTransactions` to accept optional `category` and `dateRange` parameters and add corresponding `.where()` clauses to the Firestore query.
    -   **`index.ts`**:
        -   **[MODIFICATION]** Update the `GET /transactions` route handler to extract filter parameters from the request's query string and pass them to the `listTransactions` service.

### 2.2. Mobile (`/mobile/centhios/lib`)

-   **Goal:** Implement UI for transaction categorization and filtering.
-   **Current State:** The UI supports creating and viewing a simple list of transactions.
-   **Required Changes:**
    -   **`data/models/transaction_model.dart`**:
        -   **[MODIFICATION]** Add a `final String category;` field to the `Transaction` class and update the `fromJson` factory.
    -   **`data/repositories/transactions_repository.dart`**:
        -   **[MODIFICATION]** Update `getTransactions` to accept filter parameters and append them as a query string to the API request URL.
        -   **[MODIFICATION]** Ensure `createTransaction` sends the new category data.
    -   **`presentation/widgets/add_transaction_dialog.dart`**:
        -   **[MODIFICATION]** Add a `DropdownButtonFormField` or similar widget to select a category from a predefined list.
    -   **`presentation/pages/transactions_page.dart`**:
        -   **[MODIFICATION]** Add state management for active filters.
        -   **[MODIFICATION]** Add UI elements (e.g., a filter icon button opening a bottom sheet or dialog) to allow users to select categories and date ranges.
        -   **[MODIFICATION]** Update the `transactionsProvider` to pass the selected filters to the repository.
    -   **`presentation/widgets/transaction_list_item.dart`**:
        -   **[MODIFICATION]** Add a `Text` widget to display the transaction's category.

### 2.3. AI (`/ai/core`)

-   **Goal:** Enhance the AI assistant to understand and answer filtered transaction queries.
-   **Current State:** The AI can only fetch all transactions.
-   **Required Changes:**
    -   **`tools/financial_tools.py`**:
        -   **[MODIFICATION]** Modify the `get_transactions` function to accept optional `category` and `date_range` parameters and pass them as query params in the `requests` call.
    -   **`orchestrator.py`**:
        -   **[MODIFICATION]** Enhance the mock LLM logic in `route_query` to parse categories and date ranges from the user's query string (e.g., find "groceries" in "show me my groceries spending").
        -   **[MODIFICATION]** Pass the parsed arguments to the `get_transactions` tool when it is called.

---

## 3. Conclusion

The required work is well-defined and touches all three major components of the application stack. The modifications are extensions of existing features, indicating a moderate level of complexity. This report provides a clear blueprint for the L1A3 Development Task Planner to create a detailed implementation plan. 