from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import Tool
from typing import Optional

from ai.core.specialist_agents.investment_agent import investment_analyst_agent_executor
from ai.core.specialist_agents.budgeting_agent import budgeting_advisor_agent_executor
from ai.core.tools import financial_tools # Still need this for the generalist

# --- 1. Define the Tools for the Chief Financial Agent (CFA) ---
# The CFA's tools are the other agents. This is the core of the multi-agent design.
tools = [
    Tool.from_function(
        func=investment_analyst_agent_executor.invoke,
        name="InvestmentAnalyst",
        description="""
        Use this specialist agent for any questions about investments, stocks, mutual funds, gold,
        portfolio performance, or market analysis.
        Example queries: "How are my investments doing?", "Analyze my portfolio", "What's my best performing stock?"
        """,
    ),
    Tool.from_function(
        func=budgeting_advisor_agent_executor.invoke,
        name="BudgetingAdvisor",
        description="""
        Use this specialist agent for any questions about budgets, spending, or transaction analysis.
        Example queries: "Help me create a budget", "How much did I spend on food last month?", "Am I over budget on shopping?"
        """,
    ),
]

# --- 2. Create the Generalist Financial Agent ---
# This agent acts as a fallback for simple questions or tasks not covered by specialists.
# It has access to the basic tools for goals and transactions.
general_tools = [
    Tool(
        name="get_financial_goals",
        func=financial_tools.get_financial_goals,
        description="Use this tool to retrieve a list of the user's current financial goals.",
    ),
    Tool(
        name="get_transactions",
        func=financial_tools.get_transactions,
        description="Use this tool to retrieve a list of a user's financial transactions.",
    ),
]

general_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", "You are Alex, a helpful general financial assistant."),
        ("user", "{input}"),
        ("placeholder", "{agent_scratchpad}"),
    ]
)
general_llm = ChatOpenAI(model="gpt-4o", temperature=0)
general_agent_runnable = create_openai_functions_agent(general_llm, general_tools, general_prompt)
general_agent_executor = AgentExecutor(agent=general_agent_runnable, tools=general_tools, verbose=True)


# --- 3. Create the Chief Financial Agent (The Router) ---
cfa_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """
            You are the Chief Financial Agent (CFA) for the Centhios app. Your name is Alex.

            Your job is to understand the user's query and route it to the correct specialist agent.
            - If the query is about investments, stocks, or portfolio analysis, route it to the 'InvestmentAnalyst'.
            - If the query is about budgets, spending, or transaction history, route it to the 'BudgetingAdvisor'.

            If the query is a simple, general question that doesn't require a specialist (e.g., "list my goals"),
            you can choose to handle it yourself using your own limited set of tools.

            You are the primary interface to the user. You will receive the final response from the specialist
            and present it to the user in a friendly, conversational way.
            """,
        ),
        ("user", "{input}"),
        ("placeholder", "{agent_scratchpad}"),
    ]
)

cfa_llm = ChatOpenAI(model="gpt-4o", temperature=0)
chief_financial_agent = create_openai_functions_agent(cfa_llm, tools, cfa_prompt)
cfa_executor = AgentExecutor(agent=chief_financial_agent, tools=tools, verbose=True)

def invoke_multi_agent_system(user_id: str, query: str):
    """
    The main entry point for the multi-agent financial system.
    """
    # Inject the user_id into the query for all agents to use
    input_with_context = {
        "input": f"User ID is '{user_id}'. The user's query is: {query}"
    }
    
    # First, let the CFA decide which tool (specialist agent) to use.
    try:
        # The CFA decides which specialist to call
        result = cfa_executor.invoke(input_with_context)
        return result
    except Exception as e:
        # If the CFA fails or if no specialist is appropriate, fall back to the generalist agent.
        print(f"CFA failed or no specialist found, falling back to generalist. Error: {e}")
        return general_agent_executor.invoke(input_with_context) 