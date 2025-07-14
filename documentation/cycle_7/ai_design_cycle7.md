# AI Technical Design: Cycle 7

**Cycle Goal:** Resolve Mobile Testing Blockers & Introduce Real-Time AI Feedback.

## 1. Introduction

This document provides the technical design for refactoring the AI backend to support real-time, streaming responses. This will transform the user experience from a static, blocking request into a dynamic, conversational interaction.

## 2. Core Architectural Change: From `return` to `yield`

The fundamental change is to convert our core logic from a single return value to a stream of events. We will use Python's generator functions (`yield`) to achieve this.

### 2.1. Streaming Response Data Model

All yielded data will be a JSON-encoded string representing an event object. This provides a structured way for the client to handle different types of messages.

```json
// Example Status Update
{
  "type": "status",
  "data": "Thinking..."
}

// Example Final Result
{
  "type": "result",
  "data": {
    "agent_used": "financial_assistant (tool_caller)",
    "response_text": "I have executed the action...",
    "tool_used": "get_transactions",
    "tool_result": [...]
  }
}
```

### 2.2. `AgentOrchestrator` as a Generator

The `route_query` method will be converted to an `async def` that `yield`s these event objects.

**File:** `ai/core/orchestrator.py`

```python
import asyncio

class AgentOrchestrator:
    # ... (existing init) ...

    async def route_query(self, user_id: str, query: str) -> AsyncGenerator[str, None]:
        # Yield initial status
        yield json.dumps({"type": "status", "data": "Processing your request..."})
        await asyncio.sleep(0.5) # Simulate initial processing

        # ... (existing context retrieval and logic) ...

        if tool_to_call:
            yield json.dumps({"type": "status", "data": f"Consulting tool: {tool_to_call.__name__}..."})
            await asyncio.sleep(0.5)
            
            # ... (execute tool) ...
            
            response_text = f"I have executed the action. Here is the result: {json.dumps(tool_result)}"
            
            # ... (update context) ...

            final_response = { "type": "result", "data": response_data }
            yield json.dumps(final_response)
        
        else:
            # ... (handle fallback response) ...
            fallback_response = { "type": "result", "data": response_data }
            yield json.dumps(fallback_response)
```

### 2.3. FastAPI `StreamingResponse`

The FastAPI endpoint will be updated to handle the generator function from the orchestrator and return a `StreamingResponse`.

**File:** `ai/main.py`

```python
from fastapi.responses import StreamingResponse

# ... (existing setup) ...

@app.post("/query")
async def process_query(request: QueryRequest):
    # The orchestrator's route_query is now an async generator
    generator = orchestrator.route_query(request.user_id, request.query)
    return StreamingResponse(generator, media_type="application/x-ndjson")

```
The `application/x-ndjson` (newline-delimited JSON) media type is appropriate for this kind of streaming, where each yielded string is a self-contained JSON object.

## 3. Conclusion

This design provides a clear and efficient path to implementing a real-time streaming architecture. By converting the core logic to use `yield` and leveraging FastAPI's `StreamingResponse`, we can create a more responsive and engaging AI without adding significant complexity. 