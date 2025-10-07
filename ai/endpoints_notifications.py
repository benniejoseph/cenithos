"""
Notification API Endpoints
===========================

FastAPI endpoints for notification management:
- Create notifications (triggered by events)
- Retrieve user notifications
- Update notification status (read, archived)
- Delete notifications
- Manage user preferences
- Record interactions (for learning)
"""

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Query, Body
from pydantic import BaseModel, Field

from core.notifications.ai_notification_engine import AINotificationEngine
from core.notifications.notification_types import (
    Notification,
    NotificationCategory,
    NotificationPriority,
    NotificationAction,
    NotificationTrigger,
    UserNotificationPreferences,
)
from core.notifications.personalization_engine import PersonalizationEngine
from core.services.fcm_service import FCMService, get_fcm_service
from firebase_admin import firestore

logger = logging.getLogger(__name__)

# Initialize router
router = APIRouter(prefix="/api/v1/notifications", tags=["notifications"])

# Global instances (will be initialized with db_client)
notification_engine: Optional[AINotificationEngine] = None
personalization_engine: Optional[PersonalizationEngine] = None
fcm_service: Optional[FCMService] = None


def init_notification_system(db_client):
    """Initialize notification system with database client"""
    global notification_engine, personalization_engine, fcm_service
    notification_engine = AINotificationEngine(db_client)
    personalization_engine = PersonalizationEngine(db_client)
    fcm_service = get_fcm_service(db_client)
    logger.info("🔔 Notification system initialized")


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class CreateNotificationRequest(BaseModel):
    """Request to create a notification from a trigger"""
    trigger_type: str = Field(..., description="Type of trigger (transaction_created, budget_threshold, etc.)")
    user_id: str = Field(..., description="User ID")
    data: Dict[str, Any] = Field(..., description="Trigger data")
    priority_override: Optional[str] = None


class NotificationResponse(BaseModel):
    """Notification response model"""
    id: str
    user_id: str
    category: str
    priority: str
    title: str
    body: str
    rich_content: Optional[Dict[str, Any]] = None
    timestamp: str
    importance_score: float
    relevance_score: float
    is_read: bool = False
    is_archived: bool = False
    available_actions: List[str] = []
    related_transaction_id: Optional[str] = None


class UpdateNotificationRequest(BaseModel):
    """Request to update notification status"""
    is_read: Optional[bool] = None
    is_archived: Optional[bool] = None
    action_taken: Optional[str] = None


class NotificationPreferencesRequest(BaseModel):
    """Request to update notification preferences"""
    notifications_enabled: Optional[bool] = None
    quiet_hours_enabled: Optional[bool] = None
    quiet_hours_start: Optional[int] = None
    quiet_hours_end: Optional[int] = None
    high_value_threshold: Optional[float] = None
    category_preferences: Optional[Dict[str, bool]] = None
    show_insights: Optional[bool] = None
    show_recommendations: Optional[bool] = None
    learn_optimal_times: Optional[bool] = None


class NotificationStatsResponse(BaseModel):
    """Notification statistics"""
    total_notifications: int
    unread_count: int
    by_category: Dict[str, int]
    by_priority: Dict[str, int]
    recent_count: int  # Last 24 hours


# ============================================================================
# NOTIFICATION CRUD ENDPOINTS
# ============================================================================

