# AI Technical Design - Cycle 5

**Date:** 2025-07-02
**Author:** L2A3 (AI Architect)
**Based on:** `development_plan_cycle5.md`

---

## 1. Overview

This document specifies the AI service changes required to support filtered transaction queries with category and date range parameters.

---

## 2. Tool Enhancement

### 2.1. Financial Tools Update

**File:** `ai/core/tools/financial_tools.py`

```python
import requests
import json
from typing import Optional
from datetime import datetime

# In a real app, this would be in a config file
BASE_URL = "http://127.0.0.1:5001/cenithos/us-central1/api/v1"

def _get_auth_headers(user_id: str):
    # In a real app, this would involve a secure way to get or use a user's token
    # For this simulation, we pass the user_id to a mock auth system.
    return {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer mock-token-for-{user_id}',
    }

# EXISTING FUNCTIONS (unchanged)
def get_financial_goals(user_id: str) -> str:
    """Retrieves a list of the user's current financial goals."""
    try:
        response = requests.get(
            f"{BASE_URL}/goals",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def create_financial_goal(user_id: str, name: str, targetAmount: float, targetDate: str) -> str:
    """Creates a new financial goal for the user."""
    try:
        payload = {
            "name": name,
            "targetAmount": targetAmount,
            "targetDate": targetDate
        }
        response = requests.post(
            f"{BASE_URL}/goals",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def add_to_goal(user_id: str, goalId: str, amount: float) -> str:
    """Adds a specified amount to the current balance of a financial goal."""
    try:
        # This is a PATCH-like operation; we'll update the currentAmount.
        # First, get the current goal to calculate the new amount.
        current_goal_response = requests.get(f"{BASE_URL}/goals/{goalId}", headers=_get_auth_headers(user_id))
        current_goal_response.raise_for_status()
        current_goal = current_goal_response.json()
        
        new_amount = current_goal.get('currentAmount', 0) + amount

        payload = {"currentAmount": new_amount}
        response = requests.put(
            f"{BASE_URL}/goals/{goalId}",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)}) 

# UPDATED: Enhanced transaction tool with filtering
def get_transactions(user_id: str, category: Optional[str] = None, date_range: Optional[str] = None) -> str:
    """
    Retrieve a list of financial transactions for the user with optional filtering.
    
    Args:
        user_id: The user's unique identifier
        category: Optional category to filter by (e.g., "Groceries", "Transport")
        date_range: Optional date range to filter by (e.g., "last_month", "this_week")
    
    Returns:
        JSON string containing the filtered transactions
    """
    try:
        # Build query parameters
        params = {}
        
        if category:
            params['category'] = category
            
        if date_range:
            start_date, end_date = _parse_date_range(date_range)
            if start_date:
                params['startDate'] = start_date.isoformat()
            if end_date:
                params['endDate'] = end_date.isoformat()
        
        response = requests.get(
            f"{BASE_URL}/transactions",
            headers=_get_auth_headers(user_id),
            params=params
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

# NEW: Helper function to parse natural language date ranges
def _parse_date_range(date_range: str) -> tuple[Optional[datetime], Optional[datetime]]:
    """
    Parse natural language date ranges into start and end dates.
    
    Args:
        date_range: Natural language date range (e.g., "last_month", "this_week")
    
    Returns:
        Tuple of (start_date, end_date)
    """
    from datetime import datetime, timedelta
    import calendar
    
    now = datetime.now()
    date_range_lower = date_range.lower()
    
    if "last_month" in date_range_lower:
        # First day of last month
        first_of_this_month = now.replace(day=1)
        last_month = first_of_this_month - timedelta(days=1)
        start_date = last_month.replace(day=1)
        end_date = first_of_this_month - timedelta(days=1)
        return start_date, end_date
        
    elif "this_month" in date_range_lower:
        # First day of this month to today
        start_date = now.replace(day=1)
        end_date = now
        return start_date, end_date
        
    elif "last_week" in date_range_lower:
        # Monday of last week to Sunday of last week
        days_since_monday = now.weekday()
        start_of_this_week = now - timedelta(days=days_since_monday)
        start_of_last_week = start_of_this_week - timedelta(days=7)
        end_of_last_week = start_of_this_week - timedelta(days=1)
        return start_of_last_week, end_of_last_week
        
    elif "this_week" in date_range_lower:
        # Monday of this week to today
        days_since_monday = now.weekday()
        start_date = now - timedelta(days=days_since_monday)
        end_date = now
        return start_date, end_date
        
    elif "last_30_days" in date_range_lower or "last 30 days" in date_range_lower:
        start_date = now - timedelta(days=30)
        end_date = now
        return start_date, end_date
        
    # If no match, return None for both
    return None, None
```

