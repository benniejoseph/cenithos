import requests
import json

# In a real app, this would be in a config file
BASE_URL = "http://127.0.0.1:5001/cenithos/us-central1/api/v1"

def _get_auth_headers(user_id: str):
    # In a real app, this would involve a secure way to get or use a user's token
    # For this simulation, we pass the user_id to a mock auth system.
    return {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer mock-token-for-{user_id}',
    }

def get_financial_goals(user_id: str) -> str:
    """Retrieves a list of the user's current financial goals."""
    try:
        response = requests.get(
            f"{BASE_URL}/goals",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def create_financial_goal(user_id: str, name: str, targetAmount: float, targetDate: str) -> str:
    """Creates a new financial goal for the user."""
    try:
        payload = {
            "name": name,
            "targetAmount": targetAmount,
            "targetDate": targetDate
        }
        response = requests.post(
            f"{BASE_URL}/goals",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def add_to_goal(user_id: str, goalId: str, amount: float) -> str:
    """Adds a specified amount to the current balance of a financial goal."""
    try:
        # This is a PATCH-like operation; we'll update the currentAmount.
        # First, get the current goal to calculate the new amount.
        current_goal_response = requests.get(f"{BASE_URL}/goals/{goalId}", headers=_get_auth_headers(user_id))
        current_goal_response.raise_for_status()
        current_goal = current_goal_response.json()
        
        new_amount = current_goal.get('currentAmount', 0) + amount

        payload = {"currentAmount": new_amount}
        response = requests.put(
            f"{BASE_URL}/goals/{goalId}",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)}) 

def get_transactions(user_id: str, category: str = None, start_date: str = None, end_date: str = None) -> str:
    """
    Retrieve a list of financial transactions for the user.
    Can be filtered by category and/or a date range.
    """
    try:
        params = {}
        if category:
            params['category'] = category
        if start_date:
            params['startDate'] = start_date
        if end_date:
            params['endDate'] = end_date

        response = requests.get(
            f"{BASE_URL}/transactions",
            headers=_get_auth_headers(user_id),
            params=params
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

# --- Budget Tools ---

def create_budget(user_id: str, category: str, budgetedAmount: float, startDate: str, endDate: str) -> str:
    """Creates a new budget for a specific category and time period."""
    try:
        payload = {
            "category": category,
            "budgetedAmount": budgetedAmount,
            "startDate": startDate,
            "endDate": endDate
        }
        response = requests.post(
            f"{BASE_URL}/budgets",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def get_budgets(user_id: str) -> str:
    """Retrieves all budgets for the user."""
    try:
        response = requests.get(
            f"{BASE_URL}/budgets",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def update_budget(user_id: str, budget_id: str, updates: dict) -> str:
    """Updates a budget with new values."""
    try:
        response = requests.put(
            f"{BASE_URL}/budgets/{budget_id}",
            headers=_get_auth_headers(user_id),
            data=json.dumps(updates)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def delete_budget(user_id: str, budget_id: str) -> str:
    """Deletes a specific budget."""
    try:
        response = requests.delete(
            f"{BASE_URL}/budgets/{budget_id}",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        # Delete returns 204 No Content, so we return a success message
        if response.status_code == 204:
            return json.dumps({"success": True, "message": f"Budget {budget_id} deleted successfully."})
        else:
            return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)}) 

# --- Debt Tools ---

def create_debt(user_id: str, name: str, type: str, balance: float, interestRate: float, minimumPayment: float) -> str:
    """Creates a new debt entry for the user."""
    try:
        payload = {
            "name": name,
            "type": type,
            "balance": balance,
            "interestRate": interestRate,
            "minimumPayment": minimumPayment,
        }
        response = requests.post(
            f"{BASE_URL}/debts",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def get_debts(user_id: str) -> str:
    """Retrieves all debt entries for the user."""
    try:
        response = requests.get(
            f"{BASE_URL}/debts",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def update_debt(user_id: str, debt_id: str, updates: dict) -> str:
    """Updates a debt entry with new values."""
    try:
        response = requests.put(
            f"{BASE_URL}/debts/{debt_id}",
            headers=_get_auth_headers(user_id),
            data=json.dumps(updates)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def delete_debt(user_id: str, debt_id: str) -> str:
    """Deletes a specific debt entry."""
    try:
        response = requests.delete(
            f"{BASE_URL}/debts/{debt_id}",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        if response.status_code == 204:
            return json.dumps({"success": True, "message": f"Debt {debt_id} deleted successfully."})
        else:
            return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

# --- Investment Tools ---

def create_investment(user_id: str, name: str, type: str, currentValue: float, investedAmount: float, quantity: float = None) -> str:
    """Creates a new investment entry for the user."""
    try:
        payload = {
            "name": name,
            "type": type,
            "currentValue": currentValue,
            "investedAmount": investedAmount,
        }
        if quantity:
            payload['quantity'] = quantity

        response = requests.post(
            f"{BASE_URL}/investments",
            headers=_get_auth_headers(user_id),
            data=json.dumps(payload)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def get_investments(user_id: str) -> str:
    """Retrieves all investment entries for the user."""
    try:
        response = requests.get(
            f"{BASE_URL}/investments",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def update_investment(user_id: str, investment_id: str, updates: dict) -> str:
    """Updates an investment entry with new values."""
    try:
        response = requests.put(
            f"{BASE_URL}/investments/{investment_id}",
            headers=_get_auth_headers(user_id),
            data=json.dumps(updates)
        )
        response.raise_for_status()
        return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)})

def delete_investment(user_id: str, investment_id: str) -> str:
    """Deletes a specific investment entry."""
    try:
        response = requests.delete(
            f"{BASE_URL}/investments/{investment_id}",
            headers=_get_auth_headers(user_id)
        )
        response.raise_for_status()
        if response.status_code == 204:
            return json.dumps({"success": True, "message": f"Investment {investment_id} deleted successfully."})
        else:
            return json.dumps(response.json())
    except requests.exceptions.RequestException as e:
        return json.dumps({"error": str(e)}) 