@router.post("/create", response_model=NotificationResponse)
async def create_notification(request: CreateNotificationRequest):
    """
    Create a notification from a trigger event.
    
    This is typically called by other services when events occur
    (e.g., transaction created, budget threshold reached, etc.)
    """
    try:
        if not notification_engine:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Create trigger
        trigger = NotificationTrigger(
            trigger_type=request.trigger_type,
            user_id=request.user_id,
            data=request.data,
            timestamp=datetime.now()
        )
        
        # Process trigger through AI engine
        notification = await notification_engine.process_trigger(trigger)
        
        if not notification:
            # Notification was filtered out (not important enough)
            return {"message": "Notification filtered", "created": False}
        
        # Send push notification if enabled
        if fcm_service and notification.priority in [NotificationPriority.CRITICAL, NotificationPriority.HIGH]:
            try:
                push_data = {
                    'notification_id': notification.id,
                    'category': notification.category.value,
                    'priority': notification.priority.value,
                }
                
                if notification.related_transaction_id:
                    push_data['transaction_id'] = notification.related_transaction_id
                
                fcm_result = await fcm_service.send_notification(
                    user_id=request.user_id,
                    title=notification.title,
                    body=notification.body,
                    data=push_data,
                    notification_id=notification.id,
                    priority='high' if notification.priority == NotificationPriority.CRITICAL else 'high',
                )
                
                logger.info(f"📱 Push notification sent: {fcm_result.get('sent', 0)} devices")
                
            except Exception as e:
                logger.error(f"❌ Failed to send push notification: {e}")
        
        logger.info(f"✅ Created notification {notification.id} for user {request.user_id}")
        
        return NotificationResponse(
            id=notification.id,
            user_id=notification.user_id,
            category=notification.category.value,
            priority=notification.priority.value,
            title=notification.title,
            body=notification.body,
            rich_content=notification.rich_content,
            timestamp=notification.timestamp.isoformat(),
            importance_score=notification.importance_score,
            relevance_score=notification.relevance_score,
            is_read=notification.is_read,
            is_archived=notification.is_archived,
            available_actions=[a.value for a in notification.available_actions],
            related_transaction_id=notification.related_transaction_id,
        )
        
    except Exception as e:
        logger.error(f"❌ Error creating notification: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}", response_model=List[NotificationResponse])
