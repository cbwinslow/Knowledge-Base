#!/usr/bin/env python3
"""
LLM Integration Examples

Demonstrates integration with various Large Language Model providers:
- OpenAI (GPT-4, GPT-3.5)
- Anthropic (Claude)
- Local models (Ollama)
- LangChain framework
"""

import os
from typing import List, Dict, Optional, AsyncIterator
from dataclasses import dataclass
from enum import Enum
import asyncio

# Third-party imports
from openai import OpenAI, AsyncOpenAI
from anthropic import Anthropic, AsyncAnthropic
import ollama
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate
from loguru import logger


class Provider(Enum):
    """LLM Provider enumeration"""
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    OLLAMA = "ollama"


@dataclass
class LLMConfig:
    """Configuration for LLM providers"""
    provider: Provider
    model: str
    api_key: Optional[str] = None
    base_url: Optional[str] = None
    temperature: float = 0.7
    max_tokens: int = 1000


class OpenAIExample:
    """OpenAI API integration examples"""
    
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.async_client = AsyncOpenAI(api_key=api_key)
    
    def simple_completion(self, prompt: str, model: str = "gpt-3.5-turbo") -> str:
        """
        Simple completion example
        
        Args:
            prompt: The prompt to send
            model: Model to use
            
        Returns:
            Generated response
        """
        try:
            response = self.client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            raise
    
    def chat_with_system_message(
        self,
        system_prompt: str,
        user_message: str,
        model: str = "gpt-3.5-turbo"
    ) -> str:
        """
        Chat with system message for context
        
        Args:
            system_prompt: System instructions
            user_message: User's message
            model: Model to use
            
        Returns:
            Generated response
        """
        response = self.client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ]
        )
        return response.choices[0].message.content
    
    def streaming_response(
        self,
        prompt: str,
        model: str = "gpt-3.5-turbo"
    ) -> None:
        """
        Stream response as it's generated
        
        Args:
            prompt: The prompt to send
            model: Model to use
        """
        stream = self.client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            stream=True
        )
        
        print("Response: ", end="", flush=True)
        for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                print(chunk.choices[0].delta.content, end="", flush=True)
        print()
    
    async def async_completion(
        self,
        prompts: List[str],
        model: str = "gpt-3.5-turbo"
    ) -> List[str]:
        """
        Process multiple prompts asynchronously
        
        Args:
            prompts: List of prompts
            model: Model to use
            
        Returns:
            List of responses
        """
        async def process_prompt(prompt: str) -> str:
            response = await self.async_client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}]
            )
            return response.choices[0].message.content
        
        tasks = [process_prompt(prompt) for prompt in prompts]
        return await asyncio.gather(*tasks)
    
    def function_calling(self, user_query: str) -> Dict:
        """
        Function calling example
        
        Args:
            user_query: User's query
            
        Returns:
            Function call result
        """
        tools = [
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Get current weather for a location",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "City and state, e.g. San Francisco, CA"
                            },
                            "unit": {
                                "type": "string",
                                "enum": ["celsius", "fahrenheit"]
                            }
                        },
                        "required": ["location"]
                    }
                }
            }
        ]
        
        response = self.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": user_query}],
            tools=tools,
            tool_choice="auto"
        )
        
        message = response.choices[0].message
        if message.tool_calls:
            tool_call = message.tool_calls[0]
            return {
                "function": tool_call.function.name,
                "arguments": tool_call.function.arguments
            }
        
        return {"response": message.content}


