# AI Technical Design - Cycle 4

**Date:** 2025-07-01
**Author:** L2A3 (AI Architect)
**Based on:** `development_plan_cycle4.md`

---

## 1. Overview

This document outlines the required changes to the AI service to support querying user transactions.

---

## 2. Tool Implementation

**File:** `ai/core/tools/financial_tools.py`

A new tool function will be added to the `FinancialTools` class.

```python
# ... existing imports
from typing import List, Dict, Any

class FinancialTools:
    # ... existing methods: get_goals, create_goal, etc.

    @tool("get_transactions")
    def get_transactions(self) -> List[Dict[str, Any]]:
        """
        Retrieves a list of the user's most recent financial transactions.
        
        This tool connects to the backend API to fetch transaction data.
        
        Returns:
            A list of dictionaries, where each dictionary represents a transaction.
            Returns an empty list if there are no transactions.
        """
        # Logic to make a GET request to the backend's /transactions endpoint
        # The user's ID/token will need to be passed in the request headers
        # for authentication.
        
        # Example implementation:
        try:
            # Assuming self.session is a requests.Session object with auth headers
            response = self.session.get(f"{self.base_api_url}/transactions")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": f"API request failed: {e}"}

```

---

## 3. Orchestrator Integration

**File:** `ai/core/orchestrator.py`

The `AgentOrchestrator` will be updated to recognize user intent related to transactions.

### 3.1. Intent Recognition

- **Training Phrases:** The underlying Language Model's fine-tuning or prompt engineering will need to be updated to associate phrases like the following with the `get_transactions` tool:
  - "Show me my recent transactions"
  - "What are my latest expenses?"
  - "Can I see my income for this month?"
  - "List my spending"

### 3.2. Routing Logic

- The `_route_request` method within the orchestrator will be modified to include a case for this new intent.

```python
# In AgentOrchestrator class

    def _route_request(self, parsed_sms: Dict[str, Any]) -> Dict[str, Any]:
        intent = parsed_sms.get("intent")
        
        # ... existing routing for 'get_goals', 'create_budget', etc.

        if intent == "get_transactions":
            result = self.financial_tools.get_transactions()
            return {
                "response_text": self._format_transactions(result),
                "tool_used": "get_transactions",
                "tool_result": result,
            }

        # ... other intents and default response
```

### 3.3. Response Formatting

- A new private method, `_format_transactions`, will be created to format the JSON response from the tool into a human-readable string.

```python
# In AgentOrchestrator class

    def _format_transactions(self, transactions: List[Dict[str, Any]]) -> str:
        if not transactions or "error" in transactions:
            return "I couldn't retrieve your transactions at the moment."
        
        response_lines = ["Here are your recent transactions:"]
        for tx in transactions:
            tx_type = "Income" if tx['type'] == 'income' else "Expense"
            # Format date and amount for display
            formatted_date = # ...
            formatted_amount = # ...
            response_lines.append(f"- {formatted_date}: {tx['description']} ({tx_type}) - {formatted_amount}")
            
        return "\n".join(response_lines)
``` 