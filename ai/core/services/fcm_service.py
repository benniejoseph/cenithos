"""
Firebase Cloud Messaging (FCM) Service
======================================

Handles push notification delivery via Firebase Cloud Messaging.

Features:
- Send push notifications to devices
- Manage FCM tokens
- Handle notification data payloads
- Support for both Android and iOS
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
import firebase_admin
from firebase_admin import messaging

logger = logging.getLogger(__name__)


class FCMService:
    """Service for sending push notifications via Firebase Cloud Messaging"""
    
    def __init__(self, db_client=None):
        self.db = db_client
        self._token_cache: Dict[str, List[str]] = {}  # user_id -> [fcm_tokens]
        logger.info("📱 FCM Service initialized")
    
    async def send_notification(
        self,
        user_id: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        priority: str = "high",
        notification_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Send push notification to a user's devices.
        
        Args:
            user_id: Target user ID
            title: Notification title
            body: Notification body
            data: Additional data payload
            priority: 'high' or 'normal'
            notification_id: Optional notification ID for tracking
            
        Returns:
            Dict with delivery results
        """
        try:
            # Get user's FCM tokens
            tokens = await self._get_user_tokens(user_id)
            
            if not tokens:
                logger.warning(f"No FCM tokens found for user {user_id}")
                return {
                    "success": False,
                    "error": "No FCM tokens registered",
                    "sent": 0,
                    "failed": 0,
                }
            
            # Prepare data payload
            data_payload = data or {}
            data_payload['notification_id'] = notification_id or ""
            data_payload['timestamp'] = datetime.now().isoformat()
            data_payload['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
            
            # Build notification
            notification = messaging.Notification(
                title=title,
                body=body,
            )
            
            # Android config
            android_config = messaging.AndroidConfig(
                priority=priority,
                notification=messaging.AndroidNotification(
                    title=title,
                    body=body,
                    sound='default',
                    channel_id='financial_alerts',
                    click_action='FLUTTER_NOTIFICATION_CLICK',
                ),
            )
            
            # iOS config
            apns_config = messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=title,
                            body=body,
                        ),
                        sound='default',
                        badge=1,
                    ),
                ),
            )
            
            # Send to all tokens
            results = []
            success_count = 0
            failure_count = 0
            invalid_tokens = []
            
            for token in tokens:
                try:
                    message = messaging.Message(
                        notification=notification,
                        data=data_payload,
                        token=token,
                        android=android_config,
                        apns=apns_config,
                    )
                    
                    response = messaging.send(message)
                    results.append({
                        'token': token[:10] + '...',  # Masked for security
                        'success': True,
                        'message_id': response,
                    })
                    success_count += 1
                    
                    logger.debug(f"✅ Sent notification to token {token[:10]}...")
                    
                except messaging.UnregisteredError:
                    # Token is invalid, mark for removal
                    invalid_tokens.append(token)
                    failure_count += 1
                    logger.warning(f"❌ Invalid token: {token[:10]}...")
                    
                except Exception as e:
                    results.append({
                        'token': token[:10] + '...',
                        'success': False,
                        'error': str(e),
                    })
                    failure_count += 1
                    logger.error(f"❌ Failed to send to token {token[:10]}...: {e}")
            
            # Remove invalid tokens
            if invalid_tokens:
                await self._remove_invalid_tokens(user_id, invalid_tokens)
            
            logger.info(f"📱 Push notification sent: {success_count} success, {failure_count} failed")
            
            return {
                "success": success_count > 0,
                "sent": success_count,
                "failed": failure_count,
                "total_tokens": len(tokens),
                "invalid_tokens_removed": len(invalid_tokens),
                "results": results,
            }
            
        except Exception as e:
            logger.error(f"❌ Error sending FCM notification: {e}", exc_info=True)
            return {
                "success": False,
                "error": str(e),
                "sent": 0,
                "failed": 0,
            }
    
    async def send_notification_to_topic(
        self,
        topic: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Send notification to a topic (e.g., all users, user segments).
        
        Args:
            topic: Topic name (e.g., 'all_users', 'premium_users')
            title: Notification title
            body: Notification body
            data: Additional data payload
            
        Returns:
            Dict with delivery results
        """
        try:
            data_payload = data or {}
            data_payload['timestamp'] = datetime.now().isoformat()
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data_payload,
                topic=topic,
            )
            
            response = messaging.send(message)
            
            logger.info(f"📢 Topic notification sent to '{topic}': {response}")
            
            return {
                "success": True,
                "message_id": response,
                "topic": topic,
            }
            
        except Exception as e:
            logger.error(f"❌ Error sending topic notification: {e}", exc_info=True)
            return {
                "success": False,
                "error": str(e),
            }
    
    async def register_token(self, user_id: str, fcm_token: str) -> bool:
        """
        Register an FCM token for a user.
        
        Args:
            user_id: User ID
            fcm_token: FCM registration token from device
            
        Returns:
            True if successful
        """
        try:
            if not self.db:
                logger.warning("Database not available for token registration")
                return False
            
            # Store token in Firestore
            token_ref = self.db.collection('fcm_tokens').document(f"{user_id}_{fcm_token[:20]}")
            
            await token_ref.set({
                'user_id': user_id,
                'token': fcm_token,
                'registered_at': datetime.now().isoformat(),
                'last_used': datetime.now().isoformat(),
                'platform': 'unknown',  # Can be determined from the client
            })
            
            # Update cache
            if user_id in self._token_cache:
                if fcm_token not in self._token_cache[user_id]:
                    self._token_cache[user_id].append(fcm_token)
            else:
                self._token_cache[user_id] = [fcm_token]
            
            logger.info(f"✅ Registered FCM token for user {user_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error registering FCM token: {e}")
            return False
    
    async def unregister_token(self, user_id: str, fcm_token: str) -> bool:
        """
        Unregister an FCM token for a user.
        
        Args:
            user_id: User ID
            fcm_token: FCM token to remove
            
        Returns:
            True if successful
        """
        try:
            if not self.db:
                return False
            
            # Remove from Firestore
            token_ref = self.db.collection('fcm_tokens').document(f"{user_id}_{fcm_token[:20]}")
            await token_ref.delete()
            
            # Update cache
            if user_id in self._token_cache and fcm_token in self._token_cache[user_id]:
                self._token_cache[user_id].remove(fcm_token)
            
            logger.info(f"✅ Unregistered FCM token for user {user_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error unregistering FCM token: {e}")
            return False
    
    async def _get_user_tokens(self, user_id: str) -> List[str]:
        """Get all FCM tokens for a user"""
        
        # Check cache first
        if user_id in self._token_cache:
            return self._token_cache[user_id]
        
        # Load from database
        if not self.db:
            return []
        
        try:
            tokens_ref = self.db.collection('fcm_tokens').where('user_id', '==', user_id)
            docs = tokens_ref.stream()
            
            tokens = []
            for doc in docs:
                data = doc.to_dict()
                token = data.get('token')
                if token:
                    tokens.append(token)
            
            # Cache the tokens
            self._token_cache[user_id] = tokens
            
            return tokens
            
        except Exception as e:
            logger.error(f"❌ Error loading user tokens: {e}")
            return []
    
    async def _remove_invalid_tokens(self, user_id: str, tokens: List[str]):
        """Remove invalid tokens from database"""
        
        if not self.db:
            return
        
        try:
            for token in tokens:
                token_ref = self.db.collection('fcm_tokens').document(f"{user_id}_{token[:20]}")
                await token_ref.delete()
            
            # Update cache
            if user_id in self._token_cache:
                self._token_cache[user_id] = [
                    t for t in self._token_cache[user_id] if t not in tokens
                ]
            
            logger.info(f"🗑️  Removed {len(tokens)} invalid tokens for user {user_id}")
            
        except Exception as e:
            logger.error(f"❌ Error removing invalid tokens: {e}")
    
    async def subscribe_to_topic(self, tokens: List[str], topic: str) -> Dict[str, Any]:
        """
        Subscribe FCM tokens to a topic.
        
        Args:
            tokens: List of FCM tokens
            topic: Topic name
            
        Returns:
            Dict with subscription results
        """
        try:
            response = messaging.subscribe_to_topic(tokens, topic)
            
            logger.info(f"✅ Subscribed {response.success_count} tokens to topic '{topic}'")
            
            return {
                "success": True,
                "success_count": response.success_count,
                "failure_count": response.failure_count,
                "errors": [str(e) for e in response.errors] if response.errors else [],
            }
            
        except Exception as e:
            logger.error(f"❌ Error subscribing to topic: {e}")
            return {
                "success": False,
                "error": str(e),
            }
    
    async def unsubscribe_from_topic(self, tokens: List[str], topic: str) -> Dict[str, Any]:
        """
        Unsubscribe FCM tokens from a topic.
        
        Args:
            tokens: List of FCM tokens
            topic: Topic name
            
        Returns:
            Dict with unsubscription results
        """
        try:
            response = messaging.unsubscribe_from_topic(tokens, topic)
            
            logger.info(f"✅ Unsubscribed {response.success_count} tokens from topic '{topic}'")
            
            return {
                "success": True,
                "success_count": response.success_count,
                "failure_count": response.failure_count,
                "errors": [str(e) for e in response.errors] if response.errors else [],
            }
            
        except Exception as e:
            logger.error(f"❌ Error unsubscribing from topic: {e}")
            return {
                "success": False,
                "error": str(e),
            }


# Global FCM service instance
_fcm_service: Optional[FCMService] = None


def get_fcm_service(db_client=None) -> FCMService:
    """Get or create FCM service instance"""
    global _fcm_service
    
    if _fcm_service is None:
        _fcm_service = FCMService(db_client)
    
    return _fcm_service


async def send_push_notification(
    user_id: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
    notification_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Helper function to send push notification.
    
    This is the main entry point for sending notifications.
    """
    fcm_service = get_fcm_service()
    return await fcm_service.send_notification(
        user_id=user_id,
        title=title,
        body=body,
        data=data,
        notification_id=notification_id,
    )

