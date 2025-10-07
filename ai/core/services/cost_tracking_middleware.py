"""
Cost Tracking Middleware for Gemini API Calls

Automatically tracks and records all Gemini API usage including:
- Input/output tokens
- Model used
- Request type
- Calculated costs
"""

import logging
from typing import Optional, Any, Dict
from datetime import datetime
from functools import wraps
import google.generativeai as genai

logger = logging.getLogger("centhios-ai")

# Import cost service
try:
    from core.services.google_cloud_cost_service import gcp_cost_service
    COST_TRACKING_ENABLED = True
except Exception as e:
    logger.warning(f"⚠️  Cost tracking service not available: {e}")
    COST_TRACKING_ENABLED = False


class CostTrackingMiddleware:
    """Middleware to track Gemini API costs"""
    
    def __init__(self):
        self.enabled = COST_TRACKING_ENABLED
        
    def track_gemini_call(self, user_id: Optional[str] = None, request_type: str = "general"):
        """
        Decorator to track Gemini API calls and record costs
        
        Usage:
            @cost_tracker.track_gemini_call(user_id="user123", request_type="sms_parsing")
            async def my_gemini_call():
                ...
        """
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                if not self.enabled:
                    return await func(*args, **kwargs)
                
                start_time = datetime.now()
                model_name = None
                
                try:
                    # Extract model name from args/kwargs if available
                    if 'model' in kwargs:
                        model_name = kwargs['model']
                    elif hasattr(args[0] if args else None, 'model_name'):
                        model_name = args[0].model_name
                    else:
                        model_name = "gemini-2.5-pro"  # Default
                    
                    # Call the original function
                    result = await func(*args, **kwargs)
                    
                    # Extract token counts from result if available
                    input_tokens = 0
                    output_tokens = 0
                    
                    if hasattr(result, 'usage_metadata'):
                        input_tokens = getattr(result.usage_metadata, 'prompt_token_count', 0)
                        output_tokens = getattr(result.usage_metadata, 'candidates_token_count', 0)
                    elif isinstance(result, dict):
                        if 'usage' in result:
                            input_tokens = result['usage'].get('prompt_tokens', 0)
                            output_tokens = result['usage'].get('completion_tokens', 0)
                        elif 'usage_metadata' in result:
                            input_tokens = result['usage_metadata'].get('prompt_token_count', 0)
                            output_tokens = result['usage_metadata'].get('candidates_token_count', 0)
                    
                    # Record usage
                    if input_tokens > 0 or output_tokens > 0:
                        try:
                            record_id = gcp_cost_service.record_gemini_usage(
                                user_id=user_id or "system",
                                model_name=model_name,
                                input_tokens=input_tokens,
                                output_tokens=output_tokens,
                                request_type=request_type
                            )
                            
                            # Calculate cost
                            input_cost, output_cost, total_cost = gcp_cost_service.calculate_gemini_cost(
                                model_name,
                                input_tokens,
                                output_tokens
                            )
                            
                            duration = (datetime.now() - start_time).total_seconds()
                            
                            logger.info(
                                f"💰 Cost tracked: {model_name} | "
                                f"Tokens: {input_tokens}+{output_tokens}={input_tokens+output_tokens} | "
                                f"Cost: ${total_cost:.6f} | "
                                f"Duration: {duration:.2f}s | "
                                f"Type: {request_type}"
                            )
                        except Exception as e:
                            logger.error(f"❌ Failed to record cost: {e}")
                    
                    return result
                    
                except Exception as e:
                    logger.error(f"❌ Error in cost tracking wrapper: {e}")
                    # Re-raise the original exception
                    raise
            
            return wrapper
        return decorator
    
    def record_usage(
        self,
        model_name: str,
        input_tokens: int,
        output_tokens: int,
        user_id: Optional[str] = None,
        request_type: str = "general",
        metadata: Optional[Dict[str, Any]] = None
    ):
        """
        Directly record usage without decorator
        
        Useful for manual tracking when decorator isn't applicable
        """
        if not self.enabled:
            return
        
        try:
            record_id = gcp_cost_service.record_gemini_usage(
                user_id=user_id or "system",
                model_name=model_name,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                request_type=request_type
            )
            
            input_cost, output_cost, total_cost = gcp_cost_service.calculate_gemini_cost(
                model_name,
                input_tokens,
                output_tokens
            )
            
            logger.info(
                f"💰 Cost recorded: {model_name} | "
                f"Tokens: {input_tokens}+{output_tokens}={input_tokens+output_tokens} | "
                f"Cost: ${total_cost:.6f} | "
                f"Type: {request_type}"
            )
            
            return {
                "record_id": record_id,
                "input_cost": float(input_cost),
                "output_cost": float(output_cost),
                "total_cost": float(total_cost),
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "total_tokens": input_tokens + output_tokens
            }
            
        except Exception as e:
            logger.error(f"❌ Failed to record usage: {e}")
            return None


# Global instance
cost_tracker = CostTrackingMiddleware()


def track_gemini_response(response: Any, user_id: Optional[str] = None, request_type: str = "general", model_name: str = "gemini-2.5-pro"):
    """
    Helper function to track a Gemini response after it's received
    
    Usage:
        response = await model.generate_content_async(prompt)
        track_gemini_response(response, user_id="user123", request_type="sms_parsing")
    """
    try:
        input_tokens = 0
        output_tokens = 0
        
        if hasattr(response, 'usage_metadata'):
            input_tokens = getattr(response.usage_metadata, 'prompt_token_count', 0)
            output_tokens = getattr(response.usage_metadata, 'candidates_token_count', 0)
        
        if input_tokens > 0 or output_tokens > 0:
            cost_tracker.record_usage(
                model_name=model_name,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                user_id=user_id,
                request_type=request_type
            )
    except Exception as e:
        logger.error(f"❌ Error tracking Gemini response: {e}")

