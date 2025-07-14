# AI Integration MVP Design - Cycle 3

**Agent:** L2A3: AI Integration Architect  
**Timestamp:** 2025-07-01T13:25:00Z  
**Source Document:** `development_plan_cycle3.md`

---

## 1. Objective

To define the function specifications (tools) and the necessary refactoring of the AI orchestrator to allow the AI agent to interact with the new Goals and Budgets services.

## 2. Tool / Function Specifications

The following functions will be defined in `ai/core/tools/financial_tools.py`. These functions will be designed to be called by the AI model (e.g., as OpenAI Function Calling tools). They will, in turn, make authenticated HTTP requests to the backend API.

### `get_financial_goals()`

*   **Description:** "Retrieves a list of the user's current financial goals."
*   **Parameters:** None
*   **Returns:** A JSON array of goal objects, each containing `id`, `name`, `targetAmount`, `currentAmount`, and `targetDate`.
*   **Backend Endpoint:** `GET /v1/goals`

### `create_financial_goal(name: str, targetAmount: float, targetDate: str)`

*   **Description:** "Creates a new financial goal for the user."
*   **Parameters:**
    *   `name` (string, required): The name of the goal.
    *   `targetAmount` (number, required): The target amount for the goal.
    *   `targetDate` (string, required): The target date in `YYYY-MM-DD` format.
*   **Returns:** A JSON object of the newly created goal.
*   **Backend Endpoint:** `POST /v1/goals`

### `add_to_goal(goalId: str, amount: float)`

*   **Description:** "Adds a specified amount to the current balance of a financial goal."
*   **Parameters:**
    *   `goalId` (string, required): The ID of the goal to update.
    *   `amount` (number, required): The amount to add to the goal's `currentAmount`.
*   **Returns:** A JSON object of the updated goal.
*   **Backend Endpoint:** `PUT /v1/goals/{goalId}` (The implementation will need to handle incrementing the `currentAmount`).

## 3. Orchestrator Refactoring (`ai/core/orchestrator.py`)

The existing `AgentOrchestrator` needs to be enhanced to support tool use.

*   **Tool Registration:** A mechanism will be added to the orchestrator to register the available tools (from `financial_tools.py`) with the AI model's API call.
*   **Execution Loop:** The `route_query` method will be modified. After getting the initial response from the AI model, it must check if the model requested a tool to be called.
    *   If a tool call is requested, the orchestrator will execute the corresponding Python function.
    *   The output of the tool will be sent back to the AI model in a subsequent API call.
    *   The final response from the model (after it has processed the tool's output) will be returned to the user.

This design ensures that the AI can dynamically access the user's live financial data to answer questions or perform actions on their behalf. 