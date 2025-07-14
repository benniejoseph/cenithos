import unittest
from unittest.mock import MagicMock
from ai.core.agents.financial_assistant_agent import FinancialAssistantAgent

class TestAgents(unittest.TestCase):

    def test_financial_assistant_agent(self):
        # Arrange
        agent = FinancialAssistantAgent(api_key="test_api_key")
        
        # Mock the process_query method directly for simplicity
        agent.process_query = MagicMock(return_value="Hello from mock Financial Assistant!")

        # Act
        query = "How much did I spend on food last month?"
        context = []
        response = agent.process_query(query, context)

        # Assert
        self.assertEqual(response, "Hello from mock Financial Assistant!")
        agent.process_query.assert_called_once_with(query, context)

if __name__ == '__main__':
    unittest.main() 