class AnthropicExample:
    """Anthropic Claude API integration examples"""
    
    def __init__(self, api_key: str):
        self.client = Anthropic(api_key=api_key)
        self.async_client = AsyncAnthropic(api_key=api_key)
    
    def simple_completion(
        self,
        prompt: str,
        model: str = "claude-3-sonnet-20240229"
    ) -> str:
        """
        Simple completion with Claude
        
        Args:
            prompt: The prompt to send
            model: Model to use
            
        Returns:
            Generated response
        """
        message = self.client.messages.create(
            model=model,
            max_tokens=1000,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        return message.content[0].text
    
    def chat_with_system_prompt(
        self,
        system_prompt: str,
        user_message: str,
        model: str = "claude-3-sonnet-20240229"
    ) -> str:
        """
        Chat with system prompt
        
        Args:
            system_prompt: System instructions
            user_message: User's message
            model: Model to use
            
        Returns:
            Generated response
        """
        message = self.client.messages.create(
            model=model,
            max_tokens=1000,
            system=system_prompt,
            messages=[
                {"role": "user", "content": user_message}
            ]
        )
        return message.content[0].text
    
    def streaming_response(
        self,
        prompt: str,
        model: str = "claude-3-sonnet-20240229"
    ) -> None:
        """
        Stream response from Claude
        
        Args:
            prompt: The prompt to send
            model: Model to use
        """
        with self.client.messages.stream(
            model=model,
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        ) as stream:
            print("Response: ", end="", flush=True)
            for text in stream.text_stream:
                print(text, end="", flush=True)
            print()


class OllamaExample:
    """Ollama local LLM integration examples"""
    
    def simple_completion(self, prompt: str, model: str = "llama2") -> str:
        """
        Simple completion with Ollama
        
        Args:
            prompt: The prompt to send
            model: Model to use (must be pulled first)
            
        Returns:
            Generated response
        """
        response = ollama.chat(
            model=model,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        return response['message']['content']
    
    def streaming_response(self, prompt: str, model: str = "llama2") -> None:
        """
        Stream response from Ollama
        
        Args:
            prompt: The prompt to send
            model: Model to use
        """
        stream = ollama.chat(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            stream=True
        )
        
        print("Response: ", end="", flush=True)
        for chunk in stream:
            print(chunk['message']['content'], end="", flush=True)
        print()
    
    def list_models(self) -> List[str]:
        """
        List available Ollama models
        
        Returns:
            List of model names
        """
        models = ollama.list()
        return [model['name'] for model in models['models']]


class LangChainExample:
    """LangChain framework integration examples"""
    
    def __init__(self, openai_api_key: str):
        self.llm = ChatOpenAI(
            api_key=openai_api_key,
            model="gpt-3.5-turbo",
            temperature=0.7
        )
    
    def simple_chain(self, topic: str) -> str:
        """
        Simple LangChain prompt chain
        
        Args:
            topic: Topic to write about
            
        Returns:
            Generated content
        """
        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are a helpful assistant that writes concise articles."),
            ("human", "Write a short article about {topic}")
        ])
        
        chain = prompt | self.llm
        response = chain.invoke({"topic": topic})
        return response.content
    
    def multi_step_chain(self, product: str) -> str:
        """
        Multi-step chain example
        
        Args:
            product: Product to analyze
            
        Returns:
            Analysis result
        """
        # Step 1: Generate features
        feature_prompt = ChatPromptTemplate.from_template(
            "List 5 key features of {product}. Format as a bullet list."
        )
        feature_chain = feature_prompt | self.llm
        features = feature_chain.invoke({"product": product})
        
        # Step 2: Analyze features
        analysis_prompt = ChatPromptTemplate.from_template(
            "Given these features:\n{features}\n\n"
            "Provide a brief analysis of the product's strengths."
        )
        analysis_chain = analysis_prompt | self.llm
        analysis = analysis_chain.invoke({"features": features.content})
        
        return analysis.content
    
    def conversation_memory(self) -> None:
        """
        Example with conversation memory
        """
        from langchain.memory import ConversationBufferMemory
        from langchain.chains import ConversationChain
        
        memory = ConversationBufferMemory()
        conversation = ConversationChain(
            llm=self.llm,
            memory=memory,
            verbose=True
        )
        
        # First message
        response1 = conversation.predict(input="Hi! My name is Alice.")
        print(f"Bot: {response1}")
        
        # Second message - bot should remember the name
        response2 = conversation.predict(input="What's my name?")
        print(f"Bot: {response2}")


def main():
    """Main demonstration function"""
    
    # Configuration
    openai_key = os.getenv("OPENAI_API_KEY")
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    
    print("=== LLM Integration Examples ===\n")
    
    # OpenAI Examples
    if openai_key:
        print("1. OpenAI Examples")
        openai_client = OpenAIExample(openai_key)
        
        # Simple completion
        response = openai_client.simple_completion("What is Python?")
        print(f"Simple completion: {response[:100]}...\n")
        
        # Chat with system message
        response = openai_client.chat_with_system_message(
            "You are a helpful coding assistant.",
            "Explain what a list comprehension is in Python."
        )
        print(f"Chat response: {response[:100]}...\n")
        
        # Streaming
        print("Streaming response:")
        openai_client.streaming_response("Write a haiku about coding.")
        print()
    
    # Anthropic Examples
    if anthropic_key:
        print("2. Anthropic Claude Examples")
        claude_client = AnthropicExample(anthropic_key)
        
        response = claude_client.simple_completion("What is machine learning?")
        print(f"Claude response: {response[:100]}...\n")
    
    # Ollama Examples
    print("3. Ollama Examples")
    ollama_client = OllamaExample()
    
    try:
        models = ollama_client.list_models()
        print(f"Available models: {models}\n")
        
        if models:
            response = ollama_client.simple_completion(
                "What is AI?",
                model=models[0]
            )
            print(f"Ollama response: {response[:100]}...\n")
    except Exception as e:
        print(f"Ollama not available: {e}\n")
    
    # LangChain Examples
    if openai_key:
        print("4. LangChain Examples")
        langchain_client = LangChainExample(openai_key)
        
        response = langchain_client.simple_chain("artificial intelligence")
        print(f"LangChain response: {response[:100]}...\n")


if __name__ == "__main__":
    main()
