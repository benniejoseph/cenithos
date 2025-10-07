"""
Anomaly Detector for Fraud and Unusual Activity
================================================

Detects unusual financial patterns:
- Unusual amounts
- Unusual merchants
- Unusual times/locations
- Multiple transactions in short time
- Out-of-pattern spending
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from collections import defaultdict

from .notification_types import NotificationContext

logger = logging.getLogger(__name__)


class AnomalyDetector:
    """Detect anomalies in financial transactions"""
    
    def __init__(self):
        self.user_patterns: Dict[str, Dict[str, Any]] = {}
        logger.info("🔍 Anomaly Detector initialized")
    
    async def detect_anomalies(
        self,
        transaction: Dict[str, Any],
        user_id: str,
        context: NotificationContext
    ) -> Optional[Dict[str, Any]]:
        """
        Detect if a transaction is anomalous.
        
        Returns:
            Dictionary with anomaly details or None if no anomaly
        """
        
        anomaly_reasons = []
        risk_score = 0.0
        
        try:
            amount = abs(float(transaction.get("amount", 0)))
            vendor = transaction.get("vendor", "")
            category = transaction.get("category", "")
            timestamp = transaction.get("date", datetime.now().isoformat())
            
            # 1. Check amount anomalies
            amount_anomaly = self._check_amount_anomaly(
                amount, category, context
            )
            if amount_anomaly:
                anomaly_reasons.append(amount_anomaly)
                risk_score += 0.3
            
            # 2. Check time anomalies
            time_anomaly = self._check_time_anomaly(timestamp, context)
            if time_anomaly:
                anomaly_reasons.append(time_anomaly)
                risk_score += 0.2
            
            # 3. Check merchant anomalies
            merchant_anomaly = await self._check_merchant_anomaly(
                vendor, amount, user_id, context
            )
            if merchant_anomaly:
                anomaly_reasons.append(merchant_anomaly)
                risk_score += 0.3
            
            # 4. Check frequency anomalies
            frequency_anomaly = await self._check_frequency_anomaly(
                user_id, amount, context
            )
            if frequency_anomaly:
                anomaly_reasons.append(frequency_anomaly)
                risk_score += 0.4
            
            # 5. Check pattern anomalies
            pattern_anomaly = self._check_pattern_anomaly(
                transaction, context
            )
            if pattern_anomaly:
                anomaly_reasons.append(pattern_anomaly)
                risk_score += 0.3
            
            if anomaly_reasons:
                logger.warning(f"🚨 Anomaly detected for user {user_id}: {anomaly_reasons}")
                
                return {
                    'is_anomaly': True,
                    'reasons': anomaly_reasons,
                    'risk_score': min(1.0, risk_score),
                    'explanation': self._generate_explanation(anomaly_reasons, risk_score),
                    'recommended_action': self._recommend_action(risk_score)
                }
            
            return None
            
        except Exception as e:
            logger.error(f"❌ Error detecting anomalies: {e}")
            return None
    
    def _check_amount_anomaly(
        self,
        amount: float,
        category: str,
        context: NotificationContext
    ) -> Optional[str]:
        """Check if amount is unusual"""
        
        # Check against user average
        if context.user_average and context.user_average > 0:
            ratio = amount / context.user_average
            
            if ratio >= 5.0:
                return f"5x your usual {category} spending"
            elif ratio >= 3.0:
                return f"3x your usual {category} spending"
            elif ratio >= 2.0 and amount >= 5000:
                return f"2x your usual {category} spending"
        
        # Absolute high amounts
        if amount >= 50000:
            return f"Very high amount: ₹{amount:,.2f}"
        elif amount >= 25000 and category.lower() not in ['rent', 'loan emi', 'investment']:
            return f"Unusually high amount for {category}"
        
        return None
    
    def _check_time_anomaly(
        self,
        timestamp: str,
        context: NotificationContext
    ) -> Optional[str]:
        """Check if transaction time is unusual"""
        
        try:
            if isinstance(timestamp, str):
                dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            else:
                dt = timestamp
            
            hour = dt.hour
            
            # Very late night or very early morning
            if hour >= 2 and hour <= 5:
                return f"Transaction at {hour:02d}:00 (unusual time)"
            
            # Check against user's usual transaction times
            if context.is_unusual_time:
                return "Transaction at unusual time for you"
            
        except Exception as e:
            logger.debug(f"Error checking time anomaly: {e}")
        
        return None
    
    async def _check_merchant_anomaly(
        self,
        vendor: str,
        amount: float,
        user_id: str,
        context: NotificationContext
    ) -> Optional[str]:
        """Check if merchant is unusual"""
        
        if not vendor or vendor == "Unknown":
            return None
        
        # Check merchant history from context
        if context.merchant_history:
            merchant_data = context.merchant_history.get(vendor, {})
            
            # First time with this merchant
            if not merchant_data:
                if amount >= 5000:
                    return f"First transaction at {vendor}"
            else:
                # Check if amount is unusual for this merchant
                avg_amount = merchant_data.get('average_amount', 0)
                if avg_amount > 0 and amount >= avg_amount * 3:
                    return f"3x your usual spending at {vendor}"
                
                # Check if it's been a long time since last transaction
                last_txn = merchant_data.get('last_transaction_date')
                if last_txn:
                    days_since = (datetime.now() - datetime.fromisoformat(last_txn)).days
                    if days_since > 180:  # 6 months
                        return f"First transaction at {vendor} in {days_since} days"
        
        return None
    
    async def _check_frequency_anomaly(
        self,
        user_id: str,
        amount: float,
        context: NotificationContext
    ) -> Optional[str]:
        """Check if transaction frequency is unusual"""
        
        # Check recent transaction history from context
        recent_transactions = context.transaction_history[-10:]  # Last 10 transactions
        
        if len(recent_transactions) < 2:
            return None
        
        # Check for multiple high-value transactions in short time
        high_value_recent = [
            t for t in recent_transactions[-5:]
            if t.get('amount', 0) >= 5000
        ]
        
        if len(high_value_recent) >= 3:
            return f"{len(high_value_recent)} high-value transactions in short time"
        
        # Check for rapid succession
        if len(recent_transactions) >= 5:
            latest = recent_transactions[-1]
            previous = recent_transactions[-5]
            
            try:
                latest_time = datetime.fromisoformat(latest.get('date', ''))
                prev_time = datetime.fromisoformat(previous.get('date', ''))
                
                time_diff = (latest_time - prev_time).total_seconds() / 60  # minutes
                
                if time_diff <= 10:  # 5 transactions in 10 minutes
                    return "Multiple transactions in very short time"
                
            except Exception:
                pass
        
        return None
    
    def _check_pattern_anomaly(
        self,
        transaction: Dict[str, Any],
        context: NotificationContext
    ) -> Optional[str]:
        """Check if transaction breaks usual patterns"""
        
        category = transaction.get("category", "")
        amount = abs(float(transaction.get("amount", 0)))
        
        # Check spending pattern deviations
        if context.user_spending_pattern:
            usual_categories = context.user_spending_pattern.get('usual_categories', [])
            unusual_categories = context.user_spending_pattern.get('unusual_categories', [])
            
            # New category with high amount
            if category not in usual_categories and amount >= 5000:
                return f"First high-value {category} purchase"
            
            # Spending in unusual category
            if category in unusual_categories and amount >= 2000:
                return f"Unusual category for you: {category}"
        
        # Check against budget (overspending pattern)
        if context.budget_status:
            percentage = context.budget_status.get('percentage_used', 0)
            if percentage >= 100:
                return f"Budget already exceeded ({percentage:.0f}%)"
        
        return None
    
    def _generate_explanation(
        self,
        reasons: List[str],
        risk_score: float
    ) -> str:
        """Generate human-readable explanation of anomaly"""
        
        if risk_score >= 0.7:
            severity = "High risk detected"
        elif risk_score >= 0.5:
            severity = "Moderate risk detected"
        else:
            severity = "Unusual activity detected"
        
        explanation_parts = [severity, "\n\nReasons:"]
        for i, reason in enumerate(reasons, 1):
            explanation_parts.append(f"{i}. {reason}")
        
        return "\n".join(explanation_parts)
    
    def _recommend_action(self, risk_score: float) -> str:
        """Recommend action based on risk score"""
        
        if risk_score >= 0.7:
            return "Please verify this transaction immediately. If you didn't make this purchase, report it as fraud."
        elif risk_score >= 0.5:
            return "Please review this transaction to confirm it's legitimate."
        else:
            return "Please confirm this transaction was intentional."

