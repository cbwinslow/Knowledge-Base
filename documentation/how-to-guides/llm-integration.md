# Integrating LLMs in Your Application

Comprehensive guide to integrating Large Language Models into your applications.

## Overview

This guide covers:
- Choosing the right LLM provider
- API integration patterns
- Cost optimization
- Error handling and retries
- Streaming responses
- Production best practices

**Time required**: 45-60 minutes

## Prerequisites

- Python 3.9+ or Node.js 18+
- API keys from LLM providers
- Basic understanding of REST APIs
- Environment for testing

## Supported Providers

| Provider | Models | Cost | Best For |
|----------|--------|------|----------|
| OpenAI | GPT-4, GPT-3.5 | $$$ | General purpose, high quality |
| Anthropic | Claude 3 | $$$ | Long context, reasoning |
| Google | Gemini | $$ | Multimodal, cost-effective |
| Ollama | Llama2, Mistral | Free | Local, privacy-sensitive |

## Step 1: Install Dependencies

### Python

```bash
pip install openai anthropic google-generativeai ollama langchain
```

### Node.js

```bash
npm install openai @anthropic-ai/sdk @google/generative-ai ollama langchain
```

## Step 2: Configure API Keys

Create `.env` file:

```bash
# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Google
GOOGLE_API_KEY=AI...

# Optional: Custom base URL
OPENAI_BASE_URL=https://api.openai.com/v1
```

**Security**: Never commit API keys to version control!

## Step 3: Basic Integration (Python)

```python
import os
from openai import OpenAI
from anthropic import Anthropic

# Initialize clients
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
anthropic_client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

def chat_with_openai(prompt: str) -> str:
    """Simple OpenAI chat completion"""
    response = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=1000
    )
    return response.choices[0].message.content

def chat_with_claude(prompt: str) -> str:
    """Simple Claude chat completion"""
    message = anthropic_client.messages.create(
        model="claude-3-sonnet-20240229",
        max_tokens=1000,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    return message.content[0].text

# Usage
response = chat_with_openai("Explain quantum computing in simple terms")
print(response)
```

## Step 4: Error Handling and Retries

```python
from tenacity import retry, stop_after_attempt, wait_exponential
from openai import APIError, RateLimitError, APIConnectionError

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10),
    retry=retry_if_exception_type((RateLimitError, APIConnectionError))
)
def safe_chat_completion(prompt: str) -> str:
    """Chat completion with retry logic"""
    try:
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            timeout=30.0  # 30 second timeout
        )
        return response.choices[0].message.content
    except RateLimitError:
        print("Rate limit hit, retrying...")
        raise
    except APIConnectionError:
        print("Connection error, retrying...")
        raise
    except APIError as e:
        print(f"API error: {e}")
        return "I'm having trouble processing that request."
```

## Step 5: Streaming Responses

### Python

```python
def stream_chat_completion(prompt: str):
    """Stream response as it's generated"""
    stream = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        stream=True
    )
    
    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            content = chunk.choices[0].delta.content
            print(content, end="", flush=True)
            yield content
```

### FastAPI Endpoint

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.post("/chat/stream")
async def stream_chat(prompt: str):
    """Streaming chat endpoint"""
    async def generate():
        stream = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            stream=True
        )
        for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
    
    return StreamingResponse(generate(), media_type="text/plain")
```

## Step 6: Context Management

```python
from typing import List, Dict

class ChatSession:
    """Manage conversation context"""
    
    def __init__(self, system_prompt: str = "You are a helpful assistant"):
        self.messages: List[Dict] = [
            {"role": "system", "content": system_prompt}
        ]
        self.max_tokens = 4000  # Leave room for response
    
    def add_message(self, role: str, content: str):
        """Add message to context"""
        self.messages.append({"role": role, "content": content})
        self._trim_context()
    
    def _trim_context(self):
        """Keep context within token limits"""
        # Rough estimation: 1 token ~= 4 characters
        total_chars = sum(len(m["content"]) for m in self.messages)
        estimated_tokens = total_chars / 4
        
        while estimated_tokens > self.max_tokens and len(self.messages) > 2:
            # Remove oldest message (keep system message)
            self.messages.pop(1)
            total_chars = sum(len(m["content"]) for m in self.messages)
            estimated_tokens = total_chars / 4
    
    def chat(self, user_message: str) -> str:
        """Send message and get response"""
        self.add_message("user", user_message)
        
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=self.messages
        )
        
        assistant_message = response.choices[0].message.content
        self.add_message("assistant", assistant_message)
        
        return assistant_message

# Usage
session = ChatSession(system_prompt="You are a helpful Python expert")
response1 = session.chat("What is a list comprehension?")
response2 = session.chat("Show me an example")  # Remembers context
```

## Step 7: Function Calling

```python
import json

def get_weather(location: str, unit: str = "celsius") -> dict:
    """Get weather for a location (mock implementation)"""
    return {
        "location": location,
        "temperature": 22,
        "unit": unit,
        "conditions": "sunny"
    }

def chat_with_functions(user_message: str) -> str:
    """Chat with function calling capability"""
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
    
    # First API call
    response = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": user_message}],
        tools=tools,
        tool_choice="auto"
    )
    
    message = response.choices[0].message
    
    # Check if function call was requested
    if message.tool_calls:
        tool_call = message.tool_calls[0]
        function_name = tool_call.function.name
        function_args = json.loads(tool_call.function.arguments)
        
        # Execute function
        if function_name == "get_weather":
            function_response = get_weather(**function_args)
        
        # Second API call with function result
        messages = [
            {"role": "user", "content": user_message},
            message,
            {
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": json.dumps(function_response)
            }
        ]
        
        final_response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages
        )
        
        return final_response.choices[0].message.content
    
    return message.content

