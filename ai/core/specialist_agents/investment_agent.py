from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.tools import Tool
from typing import Optional

from ai.core.tools import financial_tools

# A focused subset of tools for this agent
tools = [
    Tool(
        name="get_investments",
        func=financial_tools.get_investments,
        description="Use this tool to retrieve a list of all the user's recorded investments and assets.",
    ),
    Tool(
        name="create_investment",
        func=financial_tools.create_investment,
        description="Use this tool to add a new investment or asset holding.",
    ),
     Tool(
        name="update_investment",
        func=financial_tools.update_investment,
        description="Use this tool to update an existing investment entry.",
    ),
    Tool(
        name="delete_investment",
        func=financial_tools.delete_investment,
        description="Use this tool to delete a specific investment entry.",
    ),
]

# Initialize a dedicated LLM for this agent
llm = ChatOpenAI(model="gpt-4o", temperature=0.1) # Slightly more creative

prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """
            You are a specialized Investment Analyst Agent. Your name is 'Ivy'.

            Your role is to assist users with managing and understanding their investment portfolio.
            - You are analytical, data-driven, and provide clear, concise insights.
            - Use your tools to access the user's investment data.
            - When asked for analysis, provide summaries of their portfolio, calculate total returns, and identify the best and worst-performing assets.
            - IMPORTANT: You cannot give financial advice. You can only analyze the data you have access to. Do not suggest buying or selling specific assets.
            - You must always respond with the results of your work.
            """,
        ),
        ("user", "{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ]
)

agent = create_openai_functions_agent(llm, tools, prompt)

investment_analyst_agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,
    handle_parsing_errors=True, # More robust for complex analysis
) 