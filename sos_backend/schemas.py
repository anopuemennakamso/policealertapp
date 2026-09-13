from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

# --- USER SCHEMAS ---

# Shared fields for User
class UserBase(BaseModel):
    full_name: str
    email: EmailStr
    phone_number: str
    role: Optional[str] = "citizen"  # "citizen" or "responder"

# Fields required when registering a user
class UserCreate(UserBase):
    password: str
    badge_code: Optional[str] = None  # Required only when role == 'responder'

# Fields required when logging in
class UserLogin(BaseModel):
    email: EmailStr
    password: str

# Response returned to client for User data
class UserResponse(UserBase):
    id: int

    class Config:
        from_attributes = True


# --- ALERT SCHEMAS ---

# Base alert data sent by client when triggering SOS
class AlertCreate(BaseModel):
    latitude: float
    longitude: float

# Response returned when fetching alerts
class AlertResponse(BaseModel):
    id: int
    user_id: int
    latitude: float
    longitude: float
    status: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True