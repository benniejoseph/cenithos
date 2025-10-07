"""
Notification Types and Data Models
"""

from enum import Enum
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from datetime import datetime


class NotificationCategory(str, Enum):
    """12 notification categories for financial intelligence"""
    
    # Transaction Alerts
    SMART_TRANSACTION = "smart_transaction"
    FRAUD_DETECTION = "fraud_detection"
    
    # Budget & Spending
    BUDGET_ALERT = "budget_alert"
    SPENDING_INSIGHT = "spending_insight"
    
    # Bills & Payments
    BILL_REMINDER = "bill_reminder"
    EMI_LOAN = "emi_loan"
    
    # Savings & Goals
    GOAL_PROGRESS = "goal_progress"
    SAVINGS_OPPORTUNITY = "savings_opportunity"
    
    # Income & Cashflow
    INCOME_TRACKING = "income_tracking"
    CASHFLOW_PREDICTION = "cashflow_prediction"
    
    # Insights & Recommendations
    AI_INSIGHT = "ai_insight"
    PROACTIVE_RECOMMENDATION = "proactive_recommendation"


class NotificationPriority(str, Enum):
    """Notification priority levels"""
    CRITICAL = "critical"  # 🔴 Fraud, unauthorized transaction
    HIGH = "high"          # 🟠 Budget exceeded, bill due today
    MEDIUM = "medium"      # 🟡 Bill reminder (3 days), insight
    LOW = "low"            # 🔵 Weekly summary
    INFO = "info"          # 🟢 Achievement, tip


class NotificationChannel(str, Enum):
    """Delivery channels for notifications"""
    PUSH = "push"
    IN_APP = "in_app"
    EMAIL = "email"
    SMS = "sms"
    WIDGET = "widget"


class NotificationAction(str, Enum):
    """Actions users can take on notifications"""
    VIEW = "view"
    DISMISS = "dismiss"
    SNOOZE = "snooze"
    MARK_SAFE = "mark_safe"
    REPORT_FRAUD = "report_fraud"
    EDIT_CATEGORY = "edit_category"
    PAY_NOW = "pay_now"
    VIEW_BUDGET = "view_budget"
    ADD_MONEY = "add_money"
    VIEW_BREAKDOWN = "view_breakdown"
    GET_TIPS = "get_tips"
    ADJUST_SETTINGS = "adjust_settings"


@dataclass
class NotificationContext:
    """Rich context information for notifications"""
    
    # Core context
    user_spending_pattern: Dict[str, Any] = field(default_factory=dict)
    budget_status: Dict[str, Any] = field(default_factory=dict)
    financial_health_score: Optional[float] = None
    
    # Transaction context
    transaction_history: List[Dict[str, Any]] = field(default_factory=list)
    similar_transactions: List[Dict[str, Any]] = field(default_factory=list)
    merchant_history: Dict[str, Any] = field(default_factory=dict)
    
    # Time context
    time_of_day: str = ""
    day_of_week: str = ""
    is_unusual_time: bool = False
    
    # Comparative context
    user_average: Optional[float] = None
    category_average: Optional[float] = None
    previous_month_comparison: Optional[float] = None
    
    # Predictive context
    forecast_impact: Optional[str] = None
    risk_score: Optional[float] = None
    
    # AI-generated insights
    gemini_analysis: Optional[str] = None
    recommendations: List[str] = field(default_factory=list)


@dataclass
class Notification:
    """Main notification data model"""
    
    # Identification
    id: str
    user_id: str
    category: NotificationCategory
    priority: NotificationPriority
    
    # Content
    title: str
    body: str
    rich_content: Optional[Dict[str, Any]] = None
    
    # Metadata
    timestamp: datetime = field(default_factory=datetime.now)
    importance_score: float = 0.0  # 0-100
    relevance_score: float = 0.0   # 0-100
    
    # Context
    context: NotificationContext = field(default_factory=NotificationContext)
    
    # Related data
    related_transaction_id: Optional[str] = None
    related_budget_id: Optional[str] = None
    related_goal_id: Optional[str] = None
    
    # Delivery
    channels: List[NotificationChannel] = field(default_factory=list)
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    
    # Interaction
    opened_at: Optional[datetime] = None
    action_taken: Optional[NotificationAction] = None
    action_taken_at: Optional[datetime] = None
    dismissed_at: Optional[datetime] = None
    snoozed_until: Optional[datetime] = None
    
    # Status
    is_read: bool = False
    is_archived: bool = False
    is_deleted: bool = False
    
    # Actions available
    available_actions: List[NotificationAction] = field(default_factory=list)
    
    # Personalization
    optimal_delivery_time: Optional[datetime] = None
    user_preference_score: float = 1.0  # How well this matches user prefs
    
    # A/B testing
    variant: Optional[str] = None
    test_group: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage/API"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'category': self.category.value,
            'priority': self.priority.value,
            'title': self.title,
            'body': self.body,
            'rich_content': self.rich_content,
            'timestamp': self.timestamp.isoformat(),
            'importance_score': self.importance_score,
            'relevance_score': self.relevance_score,
            'context': {
                'user_spending_pattern': self.context.user_spending_pattern,
                'budget_status': self.context.budget_status,
                'financial_health_score': self.context.financial_health_score,
                'gemini_analysis': self.context.gemini_analysis,
                'recommendations': self.context.recommendations,
            },
            'related_transaction_id': self.related_transaction_id,
            'related_budget_id': self.related_budget_id,
            'related_goal_id': self.related_goal_id,
            'channels': [c.value for c in self.channels],
            'sent_at': self.sent_at.isoformat() if self.sent_at else None,
            'delivered_at': self.delivered_at.isoformat() if self.delivered_at else None,
            'opened_at': self.opened_at.isoformat() if self.opened_at else None,
            'action_taken': self.action_taken.value if self.action_taken else None,
            'action_taken_at': self.action_taken_at.isoformat() if self.action_taken_at else None,
            'is_read': self.is_read,
            'is_archived': self.is_archived,
            'available_actions': [a.value for a in self.available_actions],
            'optimal_delivery_time': self.optimal_delivery_time.isoformat() if self.optimal_delivery_time else None,
            'user_preference_score': self.user_preference_score,
        }


