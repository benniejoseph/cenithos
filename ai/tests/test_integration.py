import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
import json
from ai.main import app

client = TestClient(app)

def get_final_response(streaming_response):
    """
    Helper to consume a streaming response and return the final 'complete' data packet.
    """
    final_data = None
    for line in streaming_response.iter_lines():
        if line:
            packet = json.loads(line)
            if packet.get("status") == "complete":
                final_data = packet["data"]
                break
    return final_data

@pytest.fixture
def mock_requests():
    with patch('ai.core.tools.financial_tools.requests') as mock_requests_patch:
        yield mock_requests_patch

def test_query_calls_get_goals_tool(mock_requests):
    """
    Tests if a query like 'show my goals' correctly calls the get_financial_goals tool.
    """
    # Configure the mock to return a successful response
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [{"id": "goal1", "name": "Test Goal"}]
    mock_requests.get.return_value = mock_response

    # Make the request
    response = client.post(
        "/query",
        json={"user_id": "test-user-123", "query": "show my goals"},
    )

    # Assertions
    assert response.status_code == 200
    data = get_final_response(response)
    assert data is not None
    assert data["agent_used"] == "financial_assistant (tool_caller)"
    assert data["tool_used"] == "get_financial_goals"
    assert "Test Goal" in data["response_text"]
    
    # Verify that requests.get was called
    mock_requests.get.assert_called_once()


def test_query_calls_create_goal_tool(mock_requests):
    """
    Tests if a query like 'create a goal' correctly calls the create_financial_goal tool.
    """
    mock_response = MagicMock()
    mock_response.status_code = 201
    mock_response.json.return_value = {"id": "goal2", "name": "New Car"}
    mock_requests.post.return_value = mock_response

    response = client.post(
        "/query",
        json={"user_id": "test-user-456", "query": "create a goal for a new car"},
    )

    assert response.status_code == 200
    data = get_final_response(response)
    assert data is not None
    assert data["agent_used"] == "financial_assistant (tool_caller)"
    assert data["tool_used"] == "create_financial_goal"
    assert "New Car" in data["response_text"]
    mock_requests.post.assert_called_once()

def test_fallback_for_unrecognized_query():
    """Tests if the agent provides a fallback response for a query that doesn't match a tool."""
    response = client.post(
        "/query",
        json={"user_id": "test-user-789", "query": "what is the meaning of life?"},
    )
    
    assert response.status_code == 200
    data = get_final_response(response)
    assert data is not None
    assert data["agent_used"] == "general_assistant"
    assert data["tool_used"] is None
    assert "I can only help with financial goals" in data["response_text"]

def test_query_calls_get_transactions_tool(mock_requests):
    """
    Tests if a query like 'show my transactions' correctly calls the get_transactions tool.
    """
    # Configure the mock to return a successful response with sample transactions
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        {"id": "txn_1", "description": "Coffee", "amount": -5.50, "type": "expense"},
        {"id": "txn_2", "description": "Paycheck", "amount": 2500.00, "type": "income"},
    ]
    mock_requests.get.return_value = mock_response

    # Make the request
    response = client.post(
        "/query",
        json={"user_id": "test-user-txn", "query": "show my transactions"},
    )

    # Assertions
    assert response.status_code == 200
    data = get_final_response(response)
    assert data is not None
    assert data["agent_used"] == "financial_assistant (tool_caller)"
    assert data["tool_used"] == "get_transactions"
    assert "Coffee" in data["response_text"]
    assert "Paycheck" in data["response_text"]

    # Verify that requests.get was called
    mock_requests.get.assert_called_once() 

