from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any, AsyncGenerator
import json
import re
from fastapi import HTTPException
import os
import openai
from dotenv import load_dotenv
from openai import OpenAI
load_dotenv()
import logging
import firebase_admin
from firebase_admin import credentials, firestore

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("centhios-ai")

# --- Local Imports ---
from ai.core.agent_service import invoke_multi_agent_system
from ai.core.agents import CategorizationAgent, PredictionAgent
from ai.core.llm import LlmProviderFactory

app = FastAPI(
    title="Centhios AI API",
    description="API for interacting with the Centhios AI financial assistant.",
    version="2.0.0",  # Version bump to reflect new agent architecture
)

# --- App Globals ---
# Use regular OpenAI client for synchronous operations
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
prediction_agent: PredictionAgent = None
db = None


# --- API Models ---
class QueryRequest(BaseModel):
    user_id: str
    query: str
    # chat_history is not implemented on the client yet, but the agent supports it
    chat_history: Optional[list] = None

class QueryResponse(BaseModel):
    output: Any

class SmsParseRequest(BaseModel):
    user_id: str
    messages: list[str]
    current_date: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    context: Optional[Dict[str, Any]] = None

class CategorizeRequest(BaseModel):
    transactions: list[dict]
    categories: list[str]


async def stream_query_response(request: QueryRequest) -> AsyncGenerator[str, None]:
    """
    Calls the orchestrator and streams the JSON responses.
    """
    for response_part in orchestrator.route_query(user_id=request.user_id, query=request.query):
        yield json.dumps(response_part) + "\n"

# --- API Endpoints ---
@app.on_event("startup")
def on_startup():
    global prediction_agent, db
    logger.info("Centhios AI API is starting up.")
    logger.info(f"OPENAI_API_KEY loaded: {'Yes' if os.getenv('OPENAI_API_KEY') else 'No'}")
    
    # Initialize Firebase Admin SDK
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if cred_path:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        logger.info("Firebase Admin SDK initialized successfully.")
    else:
        logger.error("GOOGLE_APPLICATION_CREDENTIALS not set. Firestore integration will be disabled.")

    # Initialize Prediction Agent
    if db:
        prediction_agent = PredictionAgent(firestore_client=db)
        logger.info("PredictionAgent initialized.")


@app.post("/query", response_model=QueryResponse)
async def handle_query(request: QueryRequest):
    """
    Receives a user query and invokes the new multi-agent system.
    """
    logger.info(f"Invoking multi-agent system for user '{request.user_id}' with query: '{request.query}'")
    try:
        result = invoke_multi_agent_system(
            user_id=request.user_id,
            query=request.query,
            # chat_history is not passed yet, but the architecture supports it
        )
        return QueryResponse(output=result.get("output"))
    except Exception as e:
        logger.exception(f"An error occurred while invoking the agent: {e}")
        raise HTTPException(status_code=500, detail="An error occurred while processing your query.")

@app.get("/")
def read_root():
    return {"message": "Centhios AI API v2 is running."}

@app.post("/reset-context")
def reset_context(request: Dict[str, str]):
    """Testing endpoint to clear a user's context."""
    user_id = request.get("user_id")
    if user_id:
        orchestrator.context_manager.clear_user_context(user_id)
        return {"status": "cleared"}
    return {"status": "user_id not provided"}

async def get_category_feedback_examples(db_client, user_id: str, limit: int = 10) -> str:
    """Fetches recent category corrections and formats them as prompt examples."""
    if not db_client:
        return ""
    try:
        feedback_ref = db_client.collection("ai_category_corrections")
        query = feedback_ref.where("userId", "==", user_id).order_by(
            "createdAt", direction=firestore.Query.DESCENDING
        ).limit(limit)
        docs = query.stream()

        examples = []
        seen_descriptions = set()
        for doc in docs:
            data = doc.to_dict()
            description = data.get("description", "").strip()
            # Normalize to avoid minor variations cluttering examples
            normalized_desc = ' '.join(re.sub(r'\d+', '', description).lower().split())

            if description and normalized_desc and normalized_desc not in seen_descriptions:
                examples.append(
                    f'- For transactions like "{description}", the user prefers the category "{data["newCategory"]}" over "{data["oldCategory"]}".'
                )
                seen_descriptions.add(normalized_desc)
        
        if not examples:
            return ""
        
        examples.reverse()
        header = "--- \nLEARNINGS FROM USER CORRECTIONS:\nThis user has provided feedback. Prioritize these patterns:\n\n"
        return header + "\n".join(examples) + "\n---"
    except Exception as e:
        logger.error(f"Error fetching category feedback for user {user_id}: {e}")
        return ""

