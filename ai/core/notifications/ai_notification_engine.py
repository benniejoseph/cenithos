"""
AI-Powered Notification Engine
================================

Uses Google Gemini to generate intelligent, context-aware financial notifications.

Key Features:
- Smart importance scoring
- Context generation with Gemini
- Personalization learning
- Multi-channel orchestration
- Notification fatigue prevention
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from collections import defaultdict
import asyncio

from .notification_types import (
    Notification,
    NotificationCategory,
    NotificationPriority,
    NotificationChannel,
    NotificationTrigger,
    NotificationContext,
    NotificationAction,
    UserNotificationPreferences,
)
from .notification_scorer import NotificationScorer
from .anomaly_detector import AnomalyDetector
from .context_generator import ContextGenerator
from .personalization_engine import PersonalizationEngine
from core.services.google_cloud_cost_service import RequestType
from core.simple_ai_service import call_gemini_api

logger = logging.getLogger(__name__)


class AINotificationEngine:
    """
    Main AI-powered notification engine that orchestrates the entire notification lifecycle.
    """
    
    def __init__(self, db_client=None):
        self.db = db_client
        
        # Initialize sub-components
        self.scorer = NotificationScorer()
        self.anomaly_detector = AnomalyDetector()
        self.context_generator = ContextGenerator(db_client)
        self.personalization = PersonalizationEngine(db_client)
        
        # Notification queue and history
        self.pending_notifications: Dict[str, List[Notification]] = defaultdict(list)
        self.notification_history: Dict[str, List[Notification]] = defaultdict(list)
        
        # Rate limiting
        self.notification_counts: Dict[str, Dict[str, int]] = defaultdict(
            lambda: {'hour': 0, 'day': 0}
        )
        self.last_reset: Dict[str, datetime] = {}
        
        logger.info("🧠 AI Notification Engine initialized")
    
    async def process_trigger(
        self,
        trigger: NotificationTrigger,
        user_preferences: Optional[UserNotificationPreferences] = None
    ) -> Optional[Notification]:
        """
        Process a notification trigger and decide whether to create a notification.
        
        Args:
            trigger: The event that triggered the notification
            user_preferences: User's notification preferences
            
        Returns:
            Notification object if one should be sent, None otherwise
        """
        try:
            logger.debug(f"🔔 Processing trigger: {trigger.trigger_type} for user {trigger.user_id}")
            
            # 1. Load user preferences if not provided
            if user_preferences is None:
                user_preferences = await self.personalization.get_user_preferences(trigger.user_id)
            
            # 2. Check if notifications are enabled globally
            if not user_preferences.notifications_enabled:
                logger.debug(f"Notifications disabled for user {trigger.user_id}")
                return None
            
            # 3. Check rate limiting
            if not self._check_rate_limit(trigger.user_id, user_preferences):
                logger.debug(f"Rate limit exceeded for user {trigger.user_id}")
                return None
            
            # 4. Determine notification category
            category = self._determine_category(trigger)
            
            # 5. Check if this category is enabled
            if not user_preferences.category_preferences.get(category, True):
                logger.debug(f"Category {category} disabled for user {trigger.user_id}")
                return None
            
            # 6. Generate rich context
            context = await self.context_generator.generate_context(trigger, user_preferences)
            
            # 7. Detect anomalies (fraud, unusual patterns)
            if trigger.trigger_type == "transaction_created":
                anomalies = await self.anomaly_detector.detect_anomalies(
                    trigger.data.get("transaction"),
                    trigger.user_id,
                    context
                )
                if anomalies:
                    # Upgrade to fraud alert
                    category = NotificationCategory.FRAUD_DETECTION
                    context.risk_score = anomalies.get('risk_score', 0.8)
                    context.gemini_analysis = anomalies.get('explanation', '')
            
            # 8. Calculate importance and relevance scores
            importance_score = self.scorer.calculate_importance(trigger, context, anomalies if 'anomalies' in locals() else None)
            relevance_score = await self.personalization.calculate_relevance(
                trigger, context, trigger.user_id
            )
            
            # 9. Check if scores meet threshold
            if importance_score < 30 and relevance_score < 40:
                logger.debug(f"Scores too low: importance={importance_score}, relevance={relevance_score}")
                return None
            
            # 10. Determine priority based on scores and category
            priority = self._determine_priority(importance_score, relevance_score, category)
            
            # 11. Check quiet hours for non-critical notifications
            if priority != NotificationPriority.CRITICAL:
                if self._is_quiet_hours(user_preferences):
                    logger.debug(f"Quiet hours active for user {trigger.user_id}")
                    # Queue for later delivery
                    return None
            
            # 12. Generate notification content with Gemini
            title, body, rich_content = await self._generate_notification_content(
                trigger, category, context, user_preferences
            )
            
            # 13. Determine delivery channels
            channels = self._determine_channels(priority, category, user_preferences)
            
            # 14. Determine available actions
            actions = self._determine_actions(category, trigger)
            
            # 15. Calculate optimal delivery time (if not immediate)
            optimal_time = await self.personalization.calculate_optimal_delivery_time(
                trigger.user_id, category
            ) if priority in [NotificationPriority.LOW, NotificationPriority.MEDIUM] else None
            
            # 16. Create notification object
            notification = Notification(
                id=f"notif_{trigger.user_id}_{datetime.now().timestamp()}",
                user_id=trigger.user_id,
                category=category,
                priority=priority,
                title=title,
                body=body,
                rich_content=rich_content,
                importance_score=importance_score,
                relevance_score=relevance_score,
                context=context,
                related_transaction_id=trigger.data.get("transaction", {}).get("id"),
                related_budget_id=trigger.data.get("budget_id"),
                related_goal_id=trigger.data.get("goal_id"),
                channels=channels,
                available_actions=actions,
                optimal_delivery_time=optimal_time,
                user_preference_score=relevance_score / 100.0,
            )
            
            # 17. Store notification
            await self._store_notification(notification)
            
            # 18. Update rate limiting counters
            self._increment_rate_limit(trigger.user_id)
            
            # 19. Learn from this notification for future personalization
            await self.personalization.record_notification_created(notification)
            
            logger.info(f"✅ Created notification: {category.value} for user {trigger.user_id}")
            logger.info(f"   Priority: {priority.value} | Importance: {importance_score:.1f} | Relevance: {relevance_score:.1f}")
            
            return notification
            
        except Exception as e:
            logger.error(f"❌ Error processing trigger: {e}", exc_info=True)
            return None
    
    async def _generate_notification_content(
        self,
        trigger: NotificationTrigger,
        category: NotificationCategory,
        context: NotificationContext,
        user_preferences: UserNotificationPreferences
    ) -> Tuple[str, str, Dict[str, Any]]:
        """
        Generate notification content using Gemini AI.
        
        Returns:
            (title, body, rich_content)
        """
        try:
            # Build context for Gemini
            gemini_prompt = self._build_gemini_prompt(trigger, category, context, user_preferences)
            
            # Call Gemini
            messages = [
                {
                    "role": "user",
                    "parts": [{"text": gemini_prompt}]
                }
            ]
            
            response = call_gemini_api(
                messages=messages,
                model="gemini-2.0-flash-exp",
                max_tokens=300,
                temperature=0.7,
                user_id=trigger.user_id,
                request_type=RequestType.NOTIFICATION_GENERATION
            )
            
            # Parse Gemini response
            content = response.get('content', '')
            
            # Extract title and body from response
            lines = content.strip().split('\n')
            title = lines[0].replace('**', '').strip()
            body = '\n'.join(lines[1:]).strip()
            
            # Generate rich content
            rich_content = self._build_rich_content(trigger, category, context)
            
            return title, body, rich_content
            
        except Exception as e:
            logger.error(f"❌ Error generating content with Gemini: {e}")
            # Fallback to template-based generation
            return self._generate_fallback_content(trigger, category, context)
    
    def _build_gemini_prompt(
        self,
        trigger: NotificationTrigger,
        category: NotificationCategory,
        context: NotificationContext,
        user_preferences: UserNotificationPreferences
    ) -> str:
        """Build prompt for Gemini to generate notification content"""
        
        prompt_parts = [
            "You are a financial notification assistant for Centhios, a smart banking app.",
            f"Generate a notification for category: {category.value}",
            "",
            "Context:",
        ]
        
        if trigger.trigger_type == "transaction_created":
            txn = trigger.data.get("transaction", {})
            prompt_parts.extend([
                f"- Transaction: ₹{txn.get('amount', 0):.2f} at {txn.get('vendor', 'Unknown')}",
                f"- Category: {txn.get('category', 'Uncategorized')}",
                f"- Date: {txn.get('date', 'Today')}",
            ])
            
            if context.user_average:
                prompt_parts.append(f"- User's average for this category: ₹{context.user_average:.2f}")
            
            if context.budget_status:
                budget_pct = context.budget_status.get('percentage_used', 0)
                prompt_parts.append(f"- Budget usage: {budget_pct:.0f}%")
        
        elif trigger.trigger_type == "budget_threshold":
            prompt_parts.extend([
                f"- Budget threshold reached: {trigger.data.get('percentage', 0)*100:.0f}%",
                f"- Category: {trigger.data.get('category', 'General')}",
            ])
        
        elif trigger.trigger_type == "bill_due":
            bill = trigger.data.get("bill", {})
            days = trigger.data.get("days_until_due", 0)
            prompt_parts.extend([
                f"- Bill: {bill.get('name', 'Upcoming bill')}",
                f"- Amount: ₹{bill.get('amount', 0):.2f}",
                f"- Due in: {days} days",
            ])
        
        if context.gemini_analysis:
            prompt_parts.append(f"\nAI Analysis: {context.gemini_analysis}")
        
        if context.recommendations:
            prompt_parts.append(f"\nRecommendations: {', '.join(context.recommendations[:2])}")
        
        prompt_parts.extend([
            "",
            "Instructions:",
            "1. First line: Create a concise, engaging title (max 40 characters) with an appropriate emoji",
            "2. Following lines: Write a clear, helpful message (2-3 sentences)",
            "3. Make it actionable and contextual",
            "4. Use Indian Rupee (₹) for amounts",
            "5. Be encouraging for positive news, direct for alerts",
            "",
            "Output format:",
            "[Title with emoji]",
            "[Body message line 1]",
            "[Body message line 2]",
        ])
        
        return "\n".join(prompt_parts)
    
    def _generate_fallback_content(
        self,
        trigger: NotificationTrigger,
        category: NotificationCategory,
        context: NotificationContext
    ) -> Tuple[str, str, Dict[str, Any]]:
        """Generate notification content using templates (fallback)"""
        
        title = "💳 Financial Update"
        body = "You have a new financial update."
        
        if trigger.trigger_type == "transaction_created":
            txn = trigger.data.get("transaction", {})
            amount = txn.get("amount", 0)
            vendor = txn.get("vendor", "Unknown")
            tx_type = txn.get("type", "expense")
            
            if tx_type == "income":
                title = "💰 Money Received"
                body = f"₹{amount:.2f} received{f' from {vendor}' if vendor != 'Unknown' else ''}"
            else:
                title = "💳 Payment Made"
                body = f"₹{amount:.2f} spent at {vendor}"
                
                if context.budget_status:
                    pct = context.budget_status.get('percentage_used', 0)
                    body += f"\n📊 Budget: {pct:.0f}% used"
        
        elif trigger.trigger_type == "budget_threshold":
            pct = trigger.data.get("percentage", 0) * 100
            title = "📊 Budget Alert"
            body = f"You've reached {pct:.0f}% of your budget"
        
        elif trigger.trigger_type == "bill_due":
            bill = trigger.data.get("bill", {})
            days = trigger.data.get("days_until_due", 0)
            title = "📅 Bill Reminder"
            body = f"{bill.get('name', 'Bill')} due in {days} days (₹{bill.get('amount', 0):.2f})"
        
        elif trigger.trigger_type == "goal_milestone":
            milestone = trigger.data.get("milestone", 0)
            title = "🎯 Goal Milestone!"
            body = f"You've reached {milestone:.0f}% of your savings goal!"
        
        elif trigger.trigger_type == "anomaly_detected":
            title = "🚨 Unusual Activity"
            reasons = trigger.data.get("reasons", [])
            body = f"Unusual transaction detected: {reasons[0] if reasons else 'Please review'}"
        
        rich_content = self._build_rich_content(trigger, category, context)
        
        return title, body, rich_content
    
    def _build_rich_content(
        self,
        trigger: NotificationTrigger,
        category: NotificationCategory,
        context: NotificationContext
    ) -> Dict[str, Any]:
        """Build rich content for notification (charts, stats, etc.)"""
        
        rich_content = {
            "category_icon": self._get_category_icon(category),
            "show_chart": False,
            "chart_data": None,
            "stats": [],
            "chips": [],
        }
        
        if trigger.trigger_type == "transaction_created":
            txn = trigger.data.get("transaction", {})
            
            rich_content["chips"] = [
                txn.get("category", "Uncategorized"),
                f"₹{txn.get('amount', 0):.2f}"
            ]
            
            if context.budget_status:
                rich_content["stats"].append({
                    "label": "Budget Used",
                    "value": f"{context.budget_status.get('percentage_used', 0):.0f}%",
                    "progress": context.budget_status.get('percentage_used', 0) / 100.0
                })
            
            if context.user_average:
                comparison = ((txn.get('amount', 0) - context.user_average) / context.user_average) * 100
                rich_content["stats"].append({
                    "label": "vs Your Average",
                    "value": f"{comparison:+.0f}%",
                    "is_positive": comparison < 0  # Lower spending is positive
                })
        
        return rich_content
    
    def _get_category_icon(self, category: NotificationCategory) -> str:
        """Get emoji icon for category"""
        icons = {
            NotificationCategory.SMART_TRANSACTION: "💳",
            NotificationCategory.FRAUD_DETECTION: "🚨",
            NotificationCategory.BUDGET_ALERT: "📊",
            NotificationCategory.SPENDING_INSIGHT: "💡",
            NotificationCategory.BILL_REMINDER: "📅",
            NotificationCategory.EMI_LOAN: "🏦",
            NotificationCategory.GOAL_PROGRESS: "🎯",
            NotificationCategory.SAVINGS_OPPORTUNITY: "💰",
            NotificationCategory.INCOME_TRACKING: "📈",
            NotificationCategory.CASHFLOW_PREDICTION: "🔮",
            NotificationCategory.AI_INSIGHT: "🎓",
            NotificationCategory.PROACTIVE_RECOMMENDATION: "✨",
        }
        return icons.get(category, "🔔")
    
    def _determine_category(self, trigger: NotificationTrigger) -> NotificationCategory:
        """Determine notification category from trigger"""
        
        mapping = {
            "transaction_created": NotificationCategory.SMART_TRANSACTION,
            "budget_threshold": NotificationCategory.BUDGET_ALERT,
            "bill_due": NotificationCategory.BILL_REMINDER,
            "goal_milestone": NotificationCategory.GOAL_PROGRESS,
            "anomaly_detected": NotificationCategory.FRAUD_DETECTION,
            "insight_generated": NotificationCategory.AI_INSIGHT,
            "cashflow_prediction": NotificationCategory.CASHFLOW_PREDICTION,
        }
        
        return mapping.get(trigger.trigger_type, NotificationCategory.SMART_TRANSACTION)
    
    def _determine_priority(
        self,
        importance_score: float,
        relevance_score: float,
        category: NotificationCategory
    ) -> NotificationPriority:
        """Determine notification priority"""
        
        # Critical categories always get high priority
        if category == NotificationCategory.FRAUD_DETECTION:
            return NotificationPriority.CRITICAL
        
        # Score-based priority
        combined_score = (importance_score + relevance_score) / 2
        
        if combined_score >= 85:
            return NotificationPriority.HIGH
        elif combined_score >= 65:
            return NotificationPriority.MEDIUM
        elif combined_score >= 40:
            return NotificationPriority.LOW
        else:
            return NotificationPriority.INFO
    
    def _determine_channels(
        self,
        priority: NotificationPriority,
        category: NotificationCategory,
        user_preferences: UserNotificationPreferences
    ) -> List[NotificationChannel]:
        """Determine which channels to use for delivery"""
        
        # Check user preferences first
        if category in user_preferences.channel_preferences:
            return user_preferences.channel_preferences[category]
        
        # Default channel selection based on priority
        if priority == NotificationPriority.CRITICAL:
            return [
                NotificationChannel.PUSH,
                NotificationChannel.IN_APP,
                NotificationChannel.SMS,
                NotificationChannel.EMAIL
            ]
        elif priority == NotificationPriority.HIGH:
            return [NotificationChannel.PUSH, NotificationChannel.IN_APP]
        elif priority == NotificationPriority.MEDIUM:
            return [NotificationChannel.IN_APP, NotificationChannel.EMAIL]
        else:
            return [NotificationChannel.IN_APP]
    
    def _determine_actions(
        self,
        category: NotificationCategory,
        trigger: NotificationTrigger
    ) -> List[NotificationAction]:
        """Determine available actions for this notification"""
        
        base_actions = [NotificationAction.VIEW, NotificationAction.DISMISS]
        
        if category == NotificationCategory.FRAUD_DETECTION:
            base_actions.extend([
                NotificationAction.MARK_SAFE,
                NotificationAction.REPORT_FRAUD
            ])
        elif category == NotificationCategory.SMART_TRANSACTION:
            base_actions.append(NotificationAction.EDIT_CATEGORY)
        elif category == NotificationCategory.BILL_REMINDER:
            base_actions.extend([
                NotificationAction.PAY_NOW,
                NotificationAction.SNOOZE
            ])
        elif category == NotificationCategory.BUDGET_ALERT:
            base_actions.extend([
                NotificationAction.VIEW_BUDGET,
                NotificationAction.GET_TIPS
            ])
        elif category == NotificationCategory.GOAL_PROGRESS:
            base_actions.append(NotificationAction.ADD_MONEY)
        elif category in [NotificationCategory.SPENDING_INSIGHT, NotificationCategory.AI_INSIGHT]:
            base_actions.append(NotificationAction.VIEW_BREAKDOWN)
        
        return base_actions
    
    def _check_rate_limit(
        self,
        user_id: str,
        preferences: UserNotificationPreferences
    ) -> bool:
        """Check if user hasn't exceeded rate limits"""
        
        now = datetime.now()
        
        # Reset counters if needed
        if user_id not in self.last_reset:
            self.last_reset[user_id] = now
            self.notification_counts[user_id] = {'hour': 0, 'day': 0}
        
        last_reset = self.last_reset[user_id]
        
        # Reset hourly counter
        if (now - last_reset).total_seconds() >= 3600:
            self.notification_counts[user_id]['hour'] = 0
            self.last_reset[user_id] = now
        
        # Reset daily counter
        if (now - last_reset).days >= 1:
            self.notification_counts[user_id]['day'] = 0
            self.last_reset[user_id] = now
        
        # Check limits
        counts = self.notification_counts[user_id]
        if counts['hour'] >= preferences.max_notifications_per_hour:
            return False
        if counts['day'] >= preferences.max_notifications_per_day:
            return False
        
        return True
    
    def _increment_rate_limit(self, user_id: str):
        """Increment rate limiting counters"""
        self.notification_counts[user_id]['hour'] += 1
        self.notification_counts[user_id]['day'] += 1
    
    def _is_quiet_hours(self, preferences: UserNotificationPreferences) -> bool:
        """Check if it's currently quiet hours"""
        
        if not preferences.quiet_hours_enabled:
            return False
        
        current_hour = datetime.now().hour
        start = preferences.quiet_hours_start
        end = preferences.quiet_hours_end
        
        if start < end:
            return start <= current_hour < end
        else:  # Quiet hours span midnight
            return current_hour >= start or current_hour < end
    
    async def _store_notification(self, notification: Notification):
        """Store notification in database"""
        
        if self.db:
            try:
                notification_dict = notification.to_dict()
                await self.db.collection('notifications').document(notification.id).set(notification_dict)
                logger.debug(f"💾 Stored notification {notification.id}")
            except Exception as e:
                logger.error(f"❌ Error storing notification: {e}")
        
        # Keep in memory as well
        self.notification_history[notification.user_id].append(notification)
    
    async def record_notification_interaction(
        self,
        notification_id: str,
        action: NotificationAction,
        user_id: str
    ):
        """Record user interaction with notification for learning"""
        
        try:
            # Update notification
            if self.db:
                await self.db.collection('notifications').document(notification_id).update({
                    'action_taken': action.value,
                    'action_taken_at': datetime.now().isoformat(),
                    'is_read': True,
                })
            
            # Learn from interaction
            await self.personalization.record_interaction(notification_id, action, user_id)
            
            logger.debug(f"📊 Recorded interaction: {action.value} for {notification_id}")
            
        except Exception as e:
            logger.error(f"❌ Error recording interaction: {e}")

