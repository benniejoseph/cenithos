"""
Personalization & Learning Engine
===================================

Learns from user behavior to personalize notifications:
- Optimal delivery times
- Relevance scoring
- Interaction patterns
- Preference learning
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from collections import defaultdict, Counter

from .notification_types import (
    NotificationTrigger,
    NotificationContext,
    NotificationCategory,
    NotificationAction,
    NotificationChannel,
    UserNotificationPreferences,
)

logger = logging.getLogger(__name__)


class PersonalizationEngine:
    """Learn from user interactions to personalize notifications"""
    
    def __init__(self, db_client=None):
        self.db = db_client
        self._user_profiles: Dict[str, Dict[str, Any]] = {}
        self._interaction_history: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        logger.info("🎯 Personalization Engine initialized")
    
    async def get_user_preferences(
        self,
        user_id: str
    ) -> UserNotificationPreferences:
        """Load or create user notification preferences"""
        
        if self.db:
            try:
                # Try to load from database
                pref_ref = self.db.collection('notification_preferences').document(user_id)
                pref_doc = pref_ref.get()
                
                if pref_doc.exists:
                    data = pref_doc.to_dict()
                    return self._dict_to_preferences(user_id, data)
                    
            except Exception as e:
                logger.error(f"Error loading preferences: {e}")
        
        # Return default preferences
        return UserNotificationPreferences(user_id=user_id)
    
    async def save_user_preferences(
        self,
        preferences: UserNotificationPreferences
    ):
        """Save user notification preferences"""
        
        if not self.db:
            return
        
        try:
            pref_ref = self.db.collection('notification_preferences').document(preferences.user_id)
            await pref_ref.set(preferences.to_dict())
            logger.debug(f"💾 Saved preferences for {preferences.user_id}")
            
        except Exception as e:
            logger.error(f"Error saving preferences: {e}")
    
    async def calculate_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        user_id: str
    ) -> float:
        """
        Calculate relevance score (0-100) based on user's interaction history.
        
        High relevance = notification matches user's interests and patterns
        """
        
        score = 50.0  # Start with neutral
        
        try:
            # Load user profile
            profile = await self._load_user_profile(user_id)
            
            if trigger.trigger_type == "transaction_created":
                score = self._calculate_transaction_relevance(trigger, context, profile)
            elif trigger.trigger_type == "budget_threshold":
                score = self._calculate_budget_relevance(trigger, context, profile)
            elif trigger.trigger_type == "bill_due":
                score = self._calculate_bill_relevance(trigger, context, profile)
            elif trigger.trigger_type == "goal_milestone":
                score = self._calculate_goal_relevance(trigger, context, profile)
            elif trigger.trigger_type == "insight_generated":
                score = self._calculate_insight_relevance(trigger, context, profile)
            
            # Boost/reduce based on interaction history
            interaction_boost = self._calculate_interaction_boost(user_id, trigger.trigger_type)
            score += interaction_boost
            
            # Cap between 0-100
            score = max(0.0, min(100.0, score))
            
            logger.debug(f"🎯 Relevance score: {score:.1f} for {trigger.trigger_type}")
            
        except Exception as e:
            logger.error(f"❌ Error calculating relevance: {e}")
            score = 50.0
        
        return score
    
    def _calculate_transaction_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        profile: Dict[str, Any]
    ) -> float:
        """Calculate relevance for transaction notifications"""
        
        txn = trigger.data.get("transaction", {})
        category = txn.get("category", "")
        amount = abs(float(txn.get("amount", 0)))
        
        score = 50.0
        
        # Check if user cares about this category
        category_interest = profile.get('category_interests', {}).get(category, 0.5)
        score += (category_interest - 0.5) * 40  # -20 to +20
        
        # Check if amount is significant for this user
        avg_transaction = profile.get('average_transaction_amount', 1000)
        if amount >= avg_transaction * 2:
            score += 20
        elif amount >= avg_transaction:
            score += 10
        
        # Budget awareness
        if context.budget_status and context.budget_status.get('has_budget'):
            score += 15  # User with budgets cares more about spending
        
        return score
    
    def _calculate_budget_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        profile: Dict[str, Any]
    ) -> float:
        """Calculate relevance for budget notifications"""
        
        score = 60.0  # Budget alerts are generally relevant
        
        # If user has history of exceeding budgets, make more relevant
        if profile.get('frequently_exceeds_budget', False):
            score += 20
        
        # If user has interacted positively with budget alerts before
        budget_engagement = profile.get('engagement_scores', {}).get('budget_alert', 0.5)
        score += (budget_engagement - 0.5) * 40
        
        return score
    
    def _calculate_bill_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        profile: Dict[str, Any]
    ) -> float:
        """Calculate relevance for bill notifications"""
        
        days_until_due = trigger.data.get("days_until_due", 7)
        
        score = 50.0
        
        # Urgency boosts relevance
        if days_until_due <= 1:
            score += 30
        elif days_until_due <= 3:
            score += 20
        elif days_until_due <= 7:
            score += 10
        
        # Check user's bill payment patterns
        if profile.get('frequently_late_on_bills', False):
            score += 20  # More relevant for people who forget
        
        # Engagement with bill reminders
        bill_engagement = profile.get('engagement_scores', {}).get('bill_reminder', 0.5)
        score += (bill_engagement - 0.5) * 20
        
        return score
    
    def _calculate_goal_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        profile: Dict[str, Any]
    ) -> float:
        """Calculate relevance for goal notifications"""
        
        score = 55.0  # Goals are moderately relevant
        
        # Check engagement with goals
        goal_engagement = profile.get('engagement_scores', {}).get('goal_progress', 0.5)
        score += (goal_engagement - 0.5) * 50  # Strong weight on engagement
        
        # Active goal users care more
        if profile.get('has_active_goals', False):
            score += 20
        
        return score
    
    def _calculate_insight_relevance(
        self,
        trigger: NotificationTrigger,
        context: NotificationContext,
        profile: Dict[str, Any]
    ) -> float:
        """Calculate relevance for AI insights"""
        
        score = 45.0  # Insights are less urgent but valuable
        
        # Check engagement with insights
        insight_engagement = profile.get('engagement_scores', {}).get('ai_insight', 0.5)
        score += (insight_engagement - 0.5) * 60  # Very strong weight
        
        # Power users care more about insights
        if profile.get('engagement_level', 'medium') == 'high':
            score += 20
        
        return score
    
    def _calculate_interaction_boost(
        self,
        user_id: str,
        trigger_type: str
    ) -> float:
        """Calculate boost/penalty based on past interactions"""
        
        interactions = self._interaction_history.get(user_id, [])
        
        if not interactions:
            return 0.0
        
        # Get interactions for this trigger type
        relevant_interactions = [
            i for i in interactions[-20:]  # Last 20 interactions
            if i.get('trigger_type') == trigger_type
        ]
        
        if not relevant_interactions:
            return 0.0
        
        # Calculate engagement rate
        opened = sum(1 for i in relevant_interactions if i.get('opened', False))
        acted = sum(1 for i in relevant_interactions if i.get('action_taken'))
        dismissed_quickly = sum(
            1 for i in relevant_interactions 
            if i.get('dismissed_within_seconds', 0) < 5
        )
        
        total = len(relevant_interactions)
        
        # Calculate boost
        open_rate = opened / total
        action_rate = acted / total
        quick_dismiss_rate = dismissed_quickly / total
        
        boost = 0.0
        boost += (open_rate - 0.5) * 20  # -10 to +10
        boost += (action_rate - 0.3) * 25  # -7.5 to +17.5
        boost -= quick_dismiss_rate * 15   # 0 to -15
        
        return boost
    
    async def calculate_optimal_delivery_time(
        self,
        user_id: str,
        category: NotificationCategory
    ) -> Optional[datetime]:
        """
        Calculate optimal time to deliver notification based on user's interaction patterns.
        """
        
        try:
            profile = await self._load_user_profile(user_id)
            
            # Get user's active hours
            active_hours = profile.get('active_hours', {})
            
            if not active_hours:
                return None  # Deliver immediately
            
            # Find peak engagement hours
            peak_hours = sorted(
                active_hours.items(),
                key=lambda x: x[1],
                reverse=True
            )[:3]  # Top 3 hours
            
            if not peak_hours:
                return None
            
            # Get next occurrence of a peak hour
            current_time = datetime.now()
            current_hour = current_time.hour
            
            peak_hour_values = [int(h[0]) for h in peak_hours]
            
            # Find next peak hour
            for hour in sorted(peak_hour_values):
                if hour > current_hour:
                    optimal_time = current_time.replace(
                        hour=hour,
                        minute=0,
                        second=0,
                        microsecond=0
                    )
                    
                    # Don't schedule too far in future (max 8 hours)
                    if (optimal_time - current_time).total_seconds() <= 8 * 3600:
                        return optimal_time
            
            # If no future hour today, schedule for tomorrow's first peak hour
            optimal_time = current_time.replace(
                hour=peak_hour_values[0],
                minute=0,
                second=0,
                microsecond=0
            ) + timedelta(days=1)
            
            return optimal_time
            
        except Exception as e:
            logger.error(f"Error calculating optimal time: {e}")
            return None
    
    async def record_notification_created(self, notification):
        """Record that a notification was created (for learning)"""
        
        try:
            user_id = notification.user_id
            
            if user_id not in self._interaction_history:
                self._interaction_history[user_id] = []
            
            self._interaction_history[user_id].append({
                'notification_id': notification.id,
                'category': notification.category.value,
                'created_at': datetime.now().isoformat(),
                'importance_score': notification.importance_score,
                'relevance_score': notification.relevance_score,
            })
            
            # Keep only last 100 interactions per user
            if len(self._interaction_history[user_id]) > 100:
                self._interaction_history[user_id] = self._interaction_history[user_id][-100:]
            
        except Exception as e:
            logger.error(f"Error recording notification: {e}")
    
    async def record_interaction(
        self,
        notification_id: str,
        action: NotificationAction,
        user_id: str
    ):
        """Record user interaction with notification"""
        
        try:
            # Find the notification in history
            for interaction in self._interaction_history.get(user_id, []):
                if interaction.get('notification_id') == notification_id:
                    interaction['opened'] = True
                    interaction['action_taken'] = action.value
                    interaction['action_taken_at'] = datetime.now().isoformat()
                    
                    # Calculate dismissal time
                    created_at = datetime.fromisoformat(interaction['created_at'])
                    dismissed_seconds = (datetime.now() - created_at).total_seconds()
                    interaction['dismissed_within_seconds'] = dismissed_seconds
                    
                    break
            
            # Update user profile based on interaction
            await self._update_profile_from_interaction(user_id, notification_id, action)
            
            logger.debug(f"📊 Recorded interaction: {action.value}")
            
        except Exception as e:
            logger.error(f"Error recording interaction: {e}")
    
    async def _load_user_profile(self, user_id: str) -> Dict[str, Any]:
        """Load or build user profile for personalization"""
        
        # Check cache
        if user_id in self._user_profiles:
            return self._user_profiles[user_id]
        
        # Build profile
        profile = {
            'user_id': user_id,
            'category_interests': {},
            'engagement_scores': {},
            'active_hours': {},
            'average_transaction_amount': 0.0,
            'engagement_level': 'medium',
            'has_active_goals': False,
            'frequently_exceeds_budget': False,
            'frequently_late_on_bills': False,
        }
        
        if self.db:
            try:
                # Load from database if available
                profile_ref = self.db.collection('user_notification_profiles').document(user_id)
                profile_doc = profile_ref.get()
                
                if profile_doc.exists:
                    profile.update(profile_doc.to_dict())
                
            except Exception as e:
                logger.debug(f"Building new profile for {user_id}")
        
        # Cache it
        self._user_profiles[user_id] = profile
        
        return profile
    
    async def _update_profile_from_interaction(
        self,
        user_id: str,
        notification_id: str,
        action: NotificationAction
    ):
        """Update user profile based on their interaction"""
        
        try:
            profile = await self._load_user_profile(user_id)
            
            # Find the interaction
            for interaction in self._interaction_history.get(user_id, []):
                if interaction.get('notification_id') == notification_id:
                    category = interaction.get('category', '')
                    
                    # Update engagement scores
                    if category not in profile['engagement_scores']:
                        profile['engagement_scores'][category] = 0.5
                    
                    # Positive actions increase score
                    if action in [NotificationAction.VIEW, NotificationAction.PAY_NOW, NotificationAction.ADD_MONEY]:
                        profile['engagement_scores'][category] = min(
                            1.0,
                            profile['engagement_scores'][category] + 0.1
                        )
                    # Negative actions decrease score
                    elif action == NotificationAction.DISMISS:
                        dismiss_time = interaction.get('dismissed_within_seconds', 10)
                        if dismiss_time < 5:  # Quick dismiss = not interested
                            profile['engagement_scores'][category] = max(
                                0.0,
                                profile['engagement_scores'][category] - 0.1
                            )
                    
                    # Track active hours
                    hour = datetime.now().hour
                    if str(hour) not in profile['active_hours']:
                        profile['active_hours'][str(hour)] = 0
                    profile['active_hours'][str(hour)] += 1
                    
                    break
            
            # Save updated profile
            if self.db:
                profile_ref = self.db.collection('user_notification_profiles').document(user_id)
                await profile_ref.set(profile)
            
            # Update cache
            self._user_profiles[user_id] = profile
            
        except Exception as e:
            logger.error(f"Error updating profile: {e}")
    
    def _dict_to_preferences(
        self,
        user_id: str,
        data: Dict[str, Any]
    ) -> UserNotificationPreferences:
        """Convert dictionary to UserNotificationPreferences object"""
        
        # Convert category preferences
        category_prefs = {}
        for key, value in data.get('category_preferences', {}).items():
            try:
                category_prefs[NotificationCategory(key)] = value
            except ValueError:
                pass
        
        # Convert channel preferences
        channel_prefs = {}
        for key, values in data.get('channel_preferences', {}).items():
            try:
                category = NotificationCategory(key)
                channels = [NotificationChannel(v) for v in values]
                channel_prefs[category] = channels
            except ValueError:
                pass
        
        return UserNotificationPreferences(
            user_id=user_id,
            notifications_enabled=data.get('notifications_enabled', True),
            quiet_hours_enabled=data.get('quiet_hours_enabled', False),
            quiet_hours_start=data.get('quiet_hours_start', 22),
            quiet_hours_end=data.get('quiet_hours_end', 7),
            category_preferences=category_prefs,
            channel_preferences=channel_prefs,
            high_value_threshold=data.get('high_value_threshold', 5000.0),
            budget_alert_thresholds=data.get('budget_alert_thresholds', [0.75, 0.90, 1.0, 1.1]),
            bill_reminder_days=data.get('bill_reminder_days', [7, 3, 1, 0]),
            auto_bundle_notifications=data.get('auto_bundle_notifications', True),
            bundle_delay_minutes=data.get('bundle_delay_minutes', 30),
            learn_optimal_times=data.get('learn_optimal_times', True),
            enable_predictive_alerts=data.get('enable_predictive_alerts', True),
            max_notifications_per_hour=data.get('max_notifications_per_hour', 10),
            max_notifications_per_day=data.get('max_notifications_per_day', 50),
            show_insights=data.get('show_insights', True),
            show_recommendations=data.get('show_recommendations', True),
            show_comparisons=data.get('show_comparisons', False),
            show_charts=data.get('show_charts', True),
            custom_rules=data.get('custom_rules', []),
        )

