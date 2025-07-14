# Centhios AI Assistant ("Alex")

The Centhios AI Assistant, "Alex," is a sophisticated, multi-agent system designed to provide intelligent, contextual, and specialized financial guidance. It goes beyond simple Q&A to act as a team of financial experts, managed by a Chief Financial Agent.

## Core Architecture: Multi-Agent System

Instead of a single AI trying to handle all tasks, Alex is composed of several specialist agents, each an expert in its domain. A "manager" agent, the **Chief Financial Agent (CFA)**, analyzes your requests and routes them to the appropriate specialist.

### Specialist Agents:

1.  **Investment Analyst ("Ivy"):**
    *   **Expertise:** All things related to investments.
    *   **Capabilities:**
        *   Tracking your portfolio of stocks, mutual funds, gold, etc.
        *   Analyzing the performance of your investments.
        *   Answering questions about your holdings.
    *   **Example Usage:**
        *   "How are my investments doing?"
        *   "Show me my mutual funds."
        *   "Add 10 shares of Reliance to my portfolio."

2.  **Budgeting Advisor ("Buddy"):**
    *   **Expertise:** Budgets and spending analysis.
    *   **Capabilities:**
        *   Creating and managing monthly or custom budgets.
        *   Comparing your spending against your budget limits.
        *   Analyzing your transaction history to find areas where you can save.
    *   **Example Usage:**
        *   "Create a ₹5000 budget for shopping this month."
        *   "Am I over budget on groceries?"
        *   "Analyze my spending for last month."

3.  **General Assistant (The Fallback):**
    *   **Expertise:** General, non-specialized queries.
    *   **Capabilities:**
        *   Retrieving financial goals.
        *   Listing transactions.
    *   **Example Usage:**
        *   "List my financial goals."
        *   "Show me my recent transactions."

## How to Use Alex

Interact with Alex through the "Alex" tab in the app. You can use natural language to ask questions or give commands. Be as specific or as general as you like. The more context you provide, the better the assistance Alex can offer.

**Example Conversation:**

*   **You:** "Create a new goal to save for a vacation."
*   **Alex (Generalist):** "That sounds exciting! How much do you want to save, and by when?"
*   **You:** "₹50,000 by December."
*   **Alex (Generalist):** *[Uses the `create_financial_goal` tool]* "Great! I've created a new goal for you: 'Vacation' with a target of ₹50,000 by December 31, 2024."

*   **You:** "How's my shopping budget looking?"
*   **Alex (CFA routes to BudgetingAdvisor):** *[Buddy uses the `get_budgets` and `get_transactions` tools]* "You've spent ₹3,500 of your ₹5,000 shopping budget this month, so you have ₹1,500 remaining. You're right on track!" 