@app.post("/parse-sms")
async def parse_sms(request: SmsParseRequest):
    logger.info(f"Received /parse-sms request for user {request.user_id} with {len(request.messages)} messages.")
    logger.debug(f"Raw SMS messages received: {request.messages}")
    
    # Dynamic category generation
    default_categories = "['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Groceries', 'Investment', 'Income', 'Other', 'Uncategorized']"
    category_list_str = default_categories
    
    if request.context and 'categories' in request.context and request.context['categories']:
        # Create a string representation of the list, e.g., "['Food', 'Transport']"
        category_list_str = str(request.context['categories'])
        logger.info(f"Using dynamic categories from request: {category_list_str}")
    else:
        logger.info("No dynamic categories provided, using defaults.")

    # Fetch few-shot examples from user feedback
    logger.info(f"Fetching feedback examples for user {request.user_id}.")
    feedback_examples = await get_category_feedback_examples(db, request.user_id)
    if feedback_examples:
        logger.info(f"Found {len(feedback_examples.splitlines()) - 4} feedback examples for user.")
    else:
        logger.info(f"No feedback examples found for user {request.user_id}.")

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logger.error("OpenAI API key not set.")
        raise HTTPException(status_code=500, detail="OpenAI API key not set.")
    
    base_system_prompt = f"""
You are a hyper-attentive financial data extractor for Indian SMS alerts. Your only job is to return a valid JSON array of transaction objects. Do not add any conversational text or markdown.

Each transaction object in the array MUST have the following fields:

- "amount": (number) The transaction amount.
- "currency": (string) The ISO 4217 currency code (e.g., "INR").
- "description": (string) A brief, clean, human-readable description. E.g., for "bistrobyblinkit.rzp@mairtel", the description should be "Bistro by Blinkit", not the full merchant ID. **REQUIRED**.
- "category": (string) Classify into ONE of or any appropriate category: {category_list_str}. **REQUIRED**.
- "merchant": (string) The raw payment gateway or UPI ID (e.g., "bistrobyblinkit.rzp@mairtel").
- "vendor": (string) The user-facing business name (e.g., "Bistro by Blinkit").
- "bank": (string) The name of the bank or card provider (e.g., "HDFC Bank", "Kotak Bank", "SBI").
- "date": (string) The date in YYYY-MM-DD format. Assume the current year if not present.
- "type": (string) Must be either "expense" or "income".
- "ref_id": (string) This is a **MANDATORY** unique identifier. If a natural transaction ID (e.g., UPI Ref No, Txn ID) is in the SMS, use it directly. If not, you MUST generate a SHA256 hash of the full, original SMS body. For example, a hash looks like this: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855". Do NOT just write "sha256:..." followed by the message.
- "source": (string) Hardcode this to "sms-ai".

{feedback_examples}
---
EXAMPLE:
USER INPUT SMS: "Rs.502.00 debited from your Kotak Bank Acct for UPI-bistrobyblinkit.rzp@mairtel on 13-Jul-25. Ref No 556003726618. Not you? Call 18002090000"

YOUR REQUIRED JSON OUTPUT:
```json
{{{{
  "transactions": [
    {{{{
      "amount": 502.00,
      "currency": "INR",
      "description": "Bistro by Blinkit",
      "category": "Food",
      "merchant": "bistrobyblinkit.rzp@mairtel",
      "vendor": "Bistro by Blinkit",
      "bank": "Kotak Bank",
      "date": "2025-07-13",
      "type": "expense",
      "ref_id": "556003726618",
      "source": "sms-ai"
    }}}}
  ]
}}}}
```
---

Now, process the following messages. Ignore all non-transactional messages like OTPs, ads, or balance inquiries.
Your final response must be ONLY the raw JSON object, starting with `{{` and ending with `}}`.
The JSON object must have a single key, "transactions", which holds the array of transaction objects.
"""
    # Add contextual information to the prompt
    context_prompt = ""
    if request.context:
        current_date = request.context.get('current_date')
        start_date = request.context.get('start_date')
        end_date = request.context.get('end_date')

        if current_date:
            context_prompt += f"CONTEXT: Today's date is {current_date}. "
        if start_date and end_date:
            context_prompt += f"The user is searching between {start_date} and {end_date}. Use this as a strong hint for dates without a year, but you MUST still process and return ALL transactional messages provided."
    
    final_system_prompt = (context_prompt + "\n\n" + base_system_prompt) if context_prompt else base_system_prompt
    
    user_prompt = _build_sms_parse_prompt(request.messages)

    logger.info("Constructed prompts for OpenAI API.")
    logger.debug(f"Final System Prompt: \n{final_system_prompt}")
    logger.debug(f"Final User Prompt: \n{user_prompt}")
    
    logger.info("Sending request to OpenAI API...")

    try:
        # This is a synchronous call, so no 'await' is needed
        api_response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": final_system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.3,
        )
        raw_response = api_response.choices[0].message.content
        logger.info("Received response from OpenAI API.")
        logger.debug(f"Raw response content: {raw_response}")

        # Robust JSON extraction
        start_index = raw_response.find('{')
        end_index = raw_response.rfind('}') + 1
        if start_index == -1 or end_index == -1:
            raise ValueError("Could not find a valid JSON object in the response.")

        json_str = raw_response[start_index:end_index]
        response_data = json.loads(json_str)
        logger.info(f"Successfully parsed {len(response_data.get('transactions', []))} transactions from model response.")

        transactions = response_data.get("transactions", [])
        return {"transactions": transactions}

    except json.JSONDecodeError as e:
        logger.error(f"Failed to decode JSON from model response: {e}")
        logger.error(f"Problematic response string: {raw_response}")
        return {"error": "Failed to parse JSON from AI response.", "details": str(e)}
    except openai.APIError as e:
        logger.exception(f"OpenAI API error occurred: {e}")
        raise HTTPException(status_code=502, detail=f"The AI service provider returned an error: {e}")
    except Exception as e:
        logger.exception(f"An unexpected error occurred during SMS parsing: {e}")
        raise HTTPException(status_code=500, detail="An unexpected error occurred.")


