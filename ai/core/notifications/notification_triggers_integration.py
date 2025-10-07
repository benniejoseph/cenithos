"""
Notification Triggers Integration
==================================

Helper functions to easily trigger notifications from anywhere in the codebase.

Usage:
    from core.notifications.notification_triggers_integration import (
        notify_transaction_created,
        notify_budget_alert,
        notify_bill_reminder,
    )
    
    # After creating a transaction
    await notify_transaction_created(user_id, transaction_data)
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime
from core.notifications.notification_types import NotificationTrigger
from endpoints_notifications import notification_engine

logger = logging.getLogger(__name__)


# ============================================================================
# TRANSACTION NOTIFICATIONS
# ============================================================================

async def notify_transaction_created(
    user_id: str,
    transaction: Dict[str, Any],
) -> bool:
    """
    Trigger notification when a transaction is created/detected.
    
    Args:
        user_id: User ID
        transaction: Transaction dictionary with keys:
            - id: Transaction ID
            - amount: Amount (float)
            - vendor: Merchant name
            - category: Transaction category
            - type: "expense" or "income"
            - date: ISO timestamp
            - description (optional)
    
    Returns:
        True if notification was created, False otherwise
    """
    try:
        if not notification_engine:
            logger.warning("Notification engine not initialized")
            return False
        
        trigger = NotificationTrigger.transaction_created(
            user_id=user_id,
            transaction=transaction
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.info(f"✅ Transaction notification created: {notification.id}")
            return True
        else:
            logger.debug(f"Transaction notification filtered out (not important enough)")
            return False
            
    except Exception as e:
        logger.error(f"❌ Error triggering transaction notification: {e}")
        return False


async def notify_high_value_transaction(
    user_id: str,
    transaction: Dict[str, Any],
    user_average: float,
) -> bool:
    """
    Trigger notification for high-value transactions.
    
    This is automatically handled by notify_transaction_created,
    but can be called separately for explicit high-value alerts.
    """
    return await notify_transaction_created(user_id, transaction)


# ============================================================================
# BUDGET NOTIFICATIONS
# ============================================================================

async def notify_budget_threshold(
    user_id: str,
    category: str,
    current_amount: float,
    budget_amount: float,
    percentage: int,
) -> bool:
    """
    Trigger notification when budget threshold is reached.
    
    Args:
        user_id: User ID
        category: Budget category (e.g., "Food & Dining")
        current_amount: Current spending in category
        budget_amount: Total budget for category
        percentage: Percentage used (e.g., 90)
    
    Returns:
        True if notification was created
    """
    try:
        if not notification_engine:
            return False
        
        trigger = NotificationTrigger.budget_threshold(
            user_id=user_id,
            category=category,
            current_amount=current_amount,
            budget_amount=budget_amount,
            percentage=percentage
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.info(f"✅ Budget alert notification created: {notification.id}")
            return True
        return False
        
    except Exception as e:
        logger.error(f"❌ Error triggering budget notification: {e}")
        return False


async def notify_budget_exceeded(
    user_id: str,
    category: str,
    current_amount: float,
    budget_amount: float,
) -> bool:
    """Notify when budget is exceeded (100%+)"""
    percentage = int((current_amount / budget_amount) * 100)
    return await notify_budget_threshold(
        user_id, category, current_amount, budget_amount, percentage
    )


# ============================================================================
# BILL NOTIFICATIONS
# ============================================================================

async def notify_bill_reminder(
    user_id: str,
    bill_name: str,
    amount: float,
    due_date: str,
    days_until_due: int,
) -> bool:
    """
    Trigger notification for upcoming bill.
    
    Args:
        user_id: User ID
        bill_name: Name of the bill (e.g., "Electricity Bill")
        amount: Bill amount
        due_date: Due date (ISO format or "YYYY-MM-DD")
        days_until_due: Number of days until due
    
    Returns:
        True if notification was created
    """
    try:
        if not notification_engine:
            return False
        
        trigger = NotificationTrigger.bill_due_soon(
            user_id=user_id,
            bill_name=bill_name,
            amount=amount,
            due_date=due_date
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.info(f"✅ Bill reminder notification created: {notification.id}")
            return True
        return False
        
    except Exception as e:
        logger.error(f"❌ Error triggering bill notification: {e}")
        return False


# ============================================================================
# SAVINGS GOAL NOTIFICATIONS
# ============================================================================

async def notify_goal_milestone(
    user_id: str,
    goal_name: str,
    current_amount: float,
    target_amount: float,
    milestone: int,
) -> bool:
    """
    Trigger notification when savings goal milestone is reached.
    
    Args:
        user_id: User ID
        goal_name: Name of the goal (e.g., "Vacation Fund")
        current_amount: Current saved amount
        target_amount: Target amount
        milestone: Milestone percentage (25, 50, 75, 100)
    
    Returns:
        True if notification was created
    """
    try:
        if not notification_engine:
            return False
        
        trigger = NotificationTrigger.goal_milestone(
            user_id=user_id,
            goal_name=goal_name,
            current_amount=current_amount,
            target_amount=target_amount,
            milestone=milestone
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.info(f"✅ Goal milestone notification created: {notification.id}")
            return True
        return False
        
    except Exception as e:
        logger.error(f"❌ Error triggering goal notification: {e}")
        return False


# ============================================================================
# AI INSIGHT NOTIFICATIONS
# ============================================================================

async def notify_ai_insight(
    user_id: str,
    insight_type: str,
    title: str,
    description: str,
    data: Optional[Dict[str, Any]] = None,
) -> bool:
    """
    Trigger notification for AI-generated insights.
    
    Args:
        user_id: User ID
        insight_type: Type of insight (e.g., "spending_pattern", "savings_opportunity")
        title: Insight title
        description: Insight description
        data: Additional data for context
    
    Returns:
        True if notification was created
    """
    try:
        if not notification_engine:
            return False
        
        trigger = NotificationTrigger.ai_insight(
            user_id=user_id,
            insight_type=insight_type,
            title=title,
            description=description,
            data=data or {}
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.info(f"✅ AI insight notification created: {notification.id}")
            return True
        return False
        
    except Exception as e:
        logger.error(f"❌ Error triggering AI insight notification: {e}")
        return False


# ============================================================================
# ANOMALY DETECTION (Fraud) NOTIFICATIONS
# ============================================================================

async def notify_suspicious_activity(
    user_id: str,
    transaction: Dict[str, Any],
    anomaly_reasons: list[str],
    risk_score: float,
) -> bool:
    """
    Trigger CRITICAL notification for suspicious activity.
    
    Args:
        user_id: User ID
        transaction: Transaction data
        anomaly_reasons: List of reasons (e.g., ["unusual_time", "new_merchant"])
        risk_score: Risk score 0.0-1.0
    
    Returns:
        True if notification was created
    """
    try:
        if not notification_engine:
            return False
        
        # Add anomaly info to transaction data
        transaction_with_anomaly = {
            **transaction,
            'anomaly_detected': True,
            'anomaly_reasons': anomaly_reasons,
            'risk_score': risk_score,
        }
        
        trigger = NotificationTrigger.transaction_created(
            user_id=user_id,
            transaction=transaction_with_anomaly
        )
        
        notification = await notification_engine.process_trigger(trigger)
        
        if notification:
            logger.warning(f"🚨 FRAUD ALERT notification created: {notification.id}")
            return True
        return False
        
    except Exception as e:
        logger.error(f"❌ Error triggering fraud notification: {e}")
        return False


# ============================================================================
# BATCH NOTIFICATION TRIGGERS
# ============================================================================

async def check_and_notify_budgets(user_id: str, budgets: list[Dict[str, Any]]) -> int:
    """
    Check all budgets and trigger notifications for those exceeding thresholds.
    
    Args:
        user_id: User ID
        budgets: List of budget dictionaries with:
            - category: Category name
            - spent: Current spending
            - budget: Budget limit
    
    Returns:
        Number of notifications created
    """
    count = 0
    
    for budget in budgets:
        category = budget.get('category')
        spent = budget.get('spent', 0)
        limit = budget.get('budget', 0)
        
        if limit <= 0:
            continue
        
        percentage = int((spent / limit) * 100)
        
        # Notify at 80%, 90%, 100%
        if percentage >= 80:
            success = await notify_budget_threshold(
                user_id=user_id,
                category=category,
                current_amount=spent,
                budget_amount=limit,
                percentage=percentage
            )
            if success:
                count += 1
    
    return count


async def check_and_notify_bills(user_id: str, bills: list[Dict[str, Any]]) -> int:
    """
    Check all bills and trigger reminders for upcoming ones.
    
    Args:
        user_id: User ID
        bills: List of bill dictionaries with:
            - name: Bill name
            - amount: Amount
            - due_date: Due date
            - days_until_due: Days until due
    
    Returns:
        Number of notifications created
    """
    count = 0
    
    for bill in bills:
        days_until_due = bill.get('days_until_due', 999)
        
        # Notify at 7 days, 3 days, 1 day, day of
        if days_until_due in [7, 3, 1, 0]:
            success = await notify_bill_reminder(
                user_id=user_id,
                bill_name=bill.get('name', 'Bill'),
                amount=bill.get('amount', 0),
                due_date=bill.get('due_date', ''),
                days_until_due=days_until_due
            )
            if success:
                count += 1
    
    return count

