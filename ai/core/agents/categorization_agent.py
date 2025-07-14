from .base_agent import BaseAgent
from typing import List, Dict, Any
from ai.core.llm import LlmProvider
import json

class CategorizationAgent(BaseAgent):
    """
    An agent specialized in categorizing financial transactions.
    """

    def __init__(self, llm_provider: LlmProvider):
        super().__init__(
            llm_provider=llm_provider,
            agent_name="CategorizationAgent",
            system_prompt="""
You are an expert at categorizing financial transactions.
Based on the transaction details (description, vendor, amount),
assign the most appropriate category from the provided list.
Return a JSON array where each object contains the original transaction 'id' and the assigned 'category'.
"""
        )

    async def categorize_transactions(self, transactions: List[Dict[str, Any]], categories: List[str]) -> List[Dict[str, Any]]:
        """
        Takes a list of transactions and returns them with a category assigned by the LLM.
        """
        if not transactions:
            return []

        prompt = f"""
Please categorize the following transactions based on this list of available categories:
{', '.join(categories)}

Transactions:
{transactions}

Return only a JSON array with the 'id' and assigned 'category' for each transaction.
"""
        
        response_text = await self.get_response(prompt)
        print(f"Categorization response (raw): {response_text}")
        
        try:
            categorized_data = json.loads(response_text)
            return categorized_data
        except json.JSONDecodeError:
            print("Error decoding categorization response from LLM.")
            return [] 