---

## 3. Orchestrator Enhancement

### 3.1. Query Parsing Logic Update

**File:** `ai/core/orchestrator.py`

```python
import os
from .context_manager import ContextManager
from .agents.financial_assistant_agent import FinancialAssistantAgent
from typing import Dict, Any, Callable, Optional, Tuple
import json
import re

from ai.core.tools import financial_tools

class AgentOrchestrator:
    """
    Manages the lifecycle and interaction of AI agents based on user queries,
    including routing to appropriate tools.
    """

    def __init__(self, context_manager):
        self.context_manager = context_manager
        self.tools: Dict[str, Callable] = {
            "get_financial_goals": financial_tools.get_financial_goals,
            "create_financial_goal": financial_tools.create_financial_goal,
            "add_to_goal": financial_tools.add_to_goal,
            "get_transactions": financial_tools.get_transactions,
        }
        
        # NEW: Category mappings for parsing
        self.category_keywords = {
            'groceries': 'Groceries',
            'grocery': 'Groceries',
            'food': 'Groceries',
            'transport': 'Transport',
            'transportation': 'Transport',
            'car': 'Transport',
            'uber': 'Transport',
            'taxi': 'Transport',
            'bills': 'Bills',
            'bill': 'Bills',
            'utilities': 'Bills',
            'rent': 'Bills',
            'entertainment': 'Entertainment',
            'movie': 'Entertainment',
            'movies': 'Entertainment',
            'fun': 'Entertainment',
            'shopping': 'Shopping',
            'shop': 'Shopping',
            'clothes': 'Shopping',
            'income': 'Income',
            'salary': 'Income',
            'paycheck': 'Income',
            'pay': 'Income',
        }
        
        # NEW: Date range keywords
        self.date_range_keywords = [
            'last month', 'this month', 'last week', 'this week',
            'last 30 days', 'past month', 'past week'
        ]

    def route_query(self, user_id: str, query: str) -> Dict[str, Any]:
        """
        Routes a user query. This is a mock implementation that simulates an LLM
        deciding whether to call a tool or respond directly.
        """
        full_context = self.context_manager.get_user_context(user_id)
        
        # --- Mock LLM Tool-Calling Logic ---
        # In a real scenario, an LLM would decide this based on the query and context.
        # Here, we simulate this with simple keyword matching.
        
        query_lower = query.lower()
        tool_to_call = None
        args = ()
        
        if "list my goals" in query_lower or "show my goals" in query_lower:
            tool_to_call = self.tools["get_financial_goals"]
            args = (user_id,)
            agent_name = "financial_assistant (tool_caller)"

        elif "create a goal" in query_lower:
            tool_to_call = self.tools["create_financial_goal"]
            args = (user_id, "New Car", 25000.0, "2026-12-01") 
            agent_name = "financial_assistant (tool_caller)"

        elif any(keyword in query_lower for keyword in ["show my transactions", "list my transactions", "my spending", "my expenses"]):
            tool_to_call = self.tools["get_transactions"]
            
            # NEW: Parse category and date range from query
            category = self._parse_category(query_lower)
            date_range = self._parse_date_range(query_lower)
            
            # Build arguments based on what was parsed
            args = [user_id]
            if category:
                args.append(category)
            else:
                args.append(None)
            if date_range:
                args.append(date_range)
            else:
                args.append(None)
            
            args = tuple(args)
            agent_name = "financial_assistant (tool_caller)"

        # If a tool is identified, call it
        if tool_to_call:
            print(f"Executing tool: {tool_to_call.__name__} with args: {args}")
            tool_result_str = tool_to_call(*args)
            tool_result = json.loads(tool_result_str)
            
            # Enhanced response formatting for transactions
            if tool_to_call.__name__ == "get_transactions":
                response_text = self._format_transactions_response(tool_result, args)
            else:
                response_text = f"I have executed the action. Here is the result: {json.dumps(tool_result)}"
            
            response_data = {
                "agent_used": agent_name,
                "original_query": query,
                "response_text": response_text,
                "confidence": 0.98,
                "tool_used": tool_to_call.__name__,
                "tool_result": tool_result
            }
        else:
            # Fallback to a conversational response
            response_text = f"I'm sorry, I can only help with financial goals and transactions right now. How can I assist with that?"
            agent_name = "general_assistant"
            response_data = {
                 "agent_used": agent_name,
                 "original_query": query,
                 "response_text": response_text,
                 "confidence": 0.90
            }

        self.context_manager.update_user_context(user_id, {"last_query": query, "last_response": response_data})
        return response_data
    
    # NEW: Category parsing method
    def _parse_category(self, query: str) -> Optional[str]:
        """Parse category from natural language query."""
        for keyword, category in self.category_keywords.items():
            if keyword in query:
                return category
        return None
    
    # NEW: Date range parsing method
    def _parse_date_range(self, query: str) -> Optional[str]:
        """Parse date range from natural language query."""
        for date_range in self.date_range_keywords:
            if date_range in query:
                return date_range.replace(' ', '_')  # Convert to function format
        return None
    
    # NEW: Enhanced response formatting for transactions
    def _format_transactions_response(self, tool_result: Dict[str, Any], args: tuple) -> str:
        """Format transaction results into a user-friendly response."""
        if "error" in tool_result:
            return f"I couldn't retrieve your transactions: {tool_result['error']}"
        
        transactions = tool_result if isinstance(tool_result, list) else []
        
        if not transactions:
            return "You don't have any transactions matching those criteria."
        
        # Extract filter info from args for context
        category = args[1] if len(args) > 1 and args[1] else None
        date_range = args[2] if len(args) > 2 and args[2] else None
        
        # Build response with context
        context_parts = []
        if category:
            context_parts.append(f"in the {category} category")
        if date_range:
            formatted_range = date_range.replace('_', ' ')
            context_parts.append(f"from {formatted_range}")
        
        context_str = " ".join(context_parts)
        if context_str:
            response_lines = [f"Here are your transactions {context_str}:"]
        else:
            response_lines = ["Here are your recent transactions:"]
        
        # Format each transaction
        for tx in transactions[:10]:  # Limit to 10 for readability
            amount_str = f"${abs(tx['amount']):.2f}"
            tx_type = "income" if tx['type'] == 'income' else "expense"
            date_str = tx['date'][:10]  # Just the date part
            category_str = tx.get('category', 'Other')
            
            response_lines.append(
                f"• {tx['description']} - {amount_str} ({category_str}) on {date_str}"
            )
        
        if len(transactions) > 10:
            response_lines.append(f"... and {len(transactions) - 10} more transactions")
        
        return "\n".join(response_lines)
```

