import os
import openai
import json
from typing import List, Dict, Any
from ai.core.llm import LlmProvider
from abc import ABC, abstractmethod

class BaseAgent(ABC):
    def __init__(self, llm_provider: LlmProvider, agent_name: str, system_prompt: str):
        self.llm_provider = llm_provider
        self.agent_name = agent_name
        self.system_prompt = system_prompt

    async def get_response(self, user_query: str) -> str:
        """
        Generates a response from the LLM provider using the agent's system prompt.
        """
        return await self.llm_provider.get_response(user_query, self.system_prompt) 