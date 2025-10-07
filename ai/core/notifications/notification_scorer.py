"""
Notification Importance Scorer
================================

Calculates importance scores (0-100) for notifications based on:
- Transaction amount and type
- User patterns
- Category
- Timing
- Anomalies
"""

import logging
from typing import Dict, Optional, Any
from datetime import datetime

from .notification_types import NotificationTrigger, NotificationContext

logger = logging.getLogger(__name__)


class NotificationScorer:
    """Calculate importance scores for notifications"""
    
    def calculate_importance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        anomalies: Optional[Dict[str, Any]] = None
    ) -> float:
        """
        Calculate importance score (0-100) for a notification.
        
        Higher score = more important notification
        """
        
        score = 0.0
        
        try:
            if trigger.trigger_type == "transaction_created":
                score = self._score_transaction(trigger, context)
            elif trigger.trigger_type == "budget_threshold":
                score = self._score_budget(trigger, context)
            elif trigger.trigger_type == "bill_due":
                score = self._score_bill(trigger, context)
            elif trigger.trigger_type == "goal_milestone":
                score = self._score_goal(trigger, context)
            elif trigger.trigger_type == "anomaly_detected":
                score = 95.0  # Anomalies are always high importance
            elif trigger.trigger_type == "insight_generated":
                score = self._score_insight(trigger, context)
            else:
                score = 50.0  # Default medium importance
            
            # Boost score if anomalies detected
            if anomalies and anomalies.get('is_anomaly'):
                score = min(100.0, score + 30.0)
            
            # Cap between 0-100
            score = max(0.0, min(100.0, score))
            
            logger.debug(f"📊 Importance score: {score:.1f} for {trigger.trigger_type}")
            
        except Exception as e:
            logger.error(f"❌ Error calculating importance: {e}")
            score = 50.0  # Default on error
        
        return score
    
    def _score_transaction(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext
    ) -> float:
        """Score transaction notifications"""
        
        txn = trigger.data.get("transaction", {})
        amount = abs(float(txn.get("amount", 0)))
        tx_type = txn.get("type", "expense")
        category = txn.get("category", "")
        
        score = 40.0  # Base score
        
        # Amount-based scoring
        if amount >= 50000:
            score += 30.0
        elif amount >= 10000:
            score += 20.0
        elif amount >= 5000:
            score += 10.0
        elif amount >= 1000:
            score += 5.0
        
        # Income always important
        if tx_type == "income":
            score += 15.0
        
        # Comparison with user average
        if context.user_average:
            ratio = amount / context.user_average if context.user_average > 0 else 1.0
            if ratio >= 3.0:
                score += 15.0  # 3x average
            elif ratio >= 2.0:
                score += 10.0  # 2x average
            elif ratio >= 1.5:
                score += 5.0   # 1.5x average
        
        # Budget impact
        if context.budget_status:
            pct_used = context.budget_status.get('percentage_used', 0)
            if pct_used >= 100:
                score += 20.0
            elif pct_used >= 90:
                score += 15.0
            elif pct_used >= 75:
                score += 10.0
        
        # Time-based scoring
        if context.is_unusual_time:
            score += 10.0
        
        # Critical categories
        critical_categories = ['loan emi', 'insurance', 'healthcare', 'rent']
        if any(cat in category.lower() for cat in critical_categories):
            score += 10.0
        
        return score
    
    def _score_budget(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext
    ) -> float:
        """Score budget alert notifications"""
        
        percentage = trigger.data.get("percentage", 0)
        
        score = 30.0  # Base score
        
        # Threshold-based scoring
        if percentage >= 1.10:  # 110% - over budget
            score += 40.0
        elif percentage >= 1.0:  # 100% - at limit
            score += 30.0
        elif percentage >= 0.90:  # 90% - warning
            score += 20.0
        elif percentage >= 0.75:  # 75% - heads up
            score += 10.0
        
        # Historical pattern
        if context.user_spending_pattern:
            usually_over = context.user_spending_pattern.get('usually_exceeds_budget', False)
            if usually_over and percentage >= 0.9:
                score += 10.0  # More important if they usually go over
        
        return score
    
    def _score_bill(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext
    ) -> float:
        """Score bill reminder notifications"""
        
        days_until_due = trigger.data.get("days_until_due", 7)
        bill = trigger.data.get("bill", {})
        amount = float(bill.get("amount", 0))
        
        score = 40.0  # Base score
        
        # Urgency-based scoring
        if days_until_due == 0:
            score += 40.0  # Due today!
        elif days_until_due == 1:
            score += 30.0  # Due tomorrow
        elif days_until_due == 3:
            score += 15.0  # 3 days
        elif days_until_due == 7:
            score += 5.0   # 1 week
        
        # Amount-based
        if amount >= 10000:
            score += 15.0
        elif amount >= 5000:
            score += 10.0
        elif amount >= 1000:
            score += 5.0
        
        # Bill type
        bill_type = bill.get("type", "").lower()
        critical_types = ['electricity', 'rent', 'loan', 'credit card', 'insurance']
        if any(t in bill_type for t in critical_types):
            score += 10.0
        
        return score
    
    def _score_goal(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext
    ) -> float:
        """Score goal milestone notifications"""
        
        milestone = trigger.data.get("milestone", 0)
        
        score = 30.0  # Base score
        
        # Milestone-based scoring
        if milestone >= 100:
            score += 40.0  # Goal completed!
        elif milestone >= 75:
            score += 25.0  # 75% milestone
        elif milestone >= 50:
            score += 20.0  # Half way
        elif milestone >= 25:
            score += 15.0  # Quarter way
        elif milestone >= 10:
            score += 10.0  # 10% milestone
        
        # First milestone is special
        if milestone <= 10:
            score += 10.0  # Encourage early progress
        
        return score
    
    def _score_insight(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext
    ) -> float:
        """Score AI-generated insight notifications"""
        
        insight_type = trigger.data.get("insight_type", "")
        insight_data = trigger.data.get("insight_data", {})
        
        score = 35.0  # Base score
        
        # Insight type scoring
        high_value_insights = [
            'spending_spike',
            'savings_opportunity',
            'fraud_risk',
            'budget_forecast',
            'cashflow_warning'
        ]
        
        if insight_type in high_value_insights:
            score += 25.0
        
        # Impact-based scoring
        potential_savings = insight_data.get('potential_savings', 0)
        if potential_savings >= 5000:
            score += 20.0
        elif potential_savings >= 1000:
            score += 10.0
        
        # Actionability
        if insight_data.get('is_actionable', False):
            score += 15.0
        
        return score

