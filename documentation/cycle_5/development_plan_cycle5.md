# Development Plan - Cycle 5

**Date:** 2025-07-02
**Author:** L1A3 (Development Task Planner)
**Based on:** `gap_analysis_report_cycle5.md`

---

## 1. Overview

This plan implements transaction categorization, filtering, and enhanced AI interaction capabilities. The work is organized into three phases to ensure proper dependency management and incremental validation.

---

## 2. Implementation Phases

### Phase 1: Backend Foundation (Priority: High)
*Establish the data model and API support for categories and filtering*

**L3A1 (Backend Engineer) Tasks:**

1. **Update Transaction Data Model**
   - **File:** `backend/functions/src/models/transaction.ts`
   - **Task:** Add `category: string` field to the `Transaction` interface
   - **Dependencies:** None

2. **Enhance Transaction Service - Create**
   - **File:** `backend/functions/src/services/transactions.ts`
   - **Task:** Modify `createTransaction` function to accept and store the `category` field
   - **Dependencies:** Task 1

3. **Enhance Transaction Service - List with Filters**
   - **File:** `backend/functions/src/services/transactions.ts`
   - **Task:** Update `listTransactions` to accept optional `category` and `dateRange` parameters and implement Firestore query filtering
   - **Dependencies:** Task 1

4. **Update API Routes**
   - **File:** `backend/functions/src/index.ts`
   - **Task:** Modify the `GET /transactions` route to extract query parameters (`category`, `startDate`, `endDate`) and pass them to the service
   - **Dependencies:** Task 3

### Phase 2: Mobile Implementation (Priority: High)
*Build the user interface for categorization and filtering*

**L3A2 (Mobile Engineer) Tasks:**

5. **Update Mobile Transaction Model**
   - **File:** `mobile/centhios/lib/data/models/transaction_model.dart`
   - **Task:** Add `category` field to the `Transaction` class and update the `fromJson` factory method
   - **Dependencies:** None (can work in parallel with Phase 1)

6. **Enhance Transaction Repository**
   - **File:** `mobile/centhios/lib/data/repositories/transactions_repository.dart`
   - **Task:** 
     - Update `getTransactions` method to accept filter parameters and build query string
     - Ensure `createTransaction` sends category data
   - **Dependencies:** Task 5, Backend Tasks 2-4

7. **Add Category Selection to Dialog**
   - **File:** `mobile/centhios/lib/presentation/widgets/add_transaction_dialog.dart`
   - **Task:** Add dropdown/picker for category selection with predefined categories (Groceries, Transport, Bills, Entertainment, Income, Other)
   - **Dependencies:** Task 5

8. **Display Category in List Item**
   - **File:** `mobile/centhios/lib/presentation/widgets/transaction_list_item.dart`
   - **Task:** Add UI element to display transaction category
   - **Dependencies:** Task 5

9. **Implement Transaction Filtering UI**
   - **File:** `mobile/centhios/lib/presentation/pages/transactions_page.dart`
   - **Task:** 
     - Add filter state management
     - Create filter UI (bottom sheet or dialog)
     - Update `transactionsProvider` to use filters
     - Add filter button to app bar
   - **Dependencies:** Task 6

### Phase 3: AI Enhancement (Priority: Medium)
*Enhance AI to understand filtered transaction queries*

**L3A3 (AI Engineer) Tasks:**

10. **Update Transaction Tool**
    - **File:** `ai/core/tools/financial_tools.py`
    - **Task:** Modify `get_transactions` function to accept optional `category` and `date_range` parameters and pass them as query parameters
    - **Dependencies:** Backend Tasks 1-4

11. **Enhance AI Query Parsing**
    - **File:** `ai/core/orchestrator.py`
    - **Task:** 
      - Add keyword parsing for categories ("groceries", "transport", etc.)
      - Add date range parsing ("last month", "this week", etc.)
      - Pass parsed parameters to the `get_transactions` tool
    - **Dependencies:** Task 10

---

## 3. Predefined Categories

For consistency across all components, the following categories will be used:
- **Income**
- **Groceries**
- **Transport**
- **Bills**
- **Entertainment**
- **Shopping**
- **Other**

---

## 4. Testing Strategy

1. **Unit Tests:** Each modified function should have corresponding tests
2. **Integration Tests:** Test the full flow from mobile UI → backend API → database
3. **AI Tests:** Verify that filtered queries return expected results
4. **End-to-End Tests:** Manual testing of the complete user journey

---

## 5. Definition of Done

- ✅ Users can select a category when creating transactions
- ✅ Transactions display their category in the list view
- ✅ Users can filter transactions by category and date range
- ✅ AI assistant can answer queries like "Show me my groceries spending last month"
- ✅ All automated tests pass
- ✅ No regressions in existing functionality

---

## 6. Risk Mitigation

- **Database Migration:** Existing transactions without categories will default to "Other"
- **API Compatibility:** New query parameters are optional to maintain backward compatibility
- **UI/UX:** Filter UI should be intuitive and not clutter the main transactions view 