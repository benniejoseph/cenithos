"""
Cost Tracking Endpoints for Centhios AI Backend

Provides API endpoints for tracking and retrieving Google Cloud costs
including Gemini API, Firestore, Cloud Run, and other GCP services.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import logging

from core.services.google_cloud_cost_service import gcp_cost_service, CostCategory

logger = logging.getLogger("centhios-ai")

router = APIRouter(prefix="/api/v1/costs", tags=["Cost Tracking"])

# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class GeminiUsageRequest(BaseModel):
    user_id: str
    model_name: str
    input_tokens: int
    output_tokens: int
    request_type: str = "general"

class CostSummaryResponse(BaseModel):
    total_cost: float
    cost_by_category: Dict[str, float]
    cost_by_service: Dict[str, float]
    period_start: str
    period_end: str
    currency: str
    total_requests: int

class DailyCostData(BaseModel):
    date: str
    total: float
    by_category: Dict[str, float]

class MonthlyEstimateResponse(BaseModel):
    estimated_monthly_cost: float
    daily_average: float
    based_on_days: int
    currency: str
    breakdown_by_category: Dict[str, float]

# ============================================================================
# COST TRACKING ENDPOINTS
# ============================================================================

@router.post("/record/gemini")
async def record_gemini_usage(request: GeminiUsageRequest):
    """
    Record Gemini API usage with automatic cost calculation
    
    This endpoint tracks token usage and calculates costs based on
    current Gemini pricing tiers.
    """
    try:
        record_id = gcp_cost_service.record_gemini_usage(
            user_id=request.user_id,
            model_name=request.model_name,
            input_tokens=request.input_tokens,
            output_tokens=request.output_tokens,
            request_type=request.request_type
        )
        
        # Calculate cost for response
        input_cost, output_cost, total_cost = gcp_cost_service.calculate_gemini_cost(
            request.model_name,
            request.input_tokens,
            request.output_tokens
        )
        
        return {
            "success": True,
            "record_id": record_id,
            "cost": {
                "input_cost": float(input_cost),
                "output_cost": float(output_cost),
                "total_cost": float(total_cost),
                "currency": "USD"
            },
            "usage": {
                "input_tokens": request.input_tokens,
                "output_tokens": request.output_tokens,
                "total_tokens": request.input_tokens + request.output_tokens
            }
        }
    
    except Exception as e:
        logger.error(f"Failed to record Gemini usage: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/summary")
async def get_cost_summary(
    user_id: Optional[str] = Query(None, description="User ID (omit for project-wide costs)"),
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    include_live_data: bool = Query(False, description="Include live billing data from GCP API")
):
    """
    Get comprehensive cost summary for a time period
    
    Returns breakdown by category and service. Defaults to last 30 days.
    """
    try:
        # Parse dates
        start_dt = datetime.fromisoformat(start_date) if start_date else None
        end_dt = datetime.fromisoformat(end_date) if end_date else None
        
        summary = gcp_cost_service.get_cost_summary(
            user_id=user_id,
            start_date=start_dt,
            end_date=end_dt,
            include_live_data=include_live_data
        )
        
        return summary.to_dict()
    
    except Exception as e:
        logger.error(f"Failed to get cost summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/daily")
async def get_daily_costs(
    days: int = Query(30, ge=1, le=365, description="Number of days"),
    user_id: Optional[str] = Query(None, description="User ID (omit for project-wide costs)")
):
    """
    Get daily cost breakdown for charts and visualizations
    
    Returns array of daily cost data with category breakdowns.
    """
    try:
        daily_data = gcp_cost_service.get_daily_costs(
            days=days,
            user_id=user_id
        )
        
        return {
            "success": True,
            "days": days,
            "data": daily_data
        }
    
    except Exception as e:
        logger.error(f"Failed to get daily costs: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/estimate-monthly")
async def estimate_monthly_cost(
    user_id: Optional[str] = Query(None, description="User ID (omit for project-wide)")
):
    """
    Estimate monthly cost based on recent usage patterns
    
    Uses last 7 days of data to project monthly costs.
    """
    try:
        estimate = gcp_cost_service.estimate_monthly_cost(user_id=user_id)
        
        return {
            "success": True,
            **estimate
        }
    
    except Exception as e:
        logger.error(f"Failed to estimate monthly cost: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/breakdown/category")
async def get_cost_by_category(
    user_id: Optional[str] = Query(None),
    days: int = Query(30, ge=1, le=365)
):
    """
    Get cost breakdown by category (AI, Storage, Compute, etc.)
    """
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        summary = gcp_cost_service.get_cost_summary(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date
        )
        
        # Format for pie chart
        categories = []
        for category, cost in summary.cost_by_category.items():
            categories.append({
                "category": category,
                "cost": float(cost),
                "percentage": float(cost / summary.total_cost * 100) if summary.total_cost > 0 else 0
            })
        
        return {
            "success": True,
            "total_cost": float(summary.total_cost),
            "currency": summary.currency,
            "period_days": days,
            "categories": sorted(categories, key=lambda x: x["cost"], reverse=True)
        }
    
    except Exception as e:
        logger.error(f"Failed to get category breakdown: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/breakdown/service")
async def get_cost_by_service(
    user_id: Optional[str] = Query(None),
    days: int = Query(30, ge=1, le=365)
):
    """
    Get cost breakdown by specific service
    """
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        summary = gcp_cost_service.get_cost_summary(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date
        )
        
        # Format for detailed breakdown
        services = []
        for service, cost in summary.cost_by_service.items():
            services.append({
                "service": service,
                "cost": float(cost),
                "percentage": float(cost / summary.total_cost * 100) if summary.total_cost > 0 else 0
            })
        
        return {
            "success": True,
            "total_cost": float(summary.total_cost),
            "currency": summary.currency,
            "period_days": days,
            "services": sorted(services, key=lambda x: x["cost"], reverse=True)
        }
    
    except Exception as e:
        logger.error(f"Failed to get service breakdown: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/gemini/pricing")
async def get_gemini_pricing():
    """
    Get current Gemini API pricing information
    """
    try:
        return {
            "success": True,
            "pricing": gcp_cost_service.gemini_pricing,
            "currency": "USD",
            "unit": "per 1M tokens",
            "last_updated": "2025-01-01"
        }
    
    except Exception as e:
        logger.error(f"Failed to get Gemini pricing: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/alerts")
async def get_cost_alerts(
    user_id: Optional[str] = Query(None),
    threshold_usd: float = Query(10.0, description="Alert threshold in USD")
):
    """
    Get cost alerts if spending exceeds threshold
    """
    try:
        # Get current month costs
        end_date = datetime.now()
        start_date = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        summary = gcp_cost_service.get_cost_summary(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date
        )
        
        # Calculate projection for rest of month
        days_elapsed = (end_date - start_date).days
        days_in_month = 30  # Simplified
        daily_avg = summary.total_cost / days_elapsed if days_elapsed > 0 else 0
        projected_monthly = daily_avg * days_in_month
        
        alerts = []
        if projected_monthly > threshold_usd:
            alerts.append({
                "type": "threshold_exceeded",
                "severity": "warning",
                "message": f"Projected monthly cost ${projected_monthly:.2f} exceeds threshold ${threshold_usd:.2f}",
                "current_cost": float(summary.total_cost),
                "projected_cost": float(projected_monthly),
                "threshold": threshold_usd
            })
        
        return {
            "success": True,
            "has_alerts": len(alerts) > 0,
            "alerts": alerts,
            "current_month_cost": float(summary.total_cost),
            "projected_monthly_cost": float(projected_monthly)
        }
    
    except Exception as e:
        logger.error(f"Failed to get cost alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

