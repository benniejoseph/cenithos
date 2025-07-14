import json
from datetime import datetime, timedelta

class PredictionAgent:
    def __init__(self, firestore_client):
        self.firestore_client = firestore_client

    async def generate_spending_prediction(self, user_id: str) -> dict:
        transactions_ref = self.firestore_client.collection('transactions')
        query = transactions_ref.where('userId', '==', user_id).where('type', '==', 'expense')
        
        docs = query.stream()
        
        monthly_spending = {}
        
        # Using a non-async for loop with an async generator is not ideal,
        # but it's what the original code had. This should be fixed later.
        for doc in await docs.to_list():
            transaction = doc.to_dict()
            try:
                # Assuming 'date' is a string in ISO 8601 format
                date = datetime.fromisoformat(transaction['date'])
                month_key = date.strftime('%Y-%m')
                
                if month_key not in monthly_spending:
                    monthly_spending[month_key] = 0
                monthly_spending[month_key] += transaction.get('amount', 0)
            except (ValueError, TypeError):
                # Skip transactions with invalid date format or missing amount
                continue

        if not monthly_spending:
            return {"error": "Not enough data to make a prediction."}

        total_spending = sum(monthly_spending.values())
        average_monthly_spending = total_spending / len(monthly_spending)
        
        # Predict next month's spending
        today = datetime.now()
        next_month = today + timedelta(days=30)
        prediction_month_key = next_month.strftime('%Y-%m')

        return {
            "prediction_month": prediction_month_key,
            "predicted_spending": round(average_monthly_spending, 2),
            "based_on_months": len(monthly_spending),
            "historical_data": monthly_spending,
        } 