def test_query_calls_get_transactions_tool_with_filters(mock_requests):
    """
    Tests if a filtered query for transactions correctly calls the get_transactions tool
    with the right parameters.
    """
    # Configure the mock to return a successful response
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        {"id": "txn_3", "description": "Groceries", "amount": -75.00, "category": "food"}
    ]
    mock_requests.get.return_value = mock_response

    # Make the request with a filtered query
    query = "show my transactions for category food in the last 30 days"
    response = client.post(
        "/query",
        json={"user_id": "test-user-filtered", "query": query},
    )

    # Assertions
    assert response.status_code == 200
    data = get_final_response(response)
    assert data is not None
    assert data["agent_used"] == "financial_assistant (tool_caller)"
    assert data["tool_used"] == "get_transactions"
    assert "Groceries" in data["response_text"]
    
    # Verify that requests.get was called with the correct parameters
    mock_requests.get.assert_called_once()
    call_args, call_kwargs = mock_requests.get.call_args
    assert "params" in call_kwargs
    params = call_kwargs["params"]
    assert params.get("category") == "food"
    assert "startDate" in params
    assert "endDate" in params

def test_contextual_follow_up_query(mock_requests):
    """
    Tests if the orchestrator can handle a multi-turn conversation where
    a follow-up query filters the results of a previous query.
    """
    user_id = "test-user-context"
    
    # --- Clear context before starting to ensure a clean slate ---
    client.post("/reset-context", json={"user_id": user_id})

    # --- Turn 1: Get all transactions ---
    
    # Configure the mock to return a list of transactions
    mock_response_1 = MagicMock()
    mock_response_1.status_code = 200
    transactions_data = [
        {"id": "txn_1", "description": "Coffee", "amount": -5.50, "category": "Food"},
        {"id": "txn_2", "description": "Movie", "amount": -15.00, "category": "Entertainment"},
        {"id": "txn_3", "description": "Groceries", "amount": -60.00, "category": "Food"},
    ]
    mock_response_1.json.return_value = transactions_data
    mock_requests.get.return_value = mock_response_1

    # Make the first request
    response_1 = client.post(
        "/query",
        json={"user_id": user_id, "query": "list my transactions"},
    )
    assert response_1.status_code == 200
    data_1 = get_final_response(response_1)
    assert data_1["tool_used"] == "get_transactions"
    assert len(data_1["tool_result"]) == 3
    mock_requests.get.assert_called_once() # Verify API was called

    # --- Turn 2: Filter the results from Turn 1 ---

    # Make the follow-up request
    response_2 = client.post(
        "/query",
        json={"user_id": user_id, "query": "filter for food"},
    )
    
    assert response_2.status_code == 200
    data_2 = get_final_response(response_2)
    
    # Assert that the contextual filter was used, not the main tool
    assert data_2["tool_used"] == "contextual_filter"
    
    # Assert that the data was correctly filtered from the previous turn's context
    assert len(data_2["tool_result"]) == 2
    assert data_2["tool_result"][0]["description"] == "Coffee"
    assert data_2["tool_result"][1]["description"] == "Groceries"
    
    # IMPORTANT: Assert that the API was NOT called a second time
    mock_requests.get.assert_called_once() 


def test_streaming_response_flow(mock_requests):
    """
    Tests that the endpoint streams responses correctly, sending intermediate
    statuses before the final 'complete' packet.
    """
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [{"id": "goal1", "name": "Streaming Test Goal"}]
    mock_requests.get.return_value = mock_response

    response = client.post(
        "/query",
        json={"user_id": "test-user-stream", "query": "show my goals"},
    )

    assert response.status_code == 200
    
    packets = [json.loads(line) for line in response.iter_lines() if line]
    
    assert len(packets) > 1, "Should have received multiple streaming packets"
    
    # Check intermediate statuses
    assert packets[0]["status"] == "starting"
    assert packets[1]["status"] == "thinking"
    
    # Check the final packet
    final_packet = packets[-1]
    assert final_packet["status"] == "complete"
    final_data = final_packet["data"]
    assert final_data["tool_used"] == "get_financial_goals"
    assert "Streaming Test Goal" in final_data["response_text"] 