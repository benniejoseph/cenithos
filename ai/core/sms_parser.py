import re
import os
import json
from datetime import datetime
from openai import OpenAI

# Initialize OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

class SmsParser:
    def __init__(self):
        # Regex patterns remain as a fallback
        self.patterns = [
            re.compile(r"debited\s+by\s+(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*).*?at\s+(?P<merchant>.*?)(?:\.|\sOn|\sRef)", re.IGNORECASE),
            re.compile(r"transaction\s+of\s+(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*)\s+is\s+made\s+at\s+(?P<merchant>.*?)(?:\.|\sOn|\sRef)", re.IGNORECASE),
            re.compile(r"spent\s+(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*)\s+at\s+(?P<merchant>.*?)(?:\.|\sOn|\sRef)", re.IGNORECASE),
            re.compile(r"credited\s+with\s+(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*)", re.IGNORECASE),
            re.compile(r"(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*)\s+debited\s+from.*?(?:to|at)\s+(?P<merchant>.*?)(?:\.|\sOn|\sRef)", re.IGNORECASE),
            re.compile(r"(?:Rs\.?|INR)\s*(?P<amount>[\d,]+\.?\d*)\s+credited\s+to", re.IGNORECASE)
        ]
        self.keywords = ["debited", "credited", "spent", "transaction", "payment", "received"]

    def parse_with_regex(self, message: str):
        if not any(keyword in message.lower() for keyword in self.keywords):
            return None
        for pattern in self.patterns:
            match = pattern.search(message)
            if match:
                data = match.groupdict()
                merchant = data.get("merchant", "Unknown").strip()
                if '@' in merchant:
                    merchant = merchant.split('@')[0]
                
                return {
                    "amount": float(data.get("amount", "0").replace(",", "")),
                    "merchant": merchant,
                    "type": "credit" if "credited" in message.lower() or "received" in message.lower() else "expense",
                    "category": "Other",
                    "description": merchant, # Simple description from merchant
                }
        return None

    def parse_with_ai(self, message: str):
        current_date = datetime.now()
        prompt = f"""
        You are an expert financial assistant. Your task is to extract transaction details from an SMS message and return a structured JSON object.

        **Context:**
        - The current year is {current_date.year}.
        - The current month is {current_date.strftime('%B')}.
        - Assume the transaction happened in the current year unless specified otherwise.

        **Instructions:**
        1.  Analyze the following SMS message:
            ---
            {message}
            ---
        2.  Extract the following fields and format them into a SINGLE, minified JSON object.
        3.  Do NOT include any explanatory text, markdown, or anything else outside the JSON object.

        **JSON Fields to Extract:**
        - `amount`: (Number) The transaction amount.
        - `type`: (String) "expense" or "income".
        - `currency`: (String) The currency code (e.g., "INR").
        - `description`: (String) A brief, clean description of the transaction.
        - `category`: (String) Classify the transaction into one of these categories: ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Income', 'Other'].
        - `vendor`: (String) The specific vendor or service name (e.g., "Zomato", "Uber"). If not available, use the merchant name.
        - `merchant`: (String) The payment processor or merchant identifier (e.g., "bistrobyblinkit.rzp@mairtel").
        - `bank`: (String) The name of the bank if mentioned (e.g., "HDFC Bank", "Kotak Bank").
        - `ref_id`: (String) The transaction reference ID, if available.

        **Example Output Format:**
        {{"amount": 502.0, "type": "expense", "currency": "INR", "description": "Food Order", "category": "Food", "vendor": "Bistro by Blinkit", "merchant": "bistrobyblinkit.rzp@mairtel", "bank": "Kotak Bank", "ref_id": "556003726618"}}
        
        If you cannot extract a specific field, return `null` for that field's value.
        """
        try:
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
            )
            content = response.choices[0].message.content
            # Clean up potential markdown formatting
            if content.startswith("```json"):
                content = content[7:-3].strip()
            return json.loads(content)
        except Exception as e:
            print(f"Error parsing with AI: {e}")
            return None

    def parse(self, message: str):
        # AI First Approach
        parsed_ai = self.parse_with_ai(message)
        if parsed_ai:
            # Basic validation to ensure we have a usable object
            if parsed_ai.get("amount") and parsed_ai.get("type"):
                return parsed_ai
        
        # Fallback to Regex if AI fails
        return self.parse_with_regex(message) 