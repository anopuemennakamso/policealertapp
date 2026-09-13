from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from typing import List

import models
import schemas
from database import engine, get_db

# Create database tables automatically
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SOS Emergency Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password[:72])

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

@app.get("/")
def read_root():
    return {"status": "online", "message": "SOS Emergency API Server is running"}

# --- AUTHENTICATION ENDPOINTS ---
LAW_ENFORCEMENT_SECRET = "POLICE2026"
@app.post("/api/auth/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    clean_email = user.email.strip().lower()
    existing_user = db.query(models.User).filter(models.User.email == clean_email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    if user.role == "responder":
        if not user.badge_code or user.badge_code != LAW_ENFORCEMENT_SECRET:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Invalid Agency Access Code or Badge ID. Responder registration denied."
            )

    hashed_pwd = hash_password(user.password)
    new_user = models.User(
        full_name=user.full_name,
        email=clean_email,
        phone_number=user.phone_number,
        hashed_password=hashed_pwd,
        role=user.role if user.role else "citizen"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/api/auth/login")
def login_user(credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    clean_email = credentials.email.strip().lower()
    user = db.query(models.User).filter(models.User.email == clean_email).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid credentials"
        )
    return {
        "status": "success",
        "message": "Login successful",
        "user_id": user.id,
        "full_name": user.full_name,
        "role": user.role
    }

# --- CITIZEN ALERT ENDPOINTS ---

@app.post("/api/alerts/{user_id}", response_model=schemas.AlertResponse, status_code=status.HTTP_201_CREATED)
def trigger_alert(user_id: int, alert: schemas.AlertCreate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_alert = models.Alert(
        user_id=user_id,
        latitude=alert.latitude,
        longitude=alert.longitude,
        status="TRIGGERED"
    )
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    return new_alert

@app.get("/api/alerts/{user_id}", response_model=List[schemas.AlertResponse])
def get_user_alerts(user_id: int, db: Session = Depends(get_db)):
    return db.query(models.Alert).filter(models.Alert.user_id == user_id).all()

# --- LAW ENFORCEMENT / RESPONDER ENDPOINTS ---

@app.get("/api/responder/alerts", response_model=List[schemas.AlertResponse])
def get_all_active_alerts(db: Session = Depends(get_db)):
    return db.query(models.Alert).filter(models.Alert.status == "TRIGGERED").all()

@app.patch("/api/responder/alerts/{alert_id}/resolve")
def resolve_alert(alert_id: int, db: Session = Depends(get_db)):
    alert = db.query(models.Alert).filter(models.Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.status = "RESOLVED"
    db.commit()
    return {"status": "success", "message": f"Alert {alert_id} marked as RESOLVED"}