# AI Technical Design: Cycle 6

**Cycle Goal:** Stabilize Mobile Test Environment & Enhance AI for Conversational Context.

## 1. Introduction

This document provides the technical design for transforming the AI assistant from a stateless command processor into a stateful, context-aware conversational agent. The current implementation treats every query in isolation. This design outlines the changes required to enable multi-turn conversations.

## 2. Core Problem: Statelessness

The `AgentOrchestrator` is the brain of our AI, but it currently has no memory. It uses simple keyword matching on a single query to execute a tool. This prevents it from handling follow-up questions or understanding context. The `ContextManager` only stores the *last* interaction, which is insufficient for true conversation.

## 3. Proposed Solution: Stateful Context and Logic

We will introduce state and memory into the AI system by modifying the context management and the orchestration logic.

### 3.1. `ContextManager` Enhancement

The `ContextManager` will be updated to store a transcript of the conversation, not just the last message. It will also hold temporary, turn-specific data, such as the results of a recent tool call.

**File:** `ai/core/context_manager.py`

```python
# Updated structure for user_context in self.context
{
    "user_id": {
        "conversation_history": [
            {"role": "user", "content": "Show me my transactions"},
            {"role": "assistant", "content": "Here are your last 5 transactions..."},
            # ... more turns
        ],
        "last_tool_result": [...] # Store the result of the last tool call
    }
}

class ContextManager:
    def __init__(self, history_limit=10):
        self.context = {}
        self.history_limit = history_limit

    def get_user_context(self, user_id):
        return self.context.setdefault(user_id, {"conversation_history": [], "last_tool_result": None})

    def update_user_context(self, user_id, new_data):
        # This will now append to the history and manage its size
        user_context = self.get_user_context(user_id)
        
        if "new_turn" in new_data:
            user_context["conversation_history"].append(new_data["new_turn"])
            # Trim history if it exceeds the limit
            if len(user_context["conversation_history"]) > self.history_limit * 2: # user + assistant
                user_context["conversation_history"] = user_context["conversation_history"][-self.history_limit*2:]

        if "last_tool_result" in new_data:
             user_context["last_tool_result"] = new_data["last_tool_result"]

```

### 3.2. `AgentOrchestrator` Refactoring

The orchestrator's `route_query` method will be refactored to be context-aware.

**File:** `ai/core/orchestrator.py`

**High-Level Logic for `route_query`:**

1.  **Get Context:** Retrieve the user's full context, including `conversation_history` and `last_tool_result`, from the `ContextManager`.
2.  **Stateful Mock LLM Routing:** The mock LLM logic will be enhanced. It will no longer be a simple `if/elif` chain based on the current query. Instead, it will check for contextual clues.
    -   **Example Follow-up:** If the `last_tool_result` contains a list of transactions and the new query is "filter for food", the orchestrator will know to apply a filter to the data held in `last_tool_result` rather than calling the `get_transactions` tool again.
3.  **Update Context:** After processing, the orchestrator will update the context via the `ContextManager` with the new user message, the AI's response, and the result of any tool call that was made.

**Conceptual Code Change in `AgentOrchestrator`:**

```python
def route_query(self, user_id: str, query: str) -> Dict[str, Any]:
    full_context = self.context_manager.get_user_context(user_id)
    history = full_context["conversation_history"]
    last_tool_result = full_context["last_tool_result"]
    query_lower = query.lower()

    # --- New Stateful Mock LLM Logic ---
    
    # 1. Check for contextual commands first
    if last_tool_result and ("filter" in query_lower or "show only" in query_lower):
        # A filtering follow-up is likely intended.
        # Create a new, temporary tool/function to filter the data in `last_tool_result`.
        # For example, filter a list of transactions by category.
        category_match = re.search(r"for (\w+)", query_lower)
        if category_match:
            category = category_match.group(1)
            filtered_data = [t for t in last_tool_result if t.get('category') == category]
            
            # Formulate response and update context
            response_text = f"I have filtered your results: {json.dumps(filtered_data)}"
            # ... (build response_data)
            self.context_manager.update_user_context(user_id, {
                "new_turn": {"role": "user", "content": query},
                "new_turn": {"role": "assistant", "content": response_text},
                "last_tool_result": filtered_data # The new state is the filtered data
            })
            return response_data

    # 2. If not a contextual command, fall back to existing tool-calling logic
    # ... (the if/elif chain for get_transactions, create_goal, etc.)
    # Important: When a tool is called, its result MUST be saved to the context.
    if tool_to_call:
        # ... call tool ...
        self.context_manager.update_user_context(user_id, {
            # ... (update conversation history)
            "last_tool_result": tool_result
        })

    # ... (return response)
```

## 4. Conclusion

This design moves our AI from a simple, reactive system to one with memory. By enhancing the `ContextManager` to store conversational history and refactoring the `AgentOrchestrator` to use this history, we can create a more natural and powerful user experience, fulfilling the "Intelligence" goal of Cycle 6. 