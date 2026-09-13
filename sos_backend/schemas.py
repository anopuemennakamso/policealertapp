from pydantic import BaseModel, EmailStr
from typing import Optional, List
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
    emergency_type: Optional[str] = "General SOS"  # e.g., 'Medical Emergency', 'Armed Robbery'
    description: Optional[str] = None             # Optional user details/notes

# Response returned when fetching alerts
class AlertResponse(BaseModel):
    id: int
    user_id: int
    latitude: float
    longitude: float
    emergency_type: str
    description: Optional[str] = None
    status: str
    created_at: Optional[datetime] = None
    owner: Optional[UserResponse] = None  # Includes user details (name, phone) for responder dashboard

    class Config:
        from_attributes = True




# --- EMERGENCY CONTACT SCHEMAS ---
class ContactCreate(BaseModel):
    name: str
    phone_number: str
    relationship_type: str

class ContactResponse(ContactCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# --- USER PROFILE UPDATE SCHEMAS ---
class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None

class UserProfileResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone_number: str
    role: str
    badge_code: Optional[str] = None
    emergency_contacts: List[ContactResponse] = []

    class Config:
        from_attributes = True