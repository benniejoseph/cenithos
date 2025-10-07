from fastapi import FastAPI, HTTPException, BackgroundTasks, WebSocket, WebSocketDisconnect, Depends, Request, Response
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any, AsyncGenerator, List
import json
import re
from fastapi import HTTPException
import os
from dotenv import load_dotenv
import pathlib
import sys
from pathlib import Path
from functools import lru_cache
from pydantic import validator
import redis
import jwt
from fastapi.security import OAuth2PasswordBearer
from dotenv import load_dotenv
import schedule
import threading
import time
from contextlib import contextmanager
from core.services.model_config_service import ModelConfigService
import base64
from google.cloud import storage
import tempfile
import logging
import warnings
import backoff
from fastapi import FastAPI, HTTPException, Depends, Request, Response
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Suppress non-critical warnings for cleaner logs
warnings.filterwarnings("ignore", message="Detected filter using positional arguments")
warnings.filterwarnings("ignore", message="Unrecognized FinishReason enum value")
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from core.llm import LlmProviderFactory, GeminiProvider
import google.generativeai as genai
import asyncio
import firebase_admin
from firebase_admin import credentials, firestore, auth as firebase_auth
import uvicorn
import stripe
import requests
from core.tools.investment_file_tools import get_firestore_client
from starlette.responses import Response as StarletteResponse
import logging
from logging.config import dictConfig

# Add the project root to the Python path
sys.path.append(str(Path(__file__).parent.parent))

# Define current_dir used for .env resolution
current_dir = Path(__file__).parent

# Load environment variables from the AI service directory
env_path = current_dir / '.env'
load_dotenv(dotenv_path=env_path)

# Ensure GOOGLE_API_KEY is set for langchain-google-genai and sanitize keys
_existing_google_key = os.getenv("GOOGLE_API_KEY")
_existing_gemini_key = os.getenv("GEMINI_API_KEY")
if not _existing_google_key:
    if _existing_gemini_key:
        os.environ["GOOGLE_API_KEY"] = _existing_gemini_key.strip()
else:
    os.environ["GOOGLE_API_KEY"] = _existing_google_key.strip()
if _existing_gemini_key:
    os.environ["GEMINI_API_KEY"] = _existing_gemini_key.strip()

# Enable LangSmith tracing
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_ENDPOINT"] = "https://api.smith.langchain.com"
os.environ["LANGCHAIN_PROJECT"] = "Centhios-Financial-Agent"

# Configure matplotlib to use a writable config directory and headless backend
try:
    os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib")
    os.environ.setdefault("MPLBACKEND", "Agg")
    import os as _os
    _os.makedirs("/tmp/matplotlib", exist_ok=True)
except Exception:
    pass

# Print LangSmith configuration status
print(f"🔍 LangSmith Tracing: {os.environ.get('LANGCHAIN_TRACING_V2', 'false')}")
print(f"🔗 LangSmith Project: {os.environ.get('LANGCHAIN_PROJECT', 'not-set')}")

import logging
import firebase_admin
from firebase_admin import credentials, firestore, auth as firebase_auth
from datetime import datetime
import asyncio
# Initialize Sentry if DSN provided
# SENTRY_DSN = os.getenv("SENTRY_DSN")
# if SENTRY_DSN:
#     try:
#         sentry_sdk.init(dsn=SENTRY_DSN, traces_sample_rate=0.2)
#         print("🛰️  Sentry initialized")
#     except Exception as _:
#         print("⚠️  Sentry not initialized")
# try:
#     _dsn = os.getenv('SENTRY_DSN')
#     if _dsn:
#         sentry_sdk.init(dsn=_dsn, traces_sample_rate=0.2)
#         logger.info("✅ Sentry initialized for error tracking")
# except Exception as e:
#     logger.warning(f"Sentry initialization failed: {e}")

# Minimal OTel-style manual span (no SDK dependency)
@contextmanager
def traced_span(name: str):
    start = time.time()
    try:
        yield
    finally:
        dur_ms = int((time.time() - start) * 1000)
        try:
            logger.info(f"trace span={name} duration_ms={dur_ms}")
        except Exception:
            pass


# Import learning services
try:
    from core.agents.enhanced_transaction_agent import EnhancedTransactionAgent
    from core.learning.adaptive_learning_service import AdaptiveLearningService
    from core.learning.feedback_collector import FeedbackCollector
    LEARNING_ENABLED = True
    print("🧠 Enhanced Learning Services Loaded")
except ImportError as e:
    print(f"⚠️ Learning services not available: {e}")
    LEARNING_ENABLED = False

# Set up logging for the AI service
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("centhios-ai")

# ============================================================================
# COST TRACKING - Track Gemini API usage and costs
# ============================================================================
try:
    from core.services.cost_tracking_middleware import cost_tracker, track_gemini_response
    logger.info("💰 Cost tracking middleware loaded successfully!")
    COST_TRACKING_ENABLED = True
except Exception as e:
    logger.warning(f"⚠️  Cost tracking middleware not available: {e}")
    COST_TRACKING_ENABLED = False

# Suppress Prophet plotting errors if plotly is unavailable
logging.getLogger('prophet.plot').setLevel(logging.WARNING)

# Import LangChain components
try:
    from core.agent_service import invoke_multi_agent_system
    from core.agents.investment_ai_agent import process_investment_file_with_agent  # Use LangGraph-based specialist agent
    from core.agents.transaction_agent import process_sms_with_agent
    from core.agents.transaction_agent import create_transaction_agent_graph
    from core.agents.prediction_agent import PredictionAgent  # Enable PredictionAgent for startup initialization
    
    # Also import simple_ai_service for fallback
    from core.simple_ai_service import (
        process_sms_with_agent as simple_parse_sms,
        process_investment_file_with_agent as simple_process_investment,
        invoke_multi_agent_system as simple_invoke_multi_agent
    )
    from core.tools.investment_file_tools import preprocess_file, import_investments_to_db, update_investment_nav_data
    from core.specialist_agents.investment_file_agent import arun_investment_file_agent
    from core.llm import LlmProviderFactory
    from core.agents.categorization_agent import CategorizationAgent
    from core.simple_ai_service import SimpleAIService
except ImportError:
    # Fallback to relative imports
    from core.agent_service import invoke_multi_agent_system
    from core.agents.investment_ai_agent import process_investment_file_with_agent  # Fallback to AI-agent implementation
    from core.agents.transaction_agent import process_sms_with_agent
    from core.agents.transaction_agent import create_transaction_agent_graph
    from core.agents.prediction_agent import PredictionAgent  # Fallback import for PredictionAgent
    
    # Also import simple_ai_service for fallback
    from core.simple_ai_service import (
        process_sms_with_agent as simple_parse_sms,
        process_investment_file_with_agent as simple_process_investment,
        invoke_multi_agent_system as simple_invoke_multi_agent
    )
    from core.tools.investment_file_tools import preprocess_file, import_investments_to_db, update_investment_nav_data
    from core.specialist_agents.investment_file_agent import arun_investment_file_agent
    from core.llm import LlmProviderFactory
    from core.agents.categorization_agent import CategorizationAgent

import base64
import tempfile
class QueryRequest(BaseModel):
    user_id: str
    query: str
    # chat_history is not implemented on the client yet, but the agent supports it
    chat_history: Optional[list] = None
    use_agentic: Optional[bool] = None

    @validator('query')
    def sanitize_query(cls, v):
        return v.strip().replace('\n', ' ')  # Basic sanitization

class QueryResponse(BaseModel):
    output: Any

class SmsParseRequest(BaseModel):
    user_id: str
    messages: list[str]
    sms_ids: Optional[list[str]] = None  # ✅ NEW: SMS IDs for duplicate detection
    current_date: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    use_learning: bool = False  # Enable enhanced learning capabilities
    use_agent_graph: bool = True  # Enable LangGraph agentic workflow
    context: Optional[Dict[str, Any]] = None

class CategorizeRequest(BaseModel):
    transactions: list[dict]
    categories: list[str]

class LogoRequest(BaseModel):
    vendor_name: str

class LogoResponse(BaseModel):
    vendor_name: str
    logo_url: Optional[str]
    found_via: Optional[str] = None

class InvestmentFileRequest(BaseModel):
    user_id: str
    file_name: str
    file_content_base64: str  # Base64 encoded file content
    file_type: str  # 'excel', 'pdf', 'csv'
    broker_name: Optional[str] = None

class InvestmentAnalysisRequest(BaseModel):
    user_id: str
    investment_ids: List[str] = []  # Optional: specific investments to analyze
    include_market_research: bool = True
    include_predictions: bool = True

class FeedbackRequest(BaseModel):
    user_id: str
    query: str
    feedback: str

class SetModelRequest(BaseModel):
    user_id: str
    feature: str
    model: str

class GetUserModelSettingsResponse(BaseModel):
    models: Dict[str, str]


app = FastAPI(
    title="Centhios AI API",
    description="API for interacting with the Centhios AI financial assistant with advanced investment processing.",
    version="3.0.0",  # Version bump for investment features
    docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None,  # Disable docs in production
    redoc_url="/redoc" if os.getenv("ENVIRONMENT") != "production" else None,  # Disable redoc in production
)

# --- Health Check Endpoints for Cloud Run ---
@app.get("/health", tags=["Health Check"])
async def health_check():
    """Health check endpoint for Cloud Run and monitoring with provider status"""
    try:
        from core.services.enhanced_llm_client import EnhancedLLMClient
        client = EnhancedLLMClient()
        provider_status = client.get_provider_status()
    except Exception as e:
        provider_status = {"error": str(e)}
    
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "3.0.0",
        "service": "centhios-ai-service",
        "providers": provider_status,
        "langchain_api_key_set": bool(os.getenv("LANGCHAIN_API_KEY")),
        "sentry_dsn_set": bool(os.getenv("SENTRY_DSN")),
        "gemini_api_key_set": bool(os.getenv("GEMINI_API_KEY"))
    }

@app.get("/health/liveness", tags=["Health Check"])
async def liveness_check():
    """Liveness probe for Cloud Run - simple check that app is running"""
    return {"status": "alive", "timestamp": datetime.now().isoformat()}

@app.get("/health/readiness", tags=["Health Check"])
async def readiness_check():
    """Readiness probe for Cloud Run - check if app can serve traffic"""
    # Simple check - just verify app is initialized
    return {
        "status": "ready", 
        "timestamp": datetime.now().isoformat(),
        "version": "3.0.0"
    }

@app.get("/health-check")
async def new_health_check():
    """A new, separate health check endpoint for debugging."""
    return {"status": "ok", "timestamp": datetime.now().isoformat()}

# --- Agentic RAG Endpoint ---
@app.post("/agentic/query")
async def agentic_query(req: Request):
    try:
        body = await req.json()
    except Exception:
        body = {}
    query = body.get("query") or body.get("q") or ""
    user_id = body.get("user_id")
    context = {"user_id": user_id}
    try:
        from core.agentic.orchestrator import run_agentic_pipeline
        result = run_agentic_pipeline(query, context)
        return result
    except Exception as e:
        return {"status": "error", "error": str(e)}

