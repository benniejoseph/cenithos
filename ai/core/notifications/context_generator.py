"""
Context Generator
=================

Generates rich context for notifications by analyzing:
- User spending patterns
- Budget status
- Transaction history
- Merchant history
- Financial health metrics
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from collections import defaultdict

from .notification_types import (
    NotificationTrigger,
    NotificationContext,
    UserNotificationPreferences
)

logger = logging.getLogger(__name__)


class ContextGenerator:
    """Generate rich context for notifications"""
    
    def __init__(self, db_client=None):
        self.db = db_client
        self._user_cache: Dict[str, Dict[str, Any]] = {}
        logger.info("📝 Context Generator initialized")
    
    async def generate_context(
        self,
        trigger: NotificationTrigger,
        user_preferences: UserNotificationPreferences
    ) -> NotificationContext:
        """
        Generate comprehensive context for a notification.
        
        Returns:
            NotificationContext with all relevant contextual information
        """
        
        context = NotificationContext()
        
        try:
            user_id = trigger.user_id
            
            # 1. Get spending patterns
            context.user_spending_pattern = await self._get_spending_patterns(user_id)
            
            # 2. Get budget status
            if trigger.trigger_type in ["transaction_created", "budget_threshold"]:
                context.budget_status = await self._get_budget_status(
                    user_id,
                    trigger.data.get("transaction", {}).get("category", "")
                )
            
            # 3. Get transaction history
            context.transaction_history = await self._get_transaction_history(
                user_id, limit=50
            )
            
            # 4. Get similar transactions
            if trigger.trigger_type == "transaction_created":
                txn = trigger.data.get("transaction", {})
                context.similar_transactions = await self._find_similar_transactions(
                    user_id, txn
                )
                context.merchant_history = await self._get_merchant_history(
                    user_id, txn.get("vendor", "")
                )
            
            # 5. Calculate averages
            if trigger.trigger_type == "transaction_created":
                txn = trigger.data.get("transaction", {})
                category = txn.get("category", "")
                context.user_average = self._calculate_category_average(
                    context.transaction_history, category
                )
                context.category_average = context.user_average  # Same for now
            
            # 6. Time context
            context.time_of_day = self._get_time_of_day()
            context.day_of_week = datetime.now().strftime("%A")
            context.is_unusual_time = self._is_unusual_time(
                datetime.now(), context.transaction_history
            )
            
            # 7. Comparative context
            if trigger.trigger_type == "transaction_created":
                context.previous_month_comparison = await self._get_month_comparison(
                    user_id, trigger.data.get("transaction", {}).get("category", "")
                )
            
            # 8. Financial health score
            context.financial_health_score = await self._calculate_financial_health(
                user_id, context
            )
            
            logger.debug(f"📝 Generated context for {trigger.trigger_type}")
            
        except Exception as e:
            logger.error(f"❌ Error generating context: {e}", exc_info=True)
        
        return context
    
    async def _get_spending_patterns(self, user_id: str) -> Dict[str, Any]:
        """Analyze user's spending patterns"""
        
        patterns = {
            'usual_categories': [],
            'unusual_categories': [],
            'peak_spending_hours': [],
            'average_daily_spending': 0.0,
            'average_transaction_amount': 0.0,
            'usually_exceeds_budget': False,
        }
        
        if not self.db:
            return patterns
        
        try:
            # Get last 90 days of transactions
            ninety_days_ago = (datetime.now() - timedelta(days=90)).isoformat()
            
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .where('date', '>=', ninety_days_ago) \
                .stream()
            
            transactions = [doc.to_dict() for doc in transactions_ref]
            
            if not transactions:
                return patterns
            
            # Category analysis
            category_counts = defaultdict(int)
            for txn in transactions:
                if txn.get('type') == 'expense':
                    category_counts[txn.get('category', 'Uncategorized')] += 1
            
            # Sort by frequency
            sorted_categories = sorted(
                category_counts.items(), key=lambda x: x[1], reverse=True
            )
            
            patterns['usual_categories'] = [cat for cat, count in sorted_categories[:5]]
            patterns['unusual_categories'] = [
                cat for cat, count in sorted_categories[-3:] if count == 1
            ]
            
            # Calculate averages
            total_spending = sum(
                txn.get('amount', 0) for txn in transactions 
                if txn.get('type') == 'expense'
            )
            patterns['average_daily_spending'] = total_spending / 90
            patterns['average_transaction_amount'] = total_spending / max(len(transactions), 1)
            
            # Hour analysis
            hour_counts = defaultdict(int)
            for txn in transactions:
                try:
                    txn_time = datetime.fromisoformat(txn.get('date', ''))
                    hour_counts[txn_time.hour] += 1
                except:
                    pass
            
            patterns['peak_spending_hours'] = [
                hour for hour, count in sorted(
                    hour_counts.items(), key=lambda x: x[1], reverse=True
                )[:3]
            ]
            
        except Exception as e:
            logger.error(f"Error analyzing spending patterns: {e}")
        
        return patterns
    
    async def _get_budget_status(
        self,
        user_id: str,
        category: str
    ) -> Dict[str, Any]:
        """Get current budget status for a category"""
        
        status = {
            'has_budget': False,
            'budget_amount': 0.0,
            'spent_amount': 0.0,
            'percentage_used': 0.0,
            'remaining': 0.0,
        }
        
        if not self.db or not category:
            return status
        
        try:
            # Find budget for this category
            budgets_ref = self.db.collection('budgets') \
                .where('userId', '==', user_id) \
                .where('category', '==', category) \
                .limit(1) \
                .stream()
            
            budgets = [doc.to_dict() for doc in budgets_ref]
            
            if not budgets:
                return status
            
            budget = budgets[0]
            budget_amount = float(budget.get('amount', 0))
            
            # Calculate spending for current month
            current_month = datetime.now().strftime('%Y-%m')
            
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .where('category', '==', category) \
                .where('type', '==', 'expense') \
                .stream()
            
            spent_amount = 0.0
            for doc in transactions_ref:
                txn = doc.to_dict()
                txn_date = txn.get('date', '')
                if txn_date.startswith(current_month):
                    spent_amount += float(txn.get('amount', 0))
            
            status = {
                'has_budget': True,
                'budget_amount': budget_amount,
                'spent_amount': spent_amount,
                'percentage_used': (spent_amount / budget_amount * 100) if budget_amount > 0 else 0,
                'remaining': budget_amount - spent_amount,
            }
            
        except Exception as e:
            logger.error(f"Error getting budget status: {e}")
        
        return status
    
    async def _get_transaction_history(
        self,
        user_id: str,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get recent transaction history"""
        
        if not self.db:
            return []
        
        try:
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .order_by('date', direction='DESCENDING') \
                .limit(limit) \
                .stream()
            
            return [doc.to_dict() for doc in transactions_ref]
            
        except Exception as e:
            logger.error(f"Error getting transaction history: {e}")
            return []
    
    async def _find_similar_transactions(
        self,
        user_id: str,
        transaction: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Find similar transactions (same category/vendor)"""
        
        if not self.db:
            return []
        
        try:
            category = transaction.get('category', '')
            vendor = transaction.get('vendor', '')
            
            if not category:
                return []
            
            # Get transactions in same category
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .where('category', '==', category) \
                .order_by('date', direction='DESCENDING') \
                .limit(10) \
                .stream()
            
            similar = [doc.to_dict() for doc in transactions_ref]
            
            # Filter by vendor if available
            if vendor:
                similar = [t for t in similar if t.get('vendor') == vendor]
            
            return similar[:5]  # Return top 5
            
        except Exception as e:
            logger.error(f"Error finding similar transactions: {e}")
            return []
    
    async def _get_merchant_history(
        self,
        user_id: str,
        vendor: str
    ) -> Dict[str, Any]:
        """Get history with a specific merchant"""
        
        history = {
            'transaction_count': 0,
            'total_spent': 0.0,
            'average_amount': 0.0,
            'last_transaction_date': None,
        }
        
        if not self.db or not vendor:
            return history
        
        try:
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .where('vendor', '==', vendor) \
                .stream()
            
            transactions = [doc.to_dict() for doc in transactions_ref]
            
            if transactions:
                history['transaction_count'] = len(transactions)
                history['total_spent'] = sum(t.get('amount', 0) for t in transactions)
                history['average_amount'] = history['total_spent'] / len(transactions)
                
                # Get most recent transaction date
                dates = [t.get('date') for t in transactions if t.get('date')]
                if dates:
                    history['last_transaction_date'] = max(dates)
            
        except Exception as e:
            logger.error(f"Error getting merchant history: {e}")
        
        return history
    
    def _calculate_category_average(
        self,
        transactions: List[Dict[str, Any]],
        category: str
    ) -> float:
        """Calculate average spending for a category"""
        
        category_transactions = [
            t for t in transactions
            if t.get('category') == category and t.get('type') == 'expense'
        ]
        
        if not category_transactions:
            return 0.0
        
        total = sum(t.get('amount', 0) for t in category_transactions)
        return total / len(category_transactions)
    
    def _get_time_of_day(self) -> str:
        """Get current time of day description"""
        
        hour = datetime.now().hour
        
        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"
    
    def _is_unusual_time(
        self,
        current_time: datetime,
        transaction_history: List[Dict[str, Any]]
    ) -> bool:
        """Check if current time is unusual for transactions"""
        
        if not transaction_history:
            return False
        
        # Get hours of previous transactions
        transaction_hours = []
        for txn in transaction_history:
            try:
                txn_time = datetime.fromisoformat(txn.get('date', ''))
                transaction_hours.append(txn_time.hour)
            except:
                pass
        
        if not transaction_hours:
            return False
        
        # Calculate average hour
        avg_hour = sum(transaction_hours) / len(transaction_hours)
        current_hour = current_time.hour
        
        # If more than 4 hours different from average, it's unusual
        return abs(current_hour - avg_hour) > 4
    
    async def _get_month_comparison(
        self,
        user_id: str,
        category: str
    ) -> Optional[float]:
        """Compare current month vs previous month spending"""
        
        if not self.db or not category:
            return None
        
        try:
            current_month = datetime.now().strftime('%Y-%m')
            previous_month = (datetime.now() - timedelta(days=30)).strftime('%Y-%m')
            
            # Get transactions for both months
            transactions_ref = self.db.collection('transactions') \
                .where('userId', '==', user_id) \
                .where('category', '==', category) \
                .where('type', '==', 'expense') \
                .stream()
            
            current_total = 0.0
            previous_total = 0.0
            
            for doc in transactions_ref:
                txn = doc.to_dict()
                txn_date = txn.get('date', '')
                amount = float(txn.get('amount', 0))
                
                if txn_date.startswith(current_month):
                    current_total += amount
                elif txn_date.startswith(previous_month):
                    previous_total += amount
            
            if previous_total == 0:
                return None
            
            # Return percentage change
            return ((current_total - previous_total) / previous_total) * 100
            
        except Exception as e:
            logger.error(f"Error comparing months: {e}")
            return None
    
    async def _calculate_financial_health(
        self,
        user_id: str,
        context: NotificationContext
    ) -> Optional[float]:
        """Calculate overall financial health score (0-100)"""
        
        try:
            score = 50.0  # Start with neutral score
            
            # Factor 1: Budget adherence (30 points)
            if context.budget_status and context.budget_status.get('has_budget'):
                pct_used = context.budget_status.get('percentage_used', 0)
                if pct_used <= 75:
                    score += 30
                elif pct_used <= 90:
                    score += 20
                elif pct_used <= 100:
                    score += 10
                else:  # Over budget
                    score -= 10
            
            # Factor 2: Spending trends (20 points)
            if context.previous_month_comparison is not None:
                if context.previous_month_comparison < 0:  # Spending less
                    score += 20
                elif context.previous_month_comparison < 10:  # Stable
                    score += 10
                else:  # Spending more
                    score -= 10
            
            return max(0.0, min(100.0, score))
            
        except Exception as e:
            logger.error(f"Error calculating financial health: {e}")
            return None

