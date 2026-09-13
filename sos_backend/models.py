from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone_number = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="citizen")  # "citizen" or "responder"
    badge_code = Column(String, nullable=True)

    alerts = relationship("Alert", back_populates="owner")
    emergency_contacts = relationship("EmergencyContact", back_populates="user", cascade="all, delete-orphan")


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    relationship_type = Column(String, nullable=False)  # e.g., "Parent", "Spouse", "Friend"

    user = relationship("User", back_populates="emergency_contacts")


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    emergency_type = Column(String, default="General SOS")  # e.g., Medical Emergency, Armed Robbery
    description = Column(String, nullable=True)             # Optional text details from citizen
    status = Column(String, default="TRIGGERED")            # "TRIGGERED" or "RESOLVED"
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="alerts")