# Usage
result = chat_with_functions("What's the weather in San Francisco?")
print(result)
```

## Step 8: Cost Optimization

### Token Counting

```python
import tiktoken

def count_tokens(text: str, model: str = "gpt-3.5-turbo") -> int:
    """Count tokens in text"""
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def estimate_cost(prompt: str, response: str, model: str = "gpt-3.5-turbo") -> float:
    """Estimate API call cost"""
    # Prices as of 2024 (per 1K tokens)
    prices = {
        "gpt-3.5-turbo": {"input": 0.0005, "output": 0.0015},
        "gpt-4": {"input": 0.03, "output": 0.06},
        "gpt-4-turbo": {"input": 0.01, "output": 0.03},
    }
    
    input_tokens = count_tokens(prompt, model)
    output_tokens = count_tokens(response, model)
    
    price = prices.get(model, prices["gpt-3.5-turbo"])
    cost = (input_tokens / 1000 * price["input"]) + \
           (output_tokens / 1000 * price["output"])
    
    return cost
```

### Caching Responses

```python
import redis
import hashlib
import json

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def cached_chat_completion(prompt: str, ttl: int = 3600) -> str:
    """Chat completion with Redis caching"""
    # Create cache key
    cache_key = f"llm:completion:{hashlib.md5(prompt.encode()).hexdigest()}"
    
    # Check cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Make API call
    response = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    
    result = response.choices[0].message.content
    
    # Cache result
    redis_client.setex(cache_key, ttl, json.dumps(result))
    
    return result
```

## Step 9: Local LLM with Ollama

```python
import ollama

def local_chat_completion(prompt: str, model: str = "llama2") -> str:
    """Chat with local Ollama model"""
    response = ollama.chat(
        model=model,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    return response['message']['content']

def stream_local_chat(prompt: str, model: str = "llama2"):
    """Stream local model response"""
    stream = ollama.chat(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        stream=True
    )
    
    for chunk in stream:
        print(chunk['message']['content'], end='', flush=True)
```

## Step 10: Production Configuration

```python
from pydantic_settings import BaseSettings

class LLMConfig(BaseSettings):
    """LLM configuration"""
    # Provider selection
    provider: str = "openai"
    model: str = "gpt-3.5-turbo"
    
    # API keys
    openai_api_key: str
    anthropic_api_key: str = ""
    
    # Generation parameters
    temperature: float = 0.7
    max_tokens: int = 1000
    top_p: float = 1.0
    
    # Retry configuration
    max_retries: int = 3
    retry_delay: int = 1
    
    # Rate limiting
    requests_per_minute: int = 60
    tokens_per_minute: int = 90000
    
    # Caching
    enable_cache: bool = True
    cache_ttl: int = 3600
    
    class Config:
        env_file = ".env"

# Usage
config = LLMConfig()
```

## Best Practices

### 1. Always Set Timeouts

```python
response = openai_client.chat.completions.create(
    ...,
    timeout=30.0  # 30 seconds
)
```

### 2. Use Structured Outputs

```python
from pydantic import BaseModel

class MovieReview(BaseModel):
    title: str
    rating: int
    summary: str

response = openai_client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[
        {"role": "user", "content": "Review the movie Inception"}
    ],
    response_format=MovieReview
)

review = response.choices[0].message.parsed
```

### 3. Implement Rate Limiting

```python
from ratelimit import limits, sleep_and_retry

@sleep_and_retry
@limits(calls=60, period=60)  # 60 calls per minute
def rate_limited_chat(prompt: str) -> str:
    return safe_chat_completion(prompt)
```

### 4. Monitor Usage

```python
import logging

def monitored_chat(prompt: str) -> str:
    """Chat with usage monitoring"""
    start_time = time.time()
    
    response = openai_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    
    duration = time.time() - start_time
    usage = response.usage
    
    logging.info(f"LLM Call - Duration: {duration:.2f}s, "
                f"Tokens: {usage.total_tokens}, "
                f"Cost: ${estimate_cost(prompt, response.choices[0].message.content):.4f}")
    
    return response.choices[0].message.content
```

## Troubleshooting

### Rate Limit Errors

```python
# Solution: Implement exponential backoff
from tenacity import retry, wait_exponential

@retry(wait=wait_exponential(multiplier=1, min=4, max=60))
def chat_with_retry(prompt: str) -> str:
    return openai_client.chat.completions.create(...)
```

### Token Limit Exceeded

```python
# Solution: Truncate or summarize context
def truncate_context(messages: List[Dict], max_tokens: int = 4000) -> List[Dict]:
    # Keep system message and recent messages
    return [messages[0]] + messages[-10:]
```

### High Latency

```python
# Solution: Use streaming and async
import asyncio
from openai import AsyncOpenAI

async_client = AsyncOpenAI()

async def async_chat(prompt: str) -> str:
    response = await async_client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content
```

## Production Checklist

- [ ] API keys stored securely
- [ ] Error handling implemented
- [ ] Retry logic configured
- [ ] Rate limiting in place
- [ ] Response caching enabled
- [ ] Usage monitoring active
- [ ] Timeouts configured
- [ ] Cost tracking implemented
- [ ] Fallback strategy defined
- [ ] Testing completed

## Next Steps

1. Implement vector database for RAG
2. Add prompt templates
3. Set up monitoring dashboard
4. Configure alerting
5. Implement A/B testing

## Additional Resources

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic Claude Documentation](https://docs.anthropic.com/)
- [LangChain Documentation](https://docs.langchain.com/)
- [Ollama Documentation](https://ollama.ai/docs)
