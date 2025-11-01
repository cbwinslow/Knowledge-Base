"""
FastAPI Application Template
Modern async API with best practices
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional
import uvicorn
from datetime import datetime

# Initialize FastAPI app
app = FastAPI(
    title="FastAPI Template",
    description="Production-ready FastAPI template",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic Models
class UserBase(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)
    age: Optional[int] = Field(None, ge=0, le=150)

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class User(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        orm_mode = True

class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

# Dependency Injection
async def get_current_user():
    """Dependency for authentication"""
    # Implement your auth logic
    return {"id": 1, "email": "user@example.com"}

# Routes
@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "message": "API is running"}

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

@app.get("/users", response_model=List[User])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    current_user: dict = Depends(get_current_user)
):
    """List all users with pagination"""
    # Implement database query
    users = []  # Fetch from database
    return users

@app.post("/users", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(user: UserCreate):
    """Create a new user"""
    # Validate and create user
    try:
        # Database creation logic
        new_user = {
            "id": 1,
            "email": user.email,
            "name": user.name,
            "age": user.age,
            "created_at": datetime.now()
        }
        return new_user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@app.get("/users/{user_id}", response_model=User)
async def get_user(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Get user by ID"""
    # Fetch from database
    user = None  # Database query
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user

@app.put("/users/{user_id}", response_model=User)
async def update_user(
    user_id: int,
    user: UserBase,
    current_user: dict = Depends(get_current_user)
):
    """Update user"""
    # Update in database
    updated_user = {
        "id": user_id,
        "email": user.email,
        "name": user.name,
        "age": user.age,
        "created_at": datetime.now()
    }
    return updated_user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Delete user"""
    # Delete from database
    return None

# Error Handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "message": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"success": False, "message": "Internal server error"}
    )

# Startup/Shutdown Events
@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    print("Application starting up...")
    # Initialize database connections, etc.

@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    print("Application shutting down...")
    # Close database connections, etc.

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