---

## 4. Query Examples

The enhanced AI will now understand queries like:

### 4.1. Category-based Queries
- "Show me my groceries spending"
- "What did I spend on transport last month?"
- "List my entertainment expenses"

### 4.2. Date-based Queries
- "Show me my transactions from last week"
- "What were my expenses this month?"
- "List my spending in the last 30 days"

### 4.3. Combined Queries
- "How much did I spend on groceries last month?"
- "Show me my transport expenses this week"
- "What were my bills last month?"

---

## 5. Testing Strategy

### 5.1. Unit Tests for Tools
- Test `get_transactions` with various parameter combinations
- Test `_parse_date_range` helper function with different inputs
- Verify proper query parameter building

### 5.2. Integration Tests for Orchestrator
- Test category parsing with various phrasings
- Test date range parsing accuracy
- Test combined category + date range queries
- Verify response formatting quality

### 5.3. End-to-End Tests
- Test complete query flow from natural language to formatted response
- Verify integration with backend filtering API
- Test edge cases (no results, invalid categories, etc.)

---

## 6. Error Handling

The AI will gracefully handle:
- Unrecognized categories (falls back to no filter)
- Invalid date ranges (falls back to no date filter)
- Empty results (provides helpful message)
- Backend API errors (user-friendly error messages) 