# --- App Globals ---
# Use regular OpenAI client for synchronous operations - DISABLED due to proxies issue
# client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
prediction_agent = None  # Disabled due to LangChain compatibility issues
db = None

# Lazy initialization for Cloud Run optimization
@lru_cache(maxsize=1)
def get_firestore_client():
    """Lazy initialization of Firestore to avoid initialization issues."""
    if 'pytest' in sys.modules:
        # Use a mock client for testing to avoid actual DB calls
        try:
            from unittest.mock import MagicMock
            return MagicMock()
        except ImportError:
            from unittest.mock import MagicMock
            return MagicMock()
    
    try:
        global db
        if db is not None:
            return db
        
        try:
            from firebase_admin import credentials
            # Initialize the Firebase App once
            if not firebase_admin._apps:
                # Check if we're running locally with emulator
                if os.getenv("FIRESTORE_EMULATOR_HOST"):
                    logger.info("🔧 Connecting to Firestore emulator")
                    firebase_admin.initialize_app()
                else:
                    # Production - prefer Cloud Run default service account
                    environment = os.getenv("ENVIRONMENT", "development")
                    if environment == "production":
                        # Cloud Run production environment - use default service account
                        logger.info("🔑 Using Cloud Run default service account")
                        firebase_admin.initialize_app()
                    else:
                        # Development environment - use local service account key
                        key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or str(Path(__file__).parent / "serviceAccountKey.json")
                        if os.path.exists(key_path):
                            cred = credentials.Certificate(key_path)
                            logger.info(f"🔑 Using service account: {key_path}")
                            firebase_admin.initialize_app(cred)
                        else:
                            logger.info("🔑 Using default credentials (no service account key found)")
                            firebase_admin.initialize_app()
            
            logger.info("Firebase Admin SDK initialized successfully.")
            db = firestore.client()
            logger.info("Firestore client initialized successfully.")
            return db
            
        except ValueError as e:
            # Skip duplicate initialization on auto-reload
            if "already exists" in str(e):
                logger.debug("Firebase app already initialized, skipping.")
                db = firestore.client()
                logger.info("Firestore client initialized successfully (post-skip).")
                return db
            else:
                logger.error(f"Firebase init error: {e}")
                raise e
        except Exception as e:
            logger.error(f"Firebase init failed: {e}")
            raise e

    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
        db = None
        raise e

@lru_cache(maxsize=128)
def cached_invoke(user_id: str, query: str):
    return invoke_multi_agent_system(user_id, query)

async def stream_query_response(query_request: QueryRequest) -> AsyncGenerator[str, None]:
    """
    Calls the agent and streams the response for a real-time conversational UI.
    """
    logger.info(f"Streaming agent execution for user '{query_request.user_id}' with query: '{query_request.query}'")
    
    # Temporarily using direct OpenAI instead of LangGraph due to compatibility issues
    try:
        result = cached_invoke(query_request.user_id, query_request.query)
        
        # Stream the response
        yield json.dumps({
            "type": "agent_start",
            "content": "Processing your request..."
        }) + "\n"
        
        yield json.dumps({
            "type": "agent_response", 
            "content": result.get("output", "No response available")
        }) + "\n"
        
        yield json.dumps({
            "type": "agent_finish",
            "content": "Request completed"
        }) + "\n"

    except Exception as e:
        logger.error(f"Error in stream query: {e}")
        yield json.dumps({
            "type": "error",
            "content": f"Error processing request: {str(e)}"
        }) + "\n"


# --- API Endpoints ---
# @app.on_event("startup")  # Duplicate, remove this registration
# async def on_startup():
#     global prediction_agent, db
#     logger.info("Centhios AI API is starting up.")
#     logger.info(f"OPENAI_API_KEY loaded: {'Yes' if os.getenv('OPENAI_API_KEY') else 'No'}")
#     
#     # Initialize Firebase Admin SDK and Firestore client
#     try:
#         from firebase_admin import credentials
#         # Initialize the Firebase App once
#         if not firebase_admin._apps:
#             key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or str(Path(__file__).parent / "serviceAccountKey.json")
#             cred = credentials.Certificate(key_path)
#             firebase_admin.initialize_app(cred)
#         logger.info("Firebase Admin SDK initialized successfully.")
#         # Initialize Firestore client
#         db = firestore.client()
#         logger.info("Firestore client initialized successfully.")
#     except ValueError as e:
#         # Skip duplicate initialization on auto-reload
#         if "already exists" in str(e):
#             logger.debug("Firebase app already initialized, skipping.")
#             db = firestore.client()
#             logger.info("Firestore client initialized successfully (post-skip).")
#         else:
#             logger.error(f"Firebase init error: {e}")
#             # Optionally fallback to a mock or exit
#     except Exception as e:
#         logger.error(f"Firebase init failed: {e}. Using mock.")
#         from ai.core.firestore_mock import FirestoreMockClient
#         db = FirestoreMockClient()

#     prediction_agent = PredictionAgent(firestore_client=db)  # Enable
#     logger.info("PredictionAgent enabled and initialized.")
#     
#     logger.info("AI Service startup complete (using simple service mode)")
#     logger.info("🚀 AI Service ready to handle requests")


@app.post("/query", response_model=QueryResponse)
async def handle_query(query_request: QueryRequest, req: Request):
    """Receives a user query and invokes the multi-agent system. Verifies Firebase ID token."""
    # Verify Firebase ID token from Authorization header
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != query_request.user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    logger.info(f"Invoking multi-agent system for user '{query_request.user_id}' with query: '{query_request.query}'")

    # Rate limiting per user
    try:
        from core.services.rate_limit_service import rate_limiter
        if not rate_limiter.allow(query_request.user_id):
            raise HTTPException(status_code=429, detail="Too many requests. Please try again later.")
    except HTTPException:
        raise
    except Exception:
        pass

    # Lightweight response cache (in-memory)
    try:
        from core.services.cache_service import response_cache
        cache_key = f"query:{query_request.user_id}:{query_request.query}"
        cached = response_cache.get(cache_key)
    except Exception:
        cached = None

    if cached is not None:
        return QueryResponse(output=cached)

    # Decide whether to use the Agentic RAG pipeline
    try:
        agentic_default = (os.getenv("AGENTIC_DEFAULT", "false").lower() == "true")
        use_agentic = query_request.use_agentic if query_request.use_agentic is not None else agentic_default
        if use_agentic:
            try:
                from core.agentic.orchestrator import run_agentic_pipeline
                agentic_result = run_agentic_pipeline(
                    query=query_request.query,
                    context={"user_id": query_request.user_id}
                )
                output = agentic_result
                # Optional: cache lightweight summaries only; skip caching full traces
                return QueryResponse(output=output)
            except Exception as e:
                logger.warning(f"Agentic pipeline failed, falling back to classic flow: {e}")

        # Classic flow (fallback)
        with traced_span("invoke_multi_agent_system"):
            result = cached_invoke(
                user_id=query_request.user_id,
                query=query_request.query,
            )
        output = result.get("output")
        try:
            from core.services.cache_service import response_cache
            if output:
                response_cache.set(cache_key, output, ttl_seconds=300)
        except Exception:
            pass
        return QueryResponse(output=output)
    except Exception as e:
        logger.exception(f"An error occurred while invoking the agent: {e}")
        raise HTTPException(status_code=500, detail="An error occurred while processing your query.")

@app.post("/query/stream")
async def handle_stream_query(query_request: QueryRequest, req: Request):
    """
    Receives a user query and streams the response from the agent for conversational UI.
    """
    # Verify Firebase ID token
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != query_request.user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    return StreamingResponse(stream_query_response(query_request), media_type="application/x-ndjson")

@app.get("/")
def read_root():
    return {"message": "Centhios AI API v2 is running."}

@app.get("/models")
async def get_models():
    """
    Returns a curated list of available Gemini models.
    """
    logger.info("Received request for /models")
    # This now returns a static list of known-good Gemini models
    # as we don't need to fetch them from an API endpoint anymore.
    gemini_models = [
        "gemini-2.5-pro",
        "gemini-2.5-pro-latest",
        "gemini-2.5-pro",
    ]
    logger.info(f"Curated list of Gemini models returned to client: {gemini_models}")
    return gemini_models


@app.post("/settings/models")
async def set_user_model(request: SetModelRequest, req: Request):
    """Save per-user model selection for a feature (stored in Firestore)."""
    # Auth: user must match token uid
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != request.user_id:
            raise HTTPException(status_code=403, detail="Forbidden")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    ok = ModelConfigService.set_user_model(request.user_id, request.feature, request.model)
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid model or save failed")
    return {"success": True}


@app.get("/settings/models/{user_id}", response_model=GetUserModelSettingsResponse)
async def get_user_models(user_id: str, req: Request):
    # Auth: caller must be same user or have admin
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != user_id and not decoded.get('admin', False):
            raise HTTPException(status_code=403, detail="Forbidden")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    models = ModelConfigService.get_user_settings(user_id)
    return {"models": models}


@app.post("/reset-context")
def reset_context(request: Dict[str, str]):
    """Testing endpoint to clear a user's context."""
    user_id = request.get("user_id")
    if user_id:
        # The original code had orchestrator.context_manager.clear_user_context(user_id)
        # Assuming orchestrator is not defined in this file, this line is removed.
        # If orchestrator is meant to be defined elsewhere, it needs to be added.
        # For now, this endpoint will not function as intended without orchestrator.
        logger.warning(f"Attempted to reset context for user {user_id}, but orchestrator is not defined.")
        return {"status": "context reset attempted (orchestrator not available)"}
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

