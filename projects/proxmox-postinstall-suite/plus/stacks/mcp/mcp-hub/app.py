from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI(title='CloudCurio MCP Hub', version='0.1.0')
class Register(BaseModel):
    name: str
    url: str
REG = {}
@app.get('/health')
def h(): return {'ok': True}
@app.post('/register')
def r(s: Register): REG[s.name]=s.url; return {'registered': s.name}
@app.get('/agents')
def a(): return REG
