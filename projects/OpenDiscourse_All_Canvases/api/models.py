from pydantic import BaseModel

class SocialAccount(BaseModel):
    handle: str
