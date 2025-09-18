from pydantic import BaseModel, HttpUrl, Field
from typing import Optional, List, Literal
from datetime import datetime

Platform = Literal['x','twitter','facebook','instagram','youtube']

class SocialAccountIn(BaseModel):
    entity_id: str
    platform: Platform
    handle: str
    url: Optional[HttpUrl] = None
    verified: bool = False
    active: bool = True

class SocialPostIn(BaseModel):
    account_id: str
    platform_post_id: str
    posted_at: datetime
    text: Optional[str] = None
    lang: Optional[str] = None
    metrics: dict = Field(default_factory=dict)
    topics: List[str] = Field(default_factory=list)

class SocialReplyIn(BaseModel):
    post_id: str
    responder_handle: Optional[str]
    created_at: datetime
    text: Optional[str]
    sentiment: Optional[float]
    toxicity: Optional[float]
    stance: Optional[str]

class MetricEventIn(BaseModel):
    entity_id: str
    kpi_id: str
    value: float
    window: Optional[tuple] = None
    sample_size: Optional[int] = None
    inputs: dict = Field(default_factory=dict)