@dataclass
class UserNotificationPreferences:
    """User preferences for notifications"""
    
    user_id: str
    
    # Global settings
    notifications_enabled: bool = True
    quiet_hours_enabled: bool = False
    quiet_hours_start: int = 22  # 10 PM
    quiet_hours_end: int = 7     # 7 AM
    
    # Category preferences
    category_preferences: Dict[NotificationCategory, bool] = field(default_factory=dict)
    
    # Channel preferences by category
    channel_preferences: Dict[NotificationCategory, List[NotificationChannel]] = field(default_factory=dict)
    
    # Threshold settings
    high_value_threshold: float = 5000.0
    budget_alert_thresholds: List[float] = field(default_factory=lambda: [0.75, 0.90, 1.0, 1.1])
    bill_reminder_days: List[int] = field(default_factory=lambda: [7, 3, 1, 0])
    
    # Smart settings
    auto_bundle_notifications: bool = True
    bundle_delay_minutes: int = 30
    learn_optimal_times: bool = True
    enable_predictive_alerts: bool = True
    
    # Frequency limits
    max_notifications_per_hour: int = 10
    max_notifications_per_day: int = 50
    
    # Content preferences
    show_insights: bool = True
    show_recommendations: bool = True
    show_comparisons: bool = False  # Anonymous comparison with similar users
    show_charts: bool = True
    
    # Custom rules
    custom_rules: List[Dict[str, Any]] = field(default_factory=list)
    # Example: {"category": "food", "threshold": 200, "action": "suppress"}
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'user_id': self.user_id,
            'notifications_enabled': self.notifications_enabled,
            'quiet_hours_enabled': self.quiet_hours_enabled,
            'quiet_hours_start': self.quiet_hours_start,
            'quiet_hours_end': self.quiet_hours_end,
            'category_preferences': {
                k.value: v for k, v in self.category_preferences.items()
            },
            'channel_preferences': {
                k.value: [c.value for c in v] 
                for k, v in self.channel_preferences.items()
            },
            'high_value_threshold': self.high_value_threshold,
            'budget_alert_thresholds': self.budget_alert_thresholds,
            'bill_reminder_days': self.bill_reminder_days,
            'auto_bundle_notifications': self.auto_bundle_notifications,
            'bundle_delay_minutes': self.bundle_delay_minutes,
            'learn_optimal_times': self.learn_optimal_times,
            'enable_predictive_alerts': self.enable_predictive_alerts,
            'max_notifications_per_hour': self.max_notifications_per_hour,
            'max_notifications_per_day': self.max_notifications_per_day,
            'show_insights': self.show_insights,
            'show_recommendations': self.show_recommendations,
            'show_comparisons': self.show_comparisons,
            'show_charts': self.show_charts,
            'custom_rules': self.custom_rules,
        }


@dataclass
class NotificationTrigger:
    """Event that triggers a notification"""
    
    trigger_type: str
    user_id: str
    data: Dict[str, Any]
    timestamp: datetime = field(default_factory=datetime.now)
    priority_override: Optional[NotificationPriority] = None
    
    # Transaction triggers
    @staticmethod
    def transaction_created(user_id: str, transaction: Dict[str, Any]):
        return NotificationTrigger(
            trigger_type="transaction_created",
            user_id=user_id,
            data={"transaction": transaction}
        )
    
    # Budget triggers
    @staticmethod
    def budget_threshold_reached(user_id: str, budget_id: str, percentage: float):
        return NotificationTrigger(
            trigger_type="budget_threshold",
            user_id=user_id,
            data={"budget_id": budget_id, "percentage": percentage}
        )
    
    # Bill triggers
    @staticmethod
    def bill_due_soon(user_id: str, bill: Dict[str, Any], days_until_due: int):
        return NotificationTrigger(
            trigger_type="bill_due",
            user_id=user_id,
            data={"bill": bill, "days_until_due": days_until_due}
        )
    
    # Goal triggers
    @staticmethod
    def goal_milestone_reached(user_id: str, goal_id: str, milestone_percentage: float):
        return NotificationTrigger(
            trigger_type="goal_milestone",
            user_id=user_id,
            data={"goal_id": goal_id, "milestone": milestone_percentage}
        )
    
    # Anomaly triggers
    @staticmethod
    def anomaly_detected(user_id: str, transaction: Dict[str, Any], anomaly_reasons: List[str]):
        return NotificationTrigger(
            trigger_type="anomaly_detected",
            user_id=user_id,
            data={"transaction": transaction, "reasons": anomaly_reasons},
            priority_override=NotificationPriority.CRITICAL
        )
    
    # Insight triggers
    @staticmethod
    def insight_generated(user_id: str, insight_type: str, insight_data: Dict[str, Any]):
        return NotificationTrigger(
            trigger_type="insight_generated",
            user_id=user_id,
            data={"insight_type": insight_type, "insight_data": insight_data}
        )

