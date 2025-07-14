import os
import openai
from typing import List, Dict, Any
from abc import ABC, abstractmethod

class LlmProvider(ABC):
    @abstractmethod
    async def get_response(self, prompt: str, system_prompt: str) -> str:
        pass

class OpenAIProvider(LlmProvider):
    def __init__(self, api_key: str):
        self.client = openai.AsyncOpenAI(api_key=api_key)
        
    async def get_response(self, prompt: str, system_prompt: str) -> str:
        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=2048,
                temperature=0.0,
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"An error occurred with OpenAI: {e}")
            return ""

class LlmProviderFactory:
    @staticmethod
    def get_provider(provider_name: str) -> LlmProvider:
        if provider_name == "openai":
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable not set.")
            return OpenAIProvider(api_key=api_key)
        else:
            raise ValueError(f"Unsupported LLM provider: {provider_name}") 