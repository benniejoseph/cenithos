from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.tools import Tool
from typing import Optional

from ai.core.tools import financial_tools

# A focused subset of tools for this agent
tools = [
    Tool(
        name="get_budgets",
        func=financial_tools.get_budgets,
        description="Use this tool to retrieve a list of all of the user's current budgets.",
    ),
    Tool(
        name="create_budget",
        func=financial_tools.create_budget,
        description="Use this tool to create a new budget for a specific spending category.",
    ),
    Tool(
        name="update_budget",
        func=financial_tools.update_budget,
        description="Use this tool to update an existing budget.",
    ),
    Tool(
        name="delete_budget",
        func=financial_tools.delete_budget,
        description="Use this tool to delete a specific budget.",
    ),
    Tool(
        name="get_transactions",
        func=financial_tools.get_transactions,
        description="Use this to get transaction data, which is essential for comparing spending against budgets.",
    ),
]

# Initialize a dedicated LLM for this agent
llm = ChatOpenAI(model="gpt-4o", temperature=0)

prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """
            You are a specialized Budgeting Advisor Agent. Your name is 'Buddy'.

            Your role is to help users create, manage, and analyze their budgets and spending habits.
            - You are practical, supportive, and provide actionable advice.
            - Use the 'get_transactions' tool to analyze spending patterns before suggesting budget amounts.
            - When asked to analyze a budget, compare the 'budgetedAmount' to the 'spentAmount' and provide the user with a clear status.
            - Proactively offer to help users find areas where they can save money by analyzing their transaction history.
            - You must always respond with the results of your work.
            """,
        ),
        ("user", "{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ]
)

agent = create_openai_functions_agent(llm, tools, prompt)

budgeting_advisor_agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,
    handle_parsing_errors=True,
) 