@app.post("/categorize-transactions")
async def categorize_transactions(request: CategorizeRequest):
    logger.info(f"Received /categorize-transactions request with {len(request.transactions)} transactions.")
    try:
        # In a real app, the LLM provider would be managed more globally
        llm_provider = LlmProviderFactory.get_provider("openai")
        agent = CategorizationAgent(llm_provider)
        
        categorized_transactions = await agent.categorize_transactions(
            transactions=request.transactions,
            categories=request.categories,
        )
        
        return {"transactions": categorized_transactions}
    except Exception as e:
        logger.exception(f"Error during transaction categorization: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/predict-spending/{user_id}")
async def predict_spending(user_id: str):
    logger.info(f"Received /predict-spending request for user {user_id}.")
    if not prediction_agent:
        logger.error("Prediction agent not initialized.")
        raise HTTPException(status_code=500, detail="Prediction agent is not available.")
    try:
        prediction = await prediction_agent.generate_spending_prediction(user_id)
        return prediction
    except Exception as e:
        logger.exception(f"Error during spending prediction: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _build_sms_parse_prompt(messages: list[str]) -> str:
    prompt = """Here are some SMS messages. Extract all financial transactions.\n"""
    for i, msg in enumerate(messages, 1):
        prompt += f"{i}. {msg}\n"
    prompt += "\nReturn only a JSON array of transactions as described."
    return prompt 