async def get_user_notifications(
    user_id: str,
    limit: int = Query(50, ge=1, le=200, description="Maximum notifications to return"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    unread_only: bool = Query(False, description="Return only unread notifications"),
    category: Optional[str] = Query(None, description="Filter by category"),
    priority: Optional[str] = Query(None, description="Filter by priority"),
    since: Optional[str] = Query(None, description="Return notifications since this date (ISO format)"),
):
    """
    Get notifications for a user with filtering and pagination.
    
    Supports:
    - Pagination (limit/offset)
    - Filter by read status
    - Filter by category
    - Filter by priority
    - Filter by date
    """
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Build query
        query = notification_engine.db.collection('notifications').where('user_id', '==', user_id)
        
        # Apply filters
        if unread_only:
            query = query.where('is_read', '==', False)
        
        if category:
            query = query.where('category', '==', category)
        
        if priority:
            query = query.where('priority', '==', priority)
        
        if since:
            query = query.where('timestamp', '>=', since)
        
        # Order by timestamp (newest first)
        query = query.order_by('timestamp', direction=firestore.Query.DESCENDING)
        
        # Apply pagination
        query = query.limit(limit).offset(offset)
        
        # Execute query
        docs = query.stream()
        
        notifications = []
        for doc in docs:
            data = doc.to_dict()
            notifications.append(NotificationResponse(
                id=data.get('id'),
                user_id=data.get('user_id'),
                category=data.get('category'),
                priority=data.get('priority'),
                title=data.get('title'),
                body=data.get('body'),
                rich_content=data.get('rich_content'),
                timestamp=data.get('timestamp'),
                importance_score=data.get('importance_score', 0),
                relevance_score=data.get('relevance_score', 0),
                is_read=data.get('is_read', False),
                is_archived=data.get('is_archived', False),
                available_actions=data.get('available_actions', []),
                related_transaction_id=data.get('related_transaction_id'),
            ))
        
        logger.debug(f"📊 Retrieved {len(notifications)} notifications for user {user_id}")
        
        return notifications
        
    except Exception as e:
        logger.error(f"❌ Error retrieving notifications: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{notification_id}", response_model=NotificationResponse)
async def get_notification(notification_id: str):
    """Get a specific notification by ID"""
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        doc = notification_engine.db.collection('notifications').document(notification_id).get()
        
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        data = doc.to_dict()
        
        return NotificationResponse(
            id=data.get('id'),
            user_id=data.get('user_id'),
            category=data.get('category'),
            priority=data.get('priority'),
            title=data.get('title'),
            body=data.get('body'),
            rich_content=data.get('rich_content'),
            timestamp=data.get('timestamp'),
            importance_score=data.get('importance_score', 0),
            relevance_score=data.get('relevance_score', 0),
            is_read=data.get('is_read', False),
            is_archived=data.get('is_archived', False),
            available_actions=data.get('available_actions', []),
            related_transaction_id=data.get('related_transaction_id'),
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error retrieving notification: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{notification_id}")
async def update_notification(
    notification_id: str,
    update: UpdateNotificationRequest,
    user_id: str = Query(..., description="User ID for verification")
):
    """
    Update notification status (mark as read, archived, etc.)
    """
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Get notification
        doc_ref = notification_engine.db.collection('notifications').document(notification_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        data = doc.to_dict()
        
        # Verify ownership
        if data.get('user_id') != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to update this notification")
        
        # Build update dict
        update_dict = {}
        
        if update.is_read is not None:
            update_dict['is_read'] = update.is_read
            if update.is_read:
                update_dict['opened_at'] = datetime.now().isoformat()
        
        if update.is_archived is not None:
            update_dict['is_archived'] = update.is_archived
        
        if update.action_taken:
            update_dict['action_taken'] = update.action_taken
            update_dict['action_taken_at'] = datetime.now().isoformat()
            
            # Record interaction for learning
            try:
                action_enum = NotificationAction(update.action_taken)
                await notification_engine.record_notification_interaction(
                    notification_id, action_enum, user_id
                )
            except ValueError:
                logger.warning(f"Unknown action: {update.action_taken}")
        
        # Update in database
        doc_ref.update(update_dict)
        
        logger.debug(f"✅ Updated notification {notification_id}")
        
        return {"message": "Notification updated successfully", "updated_fields": list(update_dict.keys())}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error updating notification: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    user_id: str = Query(..., description="User ID for verification")
):
    """Delete a notification (soft delete - marks as deleted)"""
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Get notification
        doc_ref = notification_engine.db.collection('notifications').document(notification_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Notification not found")
        
        data = doc.to_dict()
        
        # Verify ownership
        if data.get('user_id') != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this notification")
        
        # Soft delete
        doc_ref.update({
            'is_deleted': True,
            'deleted_at': datetime.now().isoformat()
        })
        
        logger.debug(f"🗑️  Deleted notification {notification_id}")
        
        return {"message": "Notification deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting notification: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/mark-all-read")
async def mark_all_read(user_id: str = Body(..., embed=True)):
    """Mark all notifications as read for a user"""
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Get all unread notifications
        query = notification_engine.db.collection('notifications') \
            .where('user_id', '==', user_id) \
            .where('is_read', '==', False)
        
        docs = query.stream()
        
        count = 0
        for doc in docs:
            doc.reference.update({
                'is_read': True,
                'opened_at': datetime.now().isoformat()
            })
            count += 1
        
        logger.info(f"✅ Marked {count} notifications as read for user {user_id}")
        
        return {"message": f"Marked {count} notifications as read"}
        
    except Exception as e:
        logger.error(f"❌ Error marking all as read: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# NOTIFICATION STATISTICS
# ============================================================================

@router.get("/stats/{user_id}", response_model=NotificationStatsResponse)
async def get_notification_stats(user_id: str):
    """Get notification statistics for a user"""
    try:
        if not notification_engine or not notification_engine.db:
            raise HTTPException(status_code=500, detail="Notification system not initialized")
        
        # Get all notifications for user
        query = notification_engine.db.collection('notifications').where('user_id', '==', user_id)
        docs = list(query.stream())
        
        total = len(docs)
        unread = sum(1 for doc in docs if not doc.to_dict().get('is_read', False))
        
        # Count by category
        by_category = {}
        for doc in docs:
            cat = doc.to_dict().get('category', 'unknown')
            by_category[cat] = by_category.get(cat, 0) + 1
        
        # Count by priority
        by_priority = {}
        for doc in docs:
            pri = doc.to_dict().get('priority', 'medium')
            by_priority[pri] = by_priority.get(pri, 0) + 1
        
        # Count recent (last 24 hours)
        yesterday = (datetime.now() - timedelta(hours=24)).isoformat()
        recent = sum(
            1 for doc in docs 
            if doc.to_dict().get('timestamp', '') >= yesterday
        )
        
        return NotificationStatsResponse(
            total_notifications=total,
            unread_count=unread,
            by_category=by_category,
            by_priority=by_priority,
            recent_count=recent,
        )
        
    except Exception as e:
        logger.error(f"❌ Error getting stats: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# USER PREFERENCES
# ============================================================================

@router.get("/preferences/{user_id}")
async def get_user_preferences(user_id: str):
    """Get notification preferences for a user"""
    try:
        if not personalization_engine:
            raise HTTPException(status_code=500, detail="Personalization engine not initialized")
        
        preferences = await personalization_engine.get_user_preferences(user_id)
        
        return preferences.to_dict()
        
    except Exception as e:
        logger.error(f"❌ Error getting preferences: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/preferences/{user_id}")
async def update_user_preferences(
    user_id: str,
    preferences: NotificationPreferencesRequest
):
    """Update notification preferences for a user"""
    try:
        if not personalization_engine:
            raise HTTPException(status_code=500, detail="Personalization engine not initialized")
        
        # Load current preferences
        current_prefs = await personalization_engine.get_user_preferences(user_id)
        
        # Update fields
        if preferences.notifications_enabled is not None:
            current_prefs.notifications_enabled = preferences.notifications_enabled
        
        if preferences.quiet_hours_enabled is not None:
            current_prefs.quiet_hours_enabled = preferences.quiet_hours_enabled
        
        if preferences.quiet_hours_start is not None:
            current_prefs.quiet_hours_start = preferences.quiet_hours_start
        
        if preferences.quiet_hours_end is not None:
            current_prefs.quiet_hours_end = preferences.quiet_hours_end
        
        if preferences.high_value_threshold is not None:
            current_prefs.high_value_threshold = preferences.high_value_threshold
        
        if preferences.category_preferences:
            for cat, enabled in preferences.category_preferences.items():
                try:
                    cat_enum = NotificationCategory(cat)
                    current_prefs.category_preferences[cat_enum] = enabled
                except ValueError:
                    logger.warning(f"Unknown category: {cat}")
        
        if preferences.show_insights is not None:
            current_prefs.show_insights = preferences.show_insights
        
        if preferences.show_recommendations is not None:
            current_prefs.show_recommendations = preferences.show_recommendations
        
        if preferences.learn_optimal_times is not None:
            current_prefs.learn_optimal_times = preferences.learn_optimal_times
        
        # Save updated preferences
        await personalization_engine.save_user_preferences(current_prefs)
        
        logger.info(f"✅ Updated preferences for user {user_id}")
        
        return {"message": "Preferences updated successfully", "preferences": current_prefs.to_dict()}
        
    except Exception as e:
        logger.error(f"❌ Error updating preferences: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# FCM TOKEN MANAGEMENT
# ============================================================================

@router.post("/fcm/register")
async def register_fcm_token(
    user_id: str = Body(...),
    fcm_token: str = Body(...),
):
    """Register an FCM token for push notifications"""
    try:
        if not fcm_service:
            raise HTTPException(status_code=500, detail="FCM service not initialized")
        
        success = await fcm_service.register_token(user_id, fcm_token)
        
        if success:
            return {"message": "FCM token registered successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to register FCM token")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error registering FCM token: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/fcm/unregister")
async def unregister_fcm_token(
    user_id: str = Body(...),
    fcm_token: str = Body(...),
):
    """Unregister an FCM token"""
    try:
        if not fcm_service:
            raise HTTPException(status_code=500, detail="FCM service not initialized")
        
        success = await fcm_service.unregister_token(user_id, fcm_token)
        
        if success:
            return {"message": "FCM token unregistered successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to unregister FCM token")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error unregistering FCM token: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# TESTING & DEBUGGING
# ============================================================================

@router.post("/test/create-sample")
async def create_sample_notification(user_id: str = Body(..., embed=True)):
    """Create a sample notification for testing (development only)"""
    try:
        # Create a sample transaction trigger
        sample_trigger = NotificationTrigger.transaction_created(
            user_id=user_id,
            transaction={
                "id": f"test_{datetime.now().timestamp()}",
                "amount": 5000.0,
                "vendor": "TestMerchant",
                "category": "Shopping",
                "type": "expense",
                "date": datetime.now().isoformat(),
            }
        )
        
        notification = await notification_engine.process_trigger(sample_trigger)
        
        if notification:
            return {
                "message": "Sample notification created",
                "notification_id": notification.id,
                "title": notification.title,
                "body": notification.body,
            }
        else:
            return {"message": "Notification was filtered out"}
        
    except Exception as e:
        logger.error(f"❌ Error creating sample: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