@app.post("/parse-investment-messages")
async def parse_investment_messages(request: SmsParseRequest):
    """
    Parses SMS/Email messages specifically for investment-related activities.
    Enhanced with email agent support and comprehensive logging.
    """
    user_id = request.user_id
    messages = request.messages
    logger.info(f" INVESTMENT: Received /parse-investment-messages request for user {user_id} with {len(messages)} messages.")
    
    all_investment_activities = []
    
    # Get user categories for context
    logger.info(f" INVESTMENT: Loading user categories for {user_id}")
    categories = get_user_categories(db, user_id)
    logger.info(f" INVESTMENT: Loaded {len(categories)} user categories")
    
    # Prepare context for agents
    context = {
        'ai_model': 'gemini-2.5-pro',
        'categories': categories,  # categories is already a list of strings
        'user_id': user_id
    }
    
    # Process messages in optimized batches
    batch_size = 25  # Reduced batch size for better error handling
    total_messages = len(messages)
    logger.info(f" INVESTMENT: Processing {total_messages} messages in batches of {batch_size}")
    
    for batch_idx in range(0, total_messages, batch_size):
        batch_end = min(batch_idx + batch_size, total_messages)
        current_batch = messages[batch_idx:batch_end]
        batch_num = (batch_idx // batch_size) + 1
        total_batches = (total_messages + batch_size - 1) // batch_size
        
        logger.info(f" INVESTMENT: Processing batch {batch_num}/{total_batches} ({len(current_batch)} messages)...")
        
        for msg_idx, message in enumerate(current_batch, start=batch_idx + 1):
            try:
                logger.info(f" Processing message {msg_idx}/{total_messages}...")
                
                # Check if it's an email or SMS format
                if any(email_indicator in message.lower() for email_indicator in 
                       ['subject:', 'from:', 'to:', 'date:', '@', 'html', 'doctype']):
                    logger.info(" Detected email format, using email agent...")
                    
                    # Process with email agent
                    result = await process_investment_file_with_agent(message, user_id, context)
                    all_investment_activities.extend(result.get('investment_activities', []))
                    
                    if result.get('errors'):
                        logger.warning(f" Email processing errors: {result['errors']}")
                    
                else:
                    logger.info(" Detected SMS format, using SMS agent...")
                    
                    # Process with SMS/Transaction agent
                    # The original code had create_transaction_agent_graph()
                    # Assuming this function is no longer needed or has been refactored
                    # For now, we'll keep the structure but note the potential issue
                    # If create_transaction_agent_graph is meant to be re-introduced,
                    # it needs to be defined or imported.
                    # For now, we'll just log a placeholder message.
                    logger.warning(" create_transaction_agent_graph is not defined. Skipping SMS processing.")
                    # If create_transaction_agent_graph was intended to be re-introduced,
                    # it would look like this:
                    # from ai.core.agents.transaction_agent import create_transaction_agent_graph
                    # agent = create_transaction_agent_graph()
                    # initial_state: TransactionAgentState = { ... }
                    # final_state = agent.invoke(initial_state)
                    # ... process transactions ...
                    continue # Skip processing if agent is not available
                
                # Rate limiting to prevent API overload
                if msg_idx % 10 == 0:
                    await asyncio.sleep(0.5)  # Brief pause every 10 messages
                    
            except Exception as e:
                logger.error(f" Error processing message {msg_idx}: {e}")
                continue
        
        logger.info(f" INVESTMENT: Batch {batch_num} complete - {len(all_investment_activities)} total activities so far")
        
        # Brief pause between batches
        if batch_num < total_batches:
            await asyncio.sleep(1)
    
    logger.info(f" INVESTMENT: Successfully parsed {len(all_investment_activities)} investment activities")
    return {"investment_activities": all_investment_activities}

async def get_investment_parsing_patterns():
    """Define patterns for different types of investment messages"""
    return {
        "mutual_fund_sip": [
            r"SIP.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Systematic Investment.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Monthly investment.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "mutual_fund_purchase": [
            r"Purchase.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Invested.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Amount invested.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "stock_buy": [
            r"(?:You have )?bought.*?(\d+).*?shares?.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Purchase.*?(\d+).*?(?:equity|shares?).*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "stock_sell": [
            r"(?:You have )?sold.*?(\d+).*?shares?.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Sale.*?(\d+).*?(?:equity|shares?).*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "dividend": [
            r"Dividend.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Dividend credit.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "maturity": [
            r"(?:matured|maturity).*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"(?:FD|Fixed Deposit).*?matured.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ],
        "interest_credit": [
            r"Interest.*?credited.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)",
            r"Interest.*?(?:Rs\.?|INR)\s*(\d+(?:,\d+)*(?:\.\d+)?)"
        ]
    }

async def parse_single_investment_message(message: str, user_id: str, patterns: dict):
    """Parse a single message for investment activities using AI and patterns"""
    
    # First, use pattern matching for quick detection
    detected_type = None
    extracted_data = {}
    
    for activity_type, pattern_list in patterns.items():
        for pattern in pattern_list:
            import re
            match = re.search(pattern, message, re.IGNORECASE)
            if match:
                detected_type = activity_type
                if activity_type in ["stock_buy", "stock_sell"]:
                    extracted_data = {
                        "quantity": match.group(1) if len(match.groups()) >= 1 else None,
                        "amount": match.group(2) if len(match.groups()) >= 2 else None
                    }
                else:
                    extracted_data = {
                        "amount": match.group(1) if match.groups() else None
                    }
                break
        if detected_type:
            break
    
    if not detected_type:
        return []  # No investment activity detected
    
    # Use AI to extract detailed information
    ai_extracted = await extract_investment_details_with_ai(message, detected_type, user_id)
    
    # Combine pattern-based and AI-based extraction
    investment_activity = {
        **extracted_data,
        **ai_extracted,
        "type": detected_type,
        "raw_message": message,
            "user_id": user_id,
        "parsed_at": datetime.now().isoformat(),
        "confidence": ai_extracted.get("confidence", 0.8)
    }
    
    return [investment_activity]

async def extract_investment_details_with_ai(message: str, detected_type: str, user_id: str):
    """Use AI to extract detailed investment information from the message"""
    
    from langchain_google_genai import ChatGoogleGenerativeAI
    from langchain_core.prompts import ChatPromptTemplate
    model_name = ModelConfigService.get_model(user_id, 'investment', default_model='gemini-2.5-pro')
    llm = ChatGoogleGenerativeAI(model=model_name, temperature=0.1)
    
    # Create a specialized prompt for investment parsing
    prompt = ChatPromptTemplate.from_messages([
        ("system", """You are an expert at parsing investment-related SMS and email messages.
        
INVESTMENT TYPES:
- mutual_fund_sip: Regular SIP investments
- mutual_fund_purchase: One-time mutual fund purchases  
- stock_buy: Stock purchase transactions
- stock_sell: Stock sale transactions
- dividend: Dividend payments received
- maturity: Investment maturity (FD, bonds, etc.)
- interest_credit: Interest payments

EXTRACT these fields in JSON format:
{
  "investment_name": "Name of the fund/stock/investment",
  "symbol": "Stock symbol or fund code if mentioned", 
  "amount": 123.45,
  "quantity": 10,
  "price_per_unit": 12.34,
  "folio_number": "Portfolio/folio number if mentioned",
  "transaction_date": "YYYY-MM-DD",
  "broker": "Broker/AMC name (Groww, Zerodha, HDFC, etc.)",
  "transaction_id": "Reference number if available",
  "confidence": 0.95
}

Return ONLY valid JSON. If any field is not available, use null."""),
        ("user", "Message Type: {message_type}\n\nMessage: {message}")
    ])
    
    try:
        chain = prompt | llm
        response = await chain.ainvoke({
            "message_type": detected_type,
            "message": message
        })
        
                # Parse the JSON response
        import json
        result = json.loads(response.content)
        return result

    except Exception as e:
        logger.error(f"AI parsing failed for investment message: {e}")
        return {"confidence": 0.5}

@app.post("/parse-sms")
async def parse_sms_messages(request: SmsParseRequest, req: Request):
    """
    Parse SMS messages for financial transactions using AI Agent.
    """
    user_id = request.user_id
    messages = request.messages
    sms_ids = request.sms_ids or []  # ✅ NEW: Get SMS IDs for duplicate detection
    
    # Debug: Log the request details
    logger.info(f"🔍 SMS: Received request with {len(messages)} messages")
    logger.info(f"🔍 SMS: SMS IDs provided: {len(sms_ids)}")
    if sms_ids:
        logger.info(f"🔍 SMS: First SMS ID: {sms_ids[0]}")
    logger.info(f"🔍 SMS: Request attributes: use_learning={getattr(request, 'use_learning', 'NOT_SET')}, use_agent_graph={getattr(request, 'use_agent_graph', 'NOT_SET')}")
    logger.info(f"🔍 SMS: Request dict: {request.dict()}")
    
    logger.info(f"📱 SMS: Received SMS parsing request for user {user_id}")
    logger.info(f"📱 SMS: Processing {len(messages)} messages")
    
    # Verify Firebase ID token
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    try:
        # Determine which agentic workflow to use based on request flags
        use_learning = getattr(request, "use_learning", False)
        use_agent_graph = getattr(request, "use_agent_graph", True)  # Default to agent graph
        
        logger.info(f"🔍 SMS: use_learning={use_learning}, use_agent_graph={use_agent_graph}")
        logger.info(f"🔍 SMS: LEARNING_ENABLED={LEARNING_ENABLED}")
        
        if use_learning and LEARNING_ENABLED:
            logger.info("🧠 Using Enhanced Transaction Agent with Adaptive Learning")
            
            # Pass context including categories and current_date
            result = await enhanced_agent.process_sms_with_learning(
                messages=messages,
                user_id=user_id,
                context=request.context if hasattr(request, 'context') and request.context else {}
            )
            
            # Convert to compatible format and add SMS IDs
            parsed_transactions = []
            for idx, transaction in enumerate(result["transactions"]):
                trans_dict = transaction.__dict__ if hasattr(transaction, '__dict__') else transaction
                # ✅ NEW: Add SMS ID as ref_id if available
                if idx < len(sms_ids) and sms_ids[idx]:
                    trans_dict['ref_id'] = sms_ids[idx]
                    logger.info(f"✅ Assigned SMS ID {sms_ids[idx]} to transaction {idx}")
                parsed_transactions.append(trans_dict)
            
            logger.info(f"✅ Enhanced Learning Agent processed {len(parsed_transactions)} transactions")
            
            # ============================================================================
            # COST TRACKING - Record Gemini API usage
            # ============================================================================
            if COST_TRACKING_ENABLED:
                try:
                    # Estimate token usage based on message count and length
                    total_message_length = sum(len(msg) for msg in messages)
                    estimated_input_tokens = int(total_message_length / 4) + 500  # ~4 chars per token + system prompt
                    estimated_output_tokens = len(parsed_transactions) * 100  # ~100 tokens per transaction
                    
                    cost_tracker.record_usage(
                        model_name="gemini-2.5-pro",
                        input_tokens=estimated_input_tokens,
                        output_tokens=estimated_output_tokens,
                        user_id=user_id,
                        request_type="sms_parsing_learning"
                    )
                except Exception as e:
                    logger.error(f"❌ Failed to record cost: {e}")
            
            # ============================================================================
            # TRIGGER NOTIFICATIONS FOR TRANSACTIONS
            # ============================================================================
            try:
                from core.notifications.notification_triggers_integration import notify_transaction_created
                
                logger.info(f"🔔 Triggering notifications for {len(parsed_transactions)} transactions")
                
                for trans in parsed_transactions:
                    try:
                        # Trigger notification for each transaction
                        await notify_transaction_created(
                            user_id=user_id,
                            transaction=trans
                        )
                    except Exception as e:
                        logger.error(f"❌ Failed to trigger notification for transaction: {e}")
                        # Don't fail the whole request if notification fails
                        continue
                
                logger.info(f"✅ Notification triggers completed")
                
            except Exception as e:
                logger.warning(f"⚠️ Notification system not available: {e}")
                # Continue even if notifications fail
            
            return {
                "status": "success",
                "user_id": user_id,
                "transactions": parsed_transactions,
                "bank_balance": [],  # Enhanced agent doesn't separate these yet
                "investment_activities": [],
                "total_transactions": len(parsed_transactions),
                "learning_applied": True,
                "learning_context": result.get("learning_context_applied", {}),
                "processing_results": result.get("processing_results", []),
                "agent_workflow": "enhanced_learning"
            }
        
        elif use_agent_graph:
            # Process SMS messages through the standard Transaction Agent graph
            from core.agents.transaction_agent import create_transaction_agent_graph
            
            logger.info("🤖 Using LangGraph Transaction Agent for multi-stage SMS analysis")
            logger.info(f"🤖 Processing {len(messages)} messages")
            
            agent = create_transaction_agent_graph()
            # Build initial state for the graph
            initial_state = {
                "raw_text": "\n".join(messages),
                "user_id": user_id,
                "context": {
                    "ai_model": os.getenv("GEMINI_MODEL", "gemini-2.5-pro"),
                    "categories": get_user_categories(db, user_id),
                    "db": db
                },
                "transactions": [],
                "needs_review": False,
                "messages": []
            }
            
            final_state = agent.invoke(initial_state)
            parsed_transactions = []
            for idx, t in enumerate(final_state.get('transactions', [])):
                if isinstance(t, str):
                    print(f"⚠️ Warning: Transaction is a string, skipping: {t}")
                    continue
                elif hasattr(t, 'dict'):
                    trans_dict = t.dict()
                elif isinstance(t, dict):
                    trans_dict = t
                else:
                    print(f"⚠️ Warning: Unknown transaction type {type(t)}, skipping: {t}")
                    continue
                
                # ✅ NEW: Add SMS ID as ref_id if available
                if idx < len(sms_ids) and sms_ids[idx]:
                    trans_dict['ref_id'] = sms_ids[idx]
                    logger.info(f"✅ Assigned SMS ID {sms_ids[idx]} to transaction {idx}")
                
                parsed_transactions.append(trans_dict)
            
            bank_balance = final_state.get('bank_balance', [])
            investments = final_state.get('investment_activities', [])
            
            logger.info(f"✅ LangGraph Transaction Agent parsed {len(parsed_transactions)} transactions")
            
            # ============================================================================
            # COST TRACKING - Record Gemini API usage
            # ============================================================================
            if COST_TRACKING_ENABLED:
                try:
                    # Estimate token usage based on message count and length
                    total_message_length = sum(len(msg) for msg in messages)
                    estimated_input_tokens = int(total_message_length / 4) + 700  # ~4 chars per token + larger system prompt
                    estimated_output_tokens = len(parsed_transactions) * 150  # ~150 tokens per transaction (more detailed)
                    
                    cost_tracker.record_usage(
                        model_name="gemini-2.5-pro",
                        input_tokens=estimated_input_tokens,
                        output_tokens=estimated_output_tokens,
                        user_id=user_id,
                        request_type="sms_parsing_langgraph"
                    )
                except Exception as e:
                    logger.error(f"❌ Failed to record cost: {e}")
            
            # ============================================================================
            # TRIGGER NOTIFICATIONS FOR TRANSACTIONS
            # ============================================================================
            try:
                from core.notifications.notification_triggers_integration import notify_transaction_created
                
                logger.info(f"🔔 Triggering notifications for {len(parsed_transactions)} transactions")
                
                for trans in parsed_transactions:
                    try:
                        # Trigger notification for each transaction
                        await notify_transaction_created(
                            user_id=user_id,
                            transaction=trans
                        )
                    except Exception as e:
                        logger.error(f"❌ Failed to trigger notification for transaction: {e}")
                        # Don't fail the whole request if notification fails
                        continue
                
                logger.info(f"✅ Notification triggers completed")
                
            except Exception as e:
                logger.warning(f"⚠️ Notification system not available: {e}")
                # Continue even if notifications fail
            
            # Return structured data for UI to display and select
            return {
                "status": "success",
                "transactions": parsed_transactions,
                "bank_balance": bank_balance,
                "investment_activities": investments,
                "logs": final_state.get('messages', []),
                "success": True,
                "processed_count": len(messages),
                "extracted_count": len(parsed_transactions),
                "total_transactions": len(parsed_transactions),
                "agent_workflow": "langgraph_standard",
                "workflow_stages": ["ingest", "parse", "enrich_logo", "detect_subscriptions", "review_gate", "budget_awareness", "finalize"],
                "needs_review": final_state.get('needs_review', False)
            }
        
        else:
            # Fallback to simple parsing (non-agentic)
            logger.warning("⚠️ Using simple parsing - no agentic workflow enabled")
            logger.warning(f"⚠️ use_learning={use_learning}, use_agent_graph={use_agent_graph}, LEARNING_ENABLED={LEARNING_ENABLED}")
            return {
                "transactions": [],
                "bank_balance": [],
                "investment_activities": [],
                "logs": ["Simple parsing used - enable agent workflow for better results"],
                "success": True,
                "processed_count": len(messages),
                "extracted_count": 0,
                "agent_workflow": "simple_fallback"
            }

    except Exception as e:
        logger.error(f"❌ SMS: Parsing failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"SMS parsing failed: {str(e)}")

def get_user_categories(db_client, user_id: str) -> List[str]:
    """Helper function to fetch user categories from Firestore."""
    default_categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Health", "Groceries", "Other"]
    try:
        if not db_client:
            return default_categories
        user_doc_ref = db_client.collection('users').document(user_id)
        user_doc = user_doc_ref.get()  # Firebase Admin SDK is synchronous
        if user_doc.exists:
            user_data = user_doc.to_dict()
            custom_categories = user_data.get('customCategories', [])
            if custom_categories:
                logger.info(f"Found {len(custom_categories)} custom categories for user {user_id}")
                return default_categories + custom_categories
    except Exception as e:
        logger.exception(f"Could not fetch custom categories for user {user_id}: {e}")
    
    return default_categories

@app.post("/categorize-transactions")
async def categorize_transactions(request: CategorizeRequest, req: Request):
    logger.info(f"Received /categorize-transactions request with {len(request.transactions)} transactions.")
    # Verify Firebase ID token
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    try:
        # In a real app, the LLM provider would be managed more globally
        # Model selection for categorization
        # LlmProviderFactory currently wraps OpenAI; model routed in agent if needed
        llm_provider = LlmProviderFactory.get_provider("gemini")
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

@app.post("/get-logo", response_model=LogoResponse)
async def get_logo(request: LogoRequest):
    """
    Fetches logo URL for a given vendor name.
    Useful for testing the logo fetching functionality.
    """
    logger.info(f"Received logo request for vendor: '{request.vendor_name}'")
    
    try:
        # The original code had get_vendor_logo_url(request.vendor_name)
        # Assuming this function is no longer needed or has been refactored
        # For now, we'll just return a placeholder or raise an error.
        # If get_vendor_logo_url is meant to be re-introduced, it needs to be defined or imported.
        # For now, this endpoint will not function as intended without get_vendor_logo_url.
        logger.warning(" get_vendor_logo_url is not defined. Returning placeholder.")
        return LogoResponse(
            vendor_name=request.vendor_name,
            logo_url=None,
            found_via="placeholder"
        )
    except Exception as e:
        logger.exception(f"Error fetching logo for vendor '{request.vendor_name}': {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch logo")

@app.get("/logo-stats")
async def get_logo_stats():
    """
    Returns statistics about the logo cache for debugging.
    """
    # The original code had _logo_cache and _cache_expiry
    # Assuming these are no longer needed or have been refactored
    # For now, we'll just return a placeholder.
    logger.warning(" _logo_cache and _cache_expiry are not defined. Returning placeholder.")
    return {
        "total_cached_vendors": 0,
        "valid_cache_entries": 0,
        "expired_entries": 0,
        "cache_hit_vendors": []
    }


def _build_sms_parse_prompt(messages: list[str]) -> str:
    prompt = """Here are some SMS messages. Extract all financial transactions.\n"""
    for i, msg in enumerate(messages, 1):
        prompt += f"{i}. {msg}\n"
    prompt += "\nReturn only a JSON array of transactions as described."
    return prompt 

@app.post("/process-investment-file")
async def process_investment_file(request: InvestmentFileRequest):
    """
    Process uploaded investment files (Excel/PDF/CSV) using the refactored AI Agent.
    This endpoint accepts a file, processes it through the investment agent,
    and returns the extracted structured data.
    """
    logger.info(f"📁 Received investment file processing request for user {request.user_id}")
    logger.info(f"   - File: {request.file_name}, Type: {request.file_type}, Broker: {request.broker_name}")

    try:
        # The agent now handles all processing, including base64 decoding.
        # We just need to pass the data to it.
        result = await process_investment_file_with_agent(
            file_content=request.file_content_base64,
            file_type=request.file_type.lower(),
            user_id=request.user_id,
            broker_name=request.broker_name,
            context={'file_name': request.file_name}
        )
        
        log_message = "✅ Investment file processing complete."
        if result.get("errors"):
            log_message = "⚠️ Investment file processing completed with errors."
            
        logger.info(log_message)
        logger.info(f"   - Investments Parsed: {len(result.get('investments', []))}")
        logger.info(f"   - Transactions Parsed: {len(result.get('transactions', []))}")
        logger.info(f"   - Errors: {len(result.get('errors', []))}")

        return result

    except Exception as e:
        logger.error(f"❌ Unhandled exception in /process-investment-file endpoint: {e}", exc_info=True)
        # Return a standard error response
        return {
            "success": False,
            "error": "An unexpected error occurred on the server.",
            "investments": [],
            "transactions": [],
            "errors": [str(e)],
            "processing_stage": "failed"
        }

@app.post("/analyze-investment-portfolio")
async def analyze_investment_portfolio(request: InvestmentAnalysisRequest):
    """
    Perform comprehensive investment portfolio analysis with AI.
    Includes performance analysis, risk assessment, and optimization recommendations.
    """
    user_id = request.user_id
    investment_ids = request.investment_ids
    include_market_research = request.include_market_research
    include_predictions = request.include_predictions
    
    logger.info(f"📊 PORTFOLIO ANALYSIS: Starting analysis for user {user_id}")
    logger.info(f"📊 PORTFOLIO ANALYSIS: Investment IDs: {investment_ids}")
    logger.info(f"📊 PORTFOLIO ANALYSIS: Include market research: {include_market_research}")
    logger.info(f"📊 PORTFOLIO ANALYSIS: Include predictions: {include_predictions}")
    
    try:
        # Get user's investment data from database
        # TODO: Implement database retrieval logic
        user_investments = []  # Placeholder
        
        # Create Investment AI Agent for analysis
        # The original code had create_investment_agent_graph()
        # Assuming this function is no longer needed or has been refactored
        # For now, we'll just log a placeholder message.
        logger.warning(" create_investment_agent_graph is not defined. Skipping portfolio analysis.")
        # If create_investment_agent_graph was intended to be re-introduced,
        # it would look like this:
        # from ai.core.agents.investment_ai_agent import create_investment_agent_graph
        # agent = create_investment_agent_graph()
        # initial_state = { ... }
        # final_state = agent.invoke(initial_state)
        # ... return final_state ...
        return {
            "success": False,
            "error": "Portfolio analysis functionality is currently unavailable.",
            "portfolio_analysis": None,
            "market_insights": [],
            "recommendations": [],
            "errors": ["Portfolio analysis functionality is currently unavailable."]
        }
        
    except Exception as e:
        logger.error(f"❌ PORTFOLIO ANALYSIS: Analysis failed: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "portfolio_analysis": None,
            "market_insights": [],
            "recommendations": [],
            "errors": [str(e)]
        }

@app.post("/investment-market-research")
async def investment_market_research(request: BaseModel = None):
    """
    Get AI-powered market research and investment opportunities.
    Provides current market insights and investment recommendations.
    """
    logger.info(f"🌐 MARKET RESEARCH: Starting market analysis...")
    
    try:
        # Create comprehensive market research prompt
        # OpenAI removed - using Google Gemini
        from langchain_core.prompts import ChatPromptTemplate
        # Select model per user setting if request has user_id
        model_name = 'gemini-2.5-pro'
        try:
            uid = getattr(request, 'user_id', None) if request else None
            model_name = ModelConfigService.get_model(uid, 'market_research', default_model=model_name)
        except Exception:
            pass
        # Use unified LLM client where possible
        from core.services.llm_client import LLMClient
        llm_client = LLMClient(default_model=model_name, timeout=30, max_retries=2)
        market_research_prompt = ChatPromptTemplate.from_messages([
            ("system", """You are an expert investment advisor specializing in Indian financial markets.
            
            Provide current market analysis covering:
            
            1. EQUITY MARKETS:
            - Large cap, mid cap, small cap opportunities
            - Sector analysis (IT, Banking, Pharma, Auto, etc.)
            - Market outlook and key drivers
            
            2. DEBT INSTRUMENTS:
            - Government bonds and yields
            - Corporate bonds
            - Fixed deposits and small savings
            
            3. ALTERNATIVE INVESTMENTS:
            - Gold and precious metals
            - REITs and InvITs
            - International diversification
            
            4. EMERGING OPPORTUNITIES:
            - ESG investments
            - Digital assets (if appropriate)
            - New age sectors
            
            5. RISK FACTORS:
            - Global economic conditions
            - Domestic policy impacts
            - Inflation and interest rate outlook
            
            Provide specific, actionable insights for Indian investors with different risk profiles.
            Include current market trends and data-driven recommendations."""),
            ("user", "Provide comprehensive market research and investment opportunities for the current market scenario.")
        ])
        
        # Get market research
        # Render the prompt and call the LLM client
        rendered = market_research_prompt.format_messages({})
        mapped = []
        for msg in rendered:
            role = getattr(msg, 'type', 'user')
            content = getattr(msg, 'content', '')
            mapped.append({"role": "system" if role == "system" else "user", "content": content})

        data = await llm_client.achat(mapped, model=model_name, temperature=0.3, max_tokens=800, user_id=uid or "system", request_type=cost_tracking_service.RequestType.INVESTMENT_ANALYSIS)  # type: ignore
        class _Resp:
            content = data.get("content", "")
        response = _Resp()
        
        # Parse the response into structured data
        market_analysis = {
            "generated_at": datetime.now().isoformat(),
            "market_outlook": response.content,
            "key_recommendations": _extract_key_recommendations(response.content),
            "risk_factors": _extract_risk_factors(response.content),
            "opportunities": _extract_opportunities(response.content)
        }
        
        logger.info(f"✅ MARKET RESEARCH: Research complete")
        
        return {
            "success": True,
            "market_analysis": market_analysis,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ MARKET RESEARCH: Research failed: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "market_analysis": None,
            "timestamp": datetime.now().isoformat()
        }

@app.post("/investment-calculator")
async def investment_calculator(request: Request):
    """Run server-side investment calculators by type with provided parameters."""
    # Auth
    auth_header = request.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        fb_auth.verify_id_token(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    payload = await request.json()
    calc_type = payload.get("type")
    params = payload.get("params", {})

    from core.tools.financial_calculators import (
        sip_future_value,
        lumpsum_future_value,
        cagr,
        xirr,
        retirement_corpus,
    )

    try:
        if calc_type == "sip":
            result = {
                "future_value": sip_future_value(
                    float(params.get("monthly_investment", 0)),
                    float(params.get("annual_rate_percent", 0)),
                    int(params.get("months", 0)),
                )
            }
        elif calc_type == "lumpsum":
            result = {
                "future_value": lumpsum_future_value(
                    float(params.get("principal", 0)),
                    float(params.get("annual_rate_percent", 0)),
                    float(params.get("years", 0)),
                )
            }
        elif calc_type == "cagr":
            result = {
                "cagr_percent": cagr(
                    float(params.get("start_value", 0)),
                    float(params.get("end_value", 0)),
                    float(params.get("years", 0)),
                )
            }
        elif calc_type == "xirr":
            result = {
                "xirr_percent": xirr(params.get("cash_flows", []))
            }
        elif calc_type == "retirement":
            result = retirement_corpus(
                float(params.get("target_monthly_expense_today", 0)),
                int(params.get("years_to_retire", 0)),
                float(params.get("inflation_percent", 0)),
                float(params.get("post_retirement_return_percent", 0)),
                int(params.get("retirement_years", 25)),
            )
        else:
            return {"success": False, "error": f"Unknown calculator type: {calc_type}"}

        return {"success": True, "type": calc_type, "result": result}
    except Exception as e:
        logger.error(f"❌ INVESTMENT CALCULATOR: Calculation failed: {str(e)}")
        return {"success": False, "error": str(e)}

# Helper functions for file processing
def _process_excel_file(file_path: str) -> str:
    """Extract content from Excel file and return as structured text."""
    try:
        import pandas as pd
        
        # Try different engines for Excel file processing
        engines_to_try = ['openpyxl', 'xlrd', None]
        df_dict = None
        
        for engine in engines_to_try:
            try:
                if engine:
                    df_dict = pd.read_excel(file_path, sheet_name=None, engine=engine)
                else:
                    df_dict = pd.read_excel(file_path, sheet_name=None)
                break
            except Exception as e:
                logger.warning(f"Failed to read Excel with engine {engine}: {e}")
                continue
        
        if df_dict is None:
            return "Excel file processing error: Could not read file with any available engine"
        
        content = ""
        for sheet_name, df in df_dict.items():
            content += f"Sheet: {sheet_name}\n"
            content += df.to_string() + "\n\n"
        
        return content
    except Exception as e:
        logger.error(f"Excel processing failed: {e}")
        return f"Excel file processing error: {str(e)}"

def _process_pdf_file(file_path: str) -> str:
    """Extracts text content from a PDF file."""
    try:
        import PyPDF2
        text = ""
        with open(file_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            for page in reader.pages:
                text += page.extract_text()
        return text
    except Exception as e:
        logger.error(f"Error processing PDF file {file_path}: {e}")
        return ""

def _extract_key_recommendations(content: str) -> List[str]:
    """Extract key recommendations from market research content."""
    # TODO: Implement AI-powered extraction
    return ["Sample recommendation 1", "Sample recommendation 2"]

def _extract_risk_factors(content: str) -> List[str]:
    """Extract risk factors from market research content."""
    # TODO: Implement AI-powered extraction
    return ["Sample risk factor 1", "Sample risk factor 2"]

def _extract_opportunities(content: str) -> List[str]:
    """Extract opportunities from market research content."""
    # TODO: Implement AI-powered extraction
    return ["Sample opportunity 1", "Sample opportunity 2"] 

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import base64
import tempfile
import json
import asyncio

# Initialize FastAPI
## Duplicate FastAPI app init removed; using canonical app defined earlier

# Add CORS middleware
## CORS already configured above if needed

# Initialize OpenAI client
## OpenAI client initialized elsewhere

# Global variables
## globals declared earlier

import base64
import tempfile

## Duplicate model definitions removed (use canonical ones defined earlier)

# WebSocket connection manager for Realtime API
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        
    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        logger.info(f"🔌 WebSocket connected: {client_id}")
        
    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]
            logger.info(f"🔌 WebSocket disconnected: {client_id}")
            
    async def send_message(self, message: dict, client_id: str):
        if client_id in self.active_connections:
            websocket = self.active_connections[client_id]
            await websocket.send_text(json.dumps(message))

manager = ConnectionManager()

# @app.on_event("startup")  # Duplicate, commented out to avoid double startup handler
async def on_startup():
    global prediction_agent, db, async_client
    logger.info("Centhios AI API is starting up.")
    logger.info(f"GEMINI/GOOGLE API key loaded: {'Yes' if (os.getenv('GOOGLE_API_KEY') or os.getenv('GEMINI_API_KEY')) else 'No'}")
    
    # Initialize Firebase Admin SDK and Firestore client
    try:
        from firebase_admin import credentials
        # Initialize the Firebase App once
        if not firebase_admin._apps:
            # Check if we're running locally with emulator
            if os.getenv("FIRESTORE_EMULATOR_HOST"):
                # Running with emulator - use default initialization
                logger.info("🔧 Connecting to Firestore emulator")
                firebase_admin.initialize_app()
            else:
                # Production - prefer Cloud Run default service account
                environment = os.getenv("ENVIRONMENT", "development")
                if environment == "production":
                    # Cloud Run production environment - use default service account
                    logger.info("🔑 Using Cloud Run default service account")
                    firebase_admin.initialize_app()
                else:
                    # Development environment - use local service account key
                    key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or str(Path(__file__).parent / "serviceAccountKey.json")
                    if os.path.exists(key_path):
                        cred = credentials.Certificate(key_path)
                        logger.info(f"🔑 Using service account: {key_path}")
                        firebase_admin.initialize_app(cred)
                    else:
                        logger.info("🔑 Using default credentials (no service account key found)")
                        firebase_admin.initialize_app()
        logger.info("Firebase Admin SDK initialized successfully.")
        # Initialize Firestore client
        try:
            db = firestore.client()
            logger.info("Firestore client initialized successfully.")
        except Exception as e:
            logger.error(f"Firestore client initialization failed: {e}")
            db = None
    except ValueError as e:
        # Skip duplicate initialization on auto-reload
        if "already exists" in str(e):
            logger.debug("Firebase app already initialized, skipping.")
            db = firestore.client()
            logger.info("Firestore client initialized successfully (post-skip).")
        else:
            logger.error(f"Firebase init error: {e}")
            # Optionally fallback to a mock or exit
    except Exception as e:
        logger.error(f"Firebase init failed: {e}.")
        db = None
        raise

    prediction_agent = PredictionAgent(firestore_client=db)  # Enable
    logger.info("PredictionAgent enabled and initialized.")
    
    logger.info("AI Service startup complete (using simple service mode)")
    logger.info("🚀 AI Service ready to handle requests")

# Register startup event handler
app.add_event_handler("startup", on_startup)

@app.get("/")
async def root():
    return {"message": "Centhios AI API v2 is running.", "status": "ok", "version": "3.0.0"}

# Duplicate health endpoint removed - using the one with provider status above


@app.get("/admin/cache-stats")
async def cache_stats(req: Request):
    # Basic admin guard: require Authorization and admin claim
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if not decoded.get("admin", False):
            raise HTTPException(status_code=403, detail="Forbidden")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    try:
        from core.services.cache_service import response_cache, nav_cache
        return {
            "success": True,
            "caches": {
                "response_cache_size": len(getattr(response_cache, "_store", {})),
                "nav_cache_size": len(getattr(nav_cache, "_store", {})),
            },
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@app.get("/status")
async def status():
    """Public status endpoint with non-sensitive runtime info."""
    try:
        from core.services.rate_limit_service import rate_limiter
        rl = getattr(rate_limiter, 'max_requests', None)
    except Exception:
        rl = None
    try:
        available_models = ModelConfigService.get_available_models()
    except Exception:
        available_models = []
    return {
        "environment": os.getenv("ENVIRONMENT", "development"),
        "version": "3.0.0",
        "rate_limit_per_min": rl,
        "available_models": available_models,
    }

# WebSocket endpoint for OpenAI Realtime API
@app.websocket("/realtime")
async def websocket_realtime_endpoint(websocket: WebSocket):
    client_id = f"client_{datetime.now().timestamp()}"
    await manager.connect(websocket, client_id)
    
    # Initialize OpenAI Realtime API connection
    openai_ws = None
    
    try:
        logger.info(f"🎤 Initializing Realtime API connection for {client_id}")
        
        # Create OpenAI Realtime session
        import websockets
        import ssl
        
        # Connect to OpenAI Realtime API
        openai_api_key = (os.getenv("OPENAI_API_KEY") or "").strip()
        if not openai_api_key:
            await manager.send_message({
                "type": "error",
                "message": "OpenAI API key not configured"
            }, client_id)
            return
            
        # WebSocket connection to OpenAI Realtime API
        uri = "wss://api.openai.com/v1/realtime?model=gemini-2.5-pro"
        headers = {
            "Authorization": f"Bearer {openai_api_key}",
            "OpenAI-Beta": "realtime=v1"
        }
        
        ssl_context = ssl.create_default_context()
        
        try:
            openai_ws = await websockets.connect(
                uri,
                extra_headers=headers,
                ssl=ssl_context,
                ping_interval=20,
                ping_timeout=10
            )
            logger.info(f"✅ Connected to OpenAI Realtime API for {client_id}")
            
            # Send session created message to client
            await manager.send_message({
                "type": "session.created",
                "session": {
                    "id": client_id,
                    "model": "gemini-2.5-pro"
                }
            }, client_id)
            
        except Exception as e:
            logger.error(f"❌ Failed to connect to OpenAI Realtime API: {e}")
            await manager.send_message({
                "type": "error",
                "message": f"Failed to connect to OpenAI Realtime API: {str(e)}"
            }, client_id)
            return
        
        # Create tasks for bidirectional communication
        async def client_to_openai():
            try:
                async for message in websocket.iter_text():
                    try:
                        data = json.loads(message)
                        logger.info(f"📨 Client message: {data.get('type', 'unknown')}")
                        
                        # Transcribe audio if needed. For now, use provided text.
                        user_id = data.get('user_id')  # Assume sent
                        query = data.get('text') or data.get('query') or ""
                        agent_response = invoke_multi_agent_system(user_id, query + ' Tailor for family use.')
                        # Send response
                        
                    except json.JSONDecodeError:
                        logger.error("❌ Invalid JSON from client")
                    except Exception as e:
                        logger.error(f"❌ Error processing client message: {e}")
                        
            except WebSocketDisconnect:
                logger.info(f"🔌 Client {client_id} disconnected")
            except Exception as e:
                logger.error(f"❌ Client connection error: {e}")
        
        async def openai_to_client():
            try:
                async for message in openai_ws:
                    try:
                        data = json.loads(message)
                        logger.info(f"📩 OpenAI message: {data.get('type', 'unknown')}")
                        
                        # Forward message to client
                        await manager.send_message(data, client_id)
                        
                    except json.JSONDecodeError:
                        logger.error("❌ Invalid JSON from OpenAI")
                    except Exception as e:
                        logger.error(f"❌ Error processing OpenAI message: {e}")
                        
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"🔌 OpenAI connection closed for {client_id}")
            except Exception as e:
                logger.error(f"❌ OpenAI connection error: {e}")
        
        # Run both tasks concurrently
        await asyncio.gather(
            client_to_openai(),
            openai_to_client(),
            return_exceptions=True
        )
        
    except WebSocketDisconnect:
        logger.info(f"🔌 Client {client_id} disconnected")
    except Exception as e:
        logger.error(f"❌ Realtime WebSocket error: {e}")
        try:
            await manager.send_message({
                "type": "error",
                "message": str(e)
            }, client_id)
        except:
            pass
    finally:
        if openai_ws:
            await openai_ws.close()
        manager.disconnect(client_id)

## Duplicate /query removed in favor of secured handle_query above

## duplicate parse-sms removed; consolidated above

# Also support /parse-sms-messages for backward compatibility
@app.post("/parse-sms-messages")
async def parse_sms_messages_compat(request: SmsParseRequest, req: Request):
    return await parse_sms_messages(request, req)

@app.post('/parse-credit-card')
async def parse_credit_card(request: SmsParseRequest, req: Request):
    # Auth
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != request.user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    # Route via CreditCardAdvisor tool (agent_service)
    from core.agent_service import cfa_executor
    payload = {"input": "Analyze credit card messages and extract structured entries.", "user_id": request.user_id, "messages": request.messages}
    try:
        routed = cfa_executor.invoke({"input": "credit card analysis", "user_id": request.user_id})
    except Exception:
        routed = {}
    # Normalize schema
    entries = routed.get("credit_card", []) if isinstance(routed, dict) else []
    return {"credit_card": entries}

@app.post('/parse-bank-balance')
async def parse_bank_balance(request: SmsParseRequest, req: Request):
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != request.user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    from core.agent_service import cfa_executor
    try:
        routed = cfa_executor.invoke({"input": "bank balance summary", "user_id": request.user_id})
    except Exception:
        routed = {}
    entries = routed.get("bank_balance", []) if isinstance(routed, dict) else []
    return {"balance": entries}

@app.post('/parse-emi-loan')
async def parse_emi_loan(request: SmsParseRequest, req: Request):
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth as fb_auth
        decoded = fb_auth.verify_id_token(token)
        if decoded.get('uid') != request.user_id:
            raise HTTPException(status_code=401, detail="Token user mismatch")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    from core.agent_service import cfa_executor
    try:
        routed = cfa_executor.invoke({"input": "loan and emi details", "user_id": request.user_id})
    except Exception:
        routed = {}
    emi = routed.get("emi", []) if isinstance(routed, dict) else []
    loan = routed.get("loan", []) if isinstance(routed, dict) else []
    return {"emi": emi, "loan": loan}

@app.post('/feedback')
async def submit_feedback(request: FeedbackRequest):
    db.collection('feedback').add(request.dict())
    # Update knowledge or prompts dynamically
    return {'status': 'received'}

@app.post("/parse-and-import-investments")
async def parse_and_import_investments(request: InvestmentFileRequest, req: Request):
    """
    End-to-end: preprocess file, parse with AI agent, and import to database.
    """
    # Extract user ID from Authorization header for security
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token['uid']
        logger.info(f"🔐 Token verified for user: {user_id}")
    except Exception as e:
        logger.error(f"🚫 Token verification failed: {e}")
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    broker_name = request.broker_name
    # Combined pipeline: Use specialist LangChain agent to parse file
    logger.info(f"📁 Combined pipeline: Calling specialist InvestmentAgent for user {user_id}")
    # Use the new LangChain AgentExecutor pipeline
    ai_response = await arun_investment_file_agent({
        "file_content": request.file_content_base64,
        "file_type": request.file_type,
        "user_id": user_id,
        "broker_name": broker_name,
        "file_name": request.file_name
    })
    # The agent executor returns a dict
    ai_result = ai_response
    if not ai_result.get('success'):
        return ai_result
    # Combined pipeline: Import parsed investments to Firestore
    logger.info(f"💾 Combined pipeline: Writing {len(ai_result.get('investments', []))} investments to DB for user {user_id}")
    # Delegate persistence to backend API to keep a single source of truth
    import requests as _requests
    backend_base = os.getenv('BACKEND_BASE_URL', 'https://us-central1-cenithos.cloudfunctions.net/api')
    try:
        resp = _requests.post(
            f"{backend_base}/investments/import",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            json={
                "investments": ai_result.get('investments', []),
                "transactions": ai_result.get('transactions', []),
                "summary": {},
                "sourceFile": request.file_name,
                "broker": broker_name,
            },
            timeout=60,
        )
        resp.raise_for_status()
        db_result = resp.json()
    except Exception as e:
        logger.error(f"Backend import failed: {e}")
        db_result = {"success": False, "error": str(e)}
    return {**ai_result, **db_result}

if __name__ == "__main__":
    import uvicorn
    # Use PORT environment variable for Cloud Run compatibility
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port) 

# Streaming endpoint for combined parse-and-import pipeline
@app.post("/stream-parse-and-import-investments")
async def stream_parse_and_import_investments(request: InvestmentFileRequest, req: Request):
    """Stream each step of the parse-and-import pipeline as server-sent events."""
    
    # Extract user ID from Authorization header for security
    auth_header = req.headers.get("authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = auth_header.split("Bearer ")[1]
    try:
        from firebase_admin import auth
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token['uid']
        logger.info(f"🔐 Token verified for user: {user_id}")
    except Exception as e:
        logger.error(f"🚫 Token verification failed: {e}")
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    async def event_generator():
        # Preprocess
        yield "data: Combined pipeline: Preprocessing file...\n\n"
        preprocess_result = await preprocess_file(request.file_content_base64, request.file_type)
        errors = preprocess_result.get('errors', [])
        yield f"data: Preprocessing complete with {len(errors)} errors" + "\n\n"
        # AI agent
        yield "data: Combined pipeline: Running LangGraph investment agent...\n\n"
        # Run LangGraph-based investment agent and capture its internal logs
        yield "data: Combined pipeline: Running LangGraph investment agent...\n\n"
        import logging
        log_buffer: list[str] = []
        class SSEHandler(logging.Handler):
            def emit(self, record):
                log_buffer.append(record.getMessage())
        # Attach handler to agent logger
        handler = SSEHandler()
        handler.setFormatter(logging.Formatter("%(message)s"))
        agent_logger = logging.getLogger("centhios-investment-agent")
        agent_logger.addHandler(handler)
        # Invoke the agent - use verified user_id from token, not from request body
        graph_res = await process_investment_file_with_agent(
            request.file_content_base64,
            request.file_type,
            user_id,  # Use verified user_id instead of request.user_id
            request.broker_name,
            {"file_name": request.file_name}
        )
        # Stream each captured log line
        for msg in log_buffer:
            yield f"data: {msg}" + "\n\n"
        # Clean up handler
        agent_logger.removeHandler(handler)
        # Import to DB - use verified user_id
        yield "data: Combined pipeline: Importing to DB...\n\n"
        # Delegate persistence to backend API
        import requests as _requests
        backend_base = os.getenv('BACKEND_BASE_URL', 'https://us-central1-cenithos.cloudfunctions.net/api')
        try:
            resp = _requests.post(
                f"{backend_base}/investments/import",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                },
                json={
                    "investments": graph_res.get('investments', []),
                    "transactions": graph_res.get('transactions', []),
                    "summary": {},
                    "sourceFile": request.file_name,
                    "broker": request.broker_name,
                },
                timeout=60,
            )
            resp.raise_for_status()
            db_result = resp.json()
        except Exception as e:
            logger.error(f"Backend import failed: {e}")
            db_result = {"investmentsCreated": 0, "transactionsCreated": 0}
        created_inv = db_result.get('investmentsCreated', 0)
        created_tx = db_result.get('transactionsCreated', 0)
        yield f"data: DB complete: {created_inv} investments, {created_tx} transactions" + "\n\n"
        # Done
        yield "data: Combined pipeline completed" + "\n\n"
    return StreamingResponse(event_generator(), media_type="text/event-stream") 

@app.post("/update-nav")
async def update_nav_endpoint(request: Optional[Dict] = None):
    """
    Update NAV (Net Asset Value) for all mutual fund investments.
    Can be triggered manually or by scheduled jobs.
    """
    logger.info("🔄 Manual NAV update triggered")
    
    try:
        user_id = None
        if request and isinstance(request, dict):
            user_id = request.get('user_id')
        
        # Run the NAV update process
        update_results = await update_investment_nav_data(user_id)
        
        response = {
            "status": "success",
            "message": "NAV update completed",
            "results": update_results,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"✅ NAV update completed: {update_results}")
        return response
        
    except Exception as e:
        error_msg = f"NAV update failed: {e}"
        logger.error(error_msg, exc_info=True)
        return {
            "status": "error",
            "message": error_msg,
            "timestamp": datetime.now().isoformat()
        }


@app.get("/test-nav/{fund_name}")
async def test_nav_fetch(fund_name: str):
    """
    Test endpoint to check NAV fetching for a specific fund.
    Usage: /test-nav/Parag%20Parikh%20Flexi%20Cap%20Fund%20Direct%20Growth
    """
    logger.info(f"🧪 Testing NAV fetch for: {fund_name}")
    
    try:
        from core.tools.investment_file_tools import fetch_nav_from_multiple_sources
        
        # Fetch NAV data
        nav_data = await fetch_nav_from_multiple_sources(fund_name, 'growth')
        
        return {
            "status": "success",
            "fund_name": fund_name,
            "nav_data": nav_data,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        error_msg = f"NAV test failed: {e}"
        logger.error(error_msg, exc_info=True)
        return {
            "status": "error",
            "message": error_msg,
            "timestamp": datetime.now().isoformat()
        } 

# Background scheduler for daily NAV updates
def schedule_daily_nav_updates():
    """Schedule daily NAV updates to run after market hours (7 PM IST)."""
    
    def run_daily_nav_update():
        """Wrapper function to run NAV updates in async context."""
        try:
            logger.info("🕒 Running scheduled daily NAV update...")
            
            # Run the async function in the event loop
            import asyncio
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            result = loop.run_until_complete(update_investment_nav_data())
            logger.info(f"✅ Scheduled NAV update completed: {result}")
            
            loop.close()
            
        except Exception as e:
            logger.error(f"❌ Scheduled NAV update failed: {e}", exc_info=True)
    
    # Schedule daily at 7 PM (after market hours)
    schedule.every().day.at("19:00").do(run_daily_nav_update)
    
    def run_scheduler():
        while True:
            schedule.run_pending()
            time.sleep(60) # check every minute

    # The following lines will be moved into the startup_event
    # scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    # scheduler_thread.start()
    # logger.info("⏰ Scheduler thread started for background tasks")

    # Start scheduler in background thread
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()
    
    logger.info("📅 Daily NAV update scheduler started (runs daily at 7 PM IST)")

# Initialize prediction agent for pre-warming ML models on startup
prediction_agent: Optional[PredictionAgent] = None
categorization_agent: Optional[CategorizationAgent] = None
# ... existing code ...
@app.on_event("startup")
async def startup_event():
    """Application startup event: initialize services and background tasks."""
    # Initialize Firebase
    try:
        if not firebase_admin._apps:
            # Use default credentials on Cloud Run
            firebase_admin.initialize_app()
        logger.info("🔥 Firebase Admin SDK initialized")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")

    # Start the scheduler in a background thread (guarded)
    if 'run_scheduler' in globals():
        scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        scheduler_thread.start()
        logger.info("⏰ Scheduler thread started for background tasks")
    else:
        logger.info("Scheduler disabled in this environment")

    # Ensure Firestore client is available before agent initialization
    global db
    try:
        if os.getenv("FIRESTORE_EMULATOR_HOST"):
            db = firestore.client()
            logger.info("Firestore client initialized (emulator)")
        else:
            db = None
    except Exception as e:
        logger.warning(f"Skipping Firestore in startup_event: {e}")
        db = None

    # Initialize agents
    global prediction_agent, categorization_agent
    try:
        prediction_agent = PredictionAgent(firestore_client=db)
        categorization_agent = CategorizationAgent(LlmProviderFactory.get_provider("gemini"))
    except Exception as e:
        logger.error(f"Failed to initialize prediction or categorization agent: {e}")

    logger.info("🚀 Starting Centhios AI Service...")

    # Initialize LLM client (Gemini only)
    try:
        from core.services.llm_client import LLMClient
        llm_client = LLMClient(default_model="gemini-2.5-pro", timeout=30, max_retries=2)
        if prediction_agent and hasattr(prediction_agent, 'set_llm_client'):
            prediction_agent.set_llm_client(llm_client)
    except Exception as e:
        logger.warning(f"LLM client init skipped: {e}")

    # Initialize Gemini API client
    try:
        from core.llm import GeminiProvider
        api_key = os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY") or ""
        gemini_provider = GeminiProvider(api_key.strip())
        if prediction_agent and hasattr(prediction_agent, 'set_gemini_provider'):
            prediction_agent.set_gemini_provider(gemini_provider)
        logger.info("Gemini API client initialized.")
    except Exception as e:
        logger.warning(f"Gemini provider init skipped: {e}")

    # Initialize Categorization Agent
    try:
        if categorization_agent and hasattr(categorization_agent, 'set_llm_provider'):
            categorization_agent.set_llm_provider(LlmProviderFactory.get_provider("gemini"))
        logger.info("CategorizationAgent enabled and initialized.")
    except Exception as e:
        logger.warning(f"Categorization agent provider setup skipped: {e}")

    logger.info("✅ AI Service startup completed") 

@app.get("/health")
async def health_check():
    """
    Simple health check endpoint that responds immediately without heavy initialization.
    Used by Cloud Run and load balancers.
    """
    return {
        "status": "healthy",
        "service": "centhios-ai",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/investments/{user_id}")
async def get_investments(user_id: str):
    """
    Get all investments for a user to verify NAV updates.
    """
    try:
        from firebase_admin import firestore
        db = firestore.client()
        
        investments_docs = db.collection('investments').where('userId', '==', user_id).stream()
        
        investments = []
        for doc in investments_docs:
            investment_data = doc.to_dict()
            if investment_data:
                investment_data['id'] = doc.id
                investments.append(investment_data)
        
        return {
            "status": "success",
            "count": len(investments),
            "investments": investments,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        error_msg = f"Failed to get investments: {e}"
        logger.error(error_msg, exc_info=True)
        return {
            "status": "error",
            "message": error_msg,
            "timestamp": datetime.now().isoformat()
        } 

@app.post("/reprocess-investment-file")
async def reprocess_investment_file(request: Dict):
    """
    Reprocess an uploaded investment file with corrected consolidation logic.
    This fixes investments that were incorrectly consolidated initially.
    """
    logger.info("🔄 Reprocessing investment file with corrected logic")
    
    try:
        user_id = request.get('user_id')
        source_file = request.get('source_file', 'Mutual_Funds_Order_History_2021-11-01_2026-03-31_1753448019008_.xlsx')
        
        if not user_id:
            return {"error": "user_id is required", "status": "error"}
        
        # First, delete existing investments from this source file
        from firebase_admin import firestore
        db = firestore.client()
        
        # Delete existing data
        existing_investments = db.collection('investments').where('userId', '==', user_id).where('sourceFile', '==', source_file).stream()
        batch = db.batch()
        deleted_count = 0
        
        for doc in existing_investments:
            batch.delete(doc.reference)
            deleted_count += 1
        
        if deleted_count > 0:
            batch.commit()
            logger.info(f"🗑️ Deleted {deleted_count} existing investments from {source_file}")
        
        # Read the file from documentation folder
        file_path = f"/Users/benniejoseph/Documents/CenthiosV2/documentation/{source_file}"
        
        try:
            with open(file_path, 'rb') as f:
                file_content = f.read()
            
            import base64
            file_content_base64 = base64.b64encode(file_content).decode('utf-8')
            
            # Reprocess with corrected agent
            result = await process_investment_file_with_agent(
                file_content=file_content_base64,
                file_type="xlsx",
                user_id=user_id,
                broker_name="Groww"
            )
            
            # Save the corrected data to database
            if result.get('success') and (result.get('investments') or result.get('transactions')):
                db_result = await import_investments_to_db(user_id, {
                    'investments': result.get('investments', []),
                    'transactions': result.get('transactions', []),
                    'source_file': source_file,
                    'broker': "Groww"
                })
                result['database_save'] = db_result
                logger.info(f"💾 Saved corrected data to database: {db_result}")
            else:
                logger.warning("⚠️ No data to save to database")
            
            return {
                "status": "success",
                "message": f"Reprocessed {source_file} with corrected logic",
                "deleted_previous": deleted_count,
                "processing_result": result,
                "timestamp": datetime.now().isoformat()
            }
            
        except FileNotFoundError:
            return {
                "status": "error", 
                "message": f"File not found: {source_file}",
                "timestamp": datetime.now().isoformat()
            }
        
    except Exception as e:
        error_msg = f"Reprocessing failed: {e}"
        logger.error(error_msg, exc_info=True)
        return {
            "status": "error",
            "message": error_msg,
            "timestamp": datetime.now().isoformat()
        } 

@app.post("/debug-investment-data")
async def debug_investment_data(request: Request):
    """Debug endpoint to check investment and transaction data"""
    try:
        # Get user from auth header
        auth_header = request.headers.get("authorization", "")
        if not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header")
        
        token = auth_header.split("Bearer ")[1]
        from firebase_admin import auth
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token['uid']
        
        from core.tools.investment_file_tools import _db
        
        # Get investments for this user
        investments = _db.collection('investments').where('userId', '==', user_id).limit(5).stream()
        investment_data = []
        
        for inv in investments:
            inv_data = inv.to_dict()
            inv_id = inv.id
            
            # Count transactions for this investment
            transactions = _db.collection('investmentTransactions').where('investmentId', '==', inv_id).stream()
            txn_count = 0
            sample_transactions = []
            
            for txn in transactions:
                txn_data = txn.to_dict()
                txn_count += 1
                if txn_count <= 3:  # Get first 3 transactions as samples
                    sample_transactions.append({
                        'type': txn_data.get('type', ''),
                        'amount': txn_data.get('amount', 0),
                        'quantity': txn_data.get('quantity', 0),
                        'date': str(txn_data.get('date', '')),
                        'nav': txn_data.get('nav', 0)
                    })
            
            investment_data.append({
                'id': inv_id,
                'name': inv_data.get('name', 'Unknown'),
                'currentValue': inv_data.get('currentValue', 0),
                'investedAmount': inv_data.get('investedAmount', 0),
                'totalGain': inv_data.get('totalGain', 0),
                'totalGainPercent': inv_data.get('totalGainPercent', 0),
                'transactionCount': txn_count,
                'sampleTransactions': sample_transactions
            })
        
        return {
            'userId': user_id,
            'totalInvestments': len(investment_data),
            'investments': investment_data
        }
        
    except Exception as e:
        logger.error(f"Debug endpoint error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# =============================================================================
# COST TRACKING ENDPOINTS
# =============================================================================

from core.services.cost_tracking_service import cost_tracking_service
from datetime import datetime, timedelta

def extract_amount_from_text(text: str) -> float:
    """Extract amount from text using regex patterns (INR-aware)."""
    import re
    amount_patterns = [
        r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d{3})*(?:\.\d{2})?)',
        r'(\d+(?:,\d{3})*(?:\.\d{2})?)\s*(?:Rs\.?|INR|₹)',
        r'amount\s*:?\s*(?:Rs\.?|INR|₹)?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)',
    ]
    for pattern in amount_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                return float(match.group(1).replace(',', ''))
            except Exception:
                continue
    return 0.0

@app.get("/cost-summary/{user_id}")
async def get_cost_summary(
    user_id: str,
    days: int = 30,
    req: Request = None
):
    """Get AI cost summary for a user"""
    try:
        # Auth: caller must be same user or have admin
        auth_header = req.headers.get("authorization", "") if req else ""
        if not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing bearer token")
        token = auth_header.split("Bearer ")[1]
        try:
            from firebase_admin import auth as fb_auth
            decoded = fb_auth.verify_id_token(token)
            if decoded.get('uid') != user_id and not decoded.get('admin', False):
                raise HTTPException(status_code=403, detail="Forbidden")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        summary = cost_tracking_service.get_cost_summary(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date
        )
        
        return {
            "user_id": user_id,
            "period_days": days,
            "total_cost": float(summary.total_cost),
            "total_requests": summary.total_requests,
            "total_input_tokens": summary.total_input_tokens,
            "total_output_tokens": summary.total_output_tokens,
            "average_cost_per_request": float(summary.average_cost_per_request),
            "cost_by_model": {k: float(v) for k, v in summary.cost_by_model.items()},
            "cost_by_request_type": {k: float(v) for k, v in summary.cost_by_request_type.items()},
            "requests_by_model": summary.requests_by_model,
            "period_start": summary.period_start.isoformat(),
            "period_end": summary.period_end.isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting cost summary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Cost summary failed: {str(e)}")

@app.get("/cost-trends/{user_id}")
async def get_cost_trends(
    user_id: str,
    days: int = 30,
    req: Request = None
):
    """Get AI cost trends for charts"""
    try:
        # Auth: caller must be same user or have admin
        auth_header = req.headers.get("authorization", "") if req else ""
        if not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing bearer token")
        token = auth_header.split("Bearer ")[1]
        try:
            from firebase_admin import auth as fb_auth
            decoded = fb_auth.verify_id_token(token)
            if decoded.get('uid') != user_id and not decoded.get('admin', False):
                raise HTTPException(status_code=403, detail="Forbidden")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

        trends = cost_tracking_service.get_usage_trends(user_id, days)
        return {
            "user_id": user_id,
            "period_days": days,
            "trends": trends
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting cost trends: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Cost trends failed: {str(e)}")

@app.get("/cost-models/{user_id}")
async def get_model_comparison(
    user_id: str,
    days: int = 30,
    req: Request = None
):
    """Get model usage comparison"""
    try:
        # Auth: caller must be same user or have admin
        auth_header = req.headers.get("authorization", "") if req else ""
        if not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing bearer token")
        token = auth_header.split("Bearer ")[1]
        try:
            from firebase_admin import auth as fb_auth
            decoded = fb_auth.verify_id_token(token)
            if decoded.get('uid') != user_id and not decoded.get('admin', False):
                raise HTTPException(status_code=403, detail="Forbidden")
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

        comparison = cost_tracking_service.get_model_comparison(user_id, days)
        return {
            "user_id": user_id,
            **comparison
        }
        
    except Exception as e:
        logger.error(f"❌ Error getting model comparison: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Model comparison failed: {str(e)}")

# =============================================================================
# ENHANCED LEARNING ENDPOINTS
# =============================================================================

if LEARNING_ENABLED:
    # Initialize learning services
    enhanced_agent = EnhancedTransactionAgent()
    learning_service = AdaptiveLearningService()
    feedback_collector = FeedbackCollector()
    
    class FeedbackRequest(BaseModel):
        transaction_id: str
        user_id: str
        feedback_type: str
        original_data: Dict[str, Any]
        corrected_data: Dict[str, Any]
    
    @app.post("/feedback")
    async def process_feedback(request: FeedbackRequest, background_tasks: BackgroundTasks):
        """Process user feedback for learning"""
        try:
            logger.info(f"📝 Feedback: Processing {request.feedback_type} for transaction {request.transaction_id}")
            
            result = await enhanced_agent.process_user_feedback(
                transaction_id=request.transaction_id,
                user_id=request.user_id,
                feedback_type=request.feedback_type,
                original_data=request.original_data,
                corrected_data=request.corrected_data
            )
            
            return {
                "feedback_processed": result.get("feedback_processed", False),
                "learning_triggered": result.get("learning_triggered", False),
                "feedback_id": result.get("feedback_id"),
                "learning_result": result.get("learning_result", {})
            }
            
        except Exception as e:
            logger.error(f"❌ Error processing feedback: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Feedback processing failed: {str(e)}")
    
    @app.get("/learning-status/{user_id}")
    async def get_learning_status(user_id: str):
        """Get current learning status for a user"""
        try:
            status = await enhanced_agent.get_learning_status(user_id)
            return status
        except Exception as e:
            logger.error(f"❌ Error getting learning status: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Learning status failed: {str(e)}")
    
    @app.post("/analyze-learning")
    async def analyze_learning(request: dict):
        """Analyze learning opportunities"""
        try:
            user_id = request.get("user_id")
            if not user_id:
                raise HTTPException(status_code=400, detail="user_id is required")
            
            result = await enhanced_agent.analyze_learning_opportunities(user_id)
            return result
        except Exception as e:
            logger.error(f"❌ Error in learning analysis: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Learning analysis failed: {str(e)}")
    
    @app.get("/feedback-analytics")
    async def get_feedback_analytics(user_id: Optional[str] = None, days_back: int = 30):
        """Get feedback analytics and trends"""
        try:
            summary = await feedback_collector.get_feedback_summary(user_id, days_back)
            trends = await feedback_collector.get_feedback_trends(user_id, days_back)
            
            opportunities = []
            if user_id:
                opportunities = await feedback_collector.get_learning_opportunities(user_id, limit=10)
            
            return {
                "feedback_summary": summary,
                "feedback_trends": trends,
                "learning_opportunities": opportunities,
                "analytics_period": f"last_{days_back}_days"
            }
        except Exception as e:
            logger.error(f"❌ Error getting feedback analytics: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Feedback analytics failed: {str(e)}")

else:
    logger.warning("⚠️ Learning endpoints not available - Enhanced learning services not loaded") 

# --- Investment Document Processing ---

class PubSubMessage(BaseModel):
    message: Dict[str, Any]
    subscription: str

@app.post("/process-investment-document")
async def process_investment_document(
    request: Request,
    background_tasks: BackgroundTasks
):
    """
    Receives a Pub/Sub message when a new investment document is uploaded.
    Downloads the document and triggers the AI processing pipeline.
    """
    body = await request.json()
    message_data = body.get("message", {})
    if not message_data:
        raise HTTPException(status_code=400, detail="Invalid Pub/Sub message format")

    # Pub/Sub messages are base64-encoded
    try:
        payload_str = base64.b64decode(message_data.get("data", "")).decode("utf-8")
        payload = json.loads(payload_str)
    except Exception as e:
        logger.error(f"Error decoding Pub/Sub message: {e}")
        raise HTTPException(status_code=400, detail="Invalid Pub/Sub message data")

    user_id = payload.get("userId")
    gcs_uri = payload.get("gcsUri")

    if not user_id or not gcs_uri:
        raise HTTPException(status_code=400, detail="Missing userId or gcsUri in payload")

    logger.info(f"Received request to process document {gcs_uri} for user {user_id}")

    # Acknowledge the message immediately to prevent retries
    # and run the processing in the background.
    background_tasks.add_task(run_investment_document_pipeline, user_id, gcs_uri)
    
    return {"status": "queued", "gcsUri": gcs_uri}

def run_investment_document_pipeline(user_id: str, gcs_uri: str):
    """
    Downloads the file and runs the full AI pipeline.
    This function is designed to be run in the background.
    """
    try:
        logger.info(f"Starting pipeline for {gcs_uri}")
        # 1. Download file from GCS
        storage_client = storage.Client()
        bucket_name, *blob_path_parts = gcs_uri.replace("gs://", "").split("/")
        blob_path = "/".join(blob_path_parts)
        
        # Debug logging
        logger.info(f"Downloading from bucket: {bucket_name}, path: {blob_path}")
        
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_path)
        
        # Create a temporary file to store the PDF
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp_file:
            blob.download_to_filename(tmp_file.name)
            local_path = tmp_file.name

        logger.info(f"Downloaded {gcs_uri} to {local_path}")

        # 2. Invoke the LangGraph Agent
        from core.agents.investment_document_agent import investment_document_agent_executor
        
        initial_state = {
            "user_id": user_id,
            "document_path": local_path,
            "processing_log": [f"Pipeline started for {gcs_uri}"],
        }
        
        result = investment_document_agent_executor.invoke(initial_state)
        
        # Log the final state and any errors
        if result.get("error"):
            logger.error(f"AI Pipeline failed for {gcs_uri}. Final state: {result}")
            # Optionally update Firestore with failure status here
        else:
            logger.info(f"AI Pipeline completed for {gcs_uri}. Final log: {result.get('processing_log')}")

    except Exception as e:
        logger.error(f"Error in investment document pipeline for {gcs_uri}: {e}", exc_info=True)
        # Here you could update Firestore with a 'failed' status
    finally:
        # 3. Clean up the temporary file
        if 'local_path' in locals() and os.path.exists(local_path):
            os.remove(local_path)
            logger.info(f"Cleaned up temporary file: {local_path}")


# --- Investment Analysis ---

# ============================================================================
# NEW BANKING FEATURES (Phases 1-2) - SMS Intelligence & Smart Banking
# ============================================================================
try:
    from endpoints_new import router as new_banking_router
    app.include_router(new_banking_router)
    logger.info("✅ New banking features endpoints loaded successfully!")
except Exception as e:
    logger.warning(f"⚠️  Could not load new banking features: {e}")

# ============================================================================
# COST TRACKING - Google Cloud Platform
# ============================================================================
try:
    from endpoints_cost_tracking import router as cost_tracking_router
    app.include_router(cost_tracking_router)
    logger.info("✅ Cost tracking endpoints loaded successfully!")
except Exception as e:
    logger.warning(f"⚠️  Could not load cost tracking endpoints: {e}")

# ============================================================================
# NOTIFICATION SYSTEM - AI-Powered Notifications
# ============================================================================
try:
    from endpoints_notifications import router as notifications_router, init_notification_system
    
    # Initialize notification system with Firestore client
    init_notification_system(db)
    
    app.include_router(notifications_router)
    logger.info("🔔 Notification system endpoints loaded successfully!")
except Exception as e:
    logger.warning(f"⚠️  Could not load notification endpoints: {e}")