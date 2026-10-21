from pydantic import BaseModel
from typing import Optional, List

class UserRegister(BaseModel):
    name: str
    email: str
    password: str
    phone: Optional[str] = None
    role: str = "parent" # admin, staff, parent, child

class UserLogin(BaseModel):
    email: str
    password: str
    delivery_method: Optional[str] = "email" # 'email' hoặc 'sms'

class ResendOTP(BaseModel):
    email: str
    delivery_method: Optional[str] = "email" # 'email' hoặc 'sms'

class VerifyOTP(BaseModel):
    email: str
    otp: str

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone: Optional[str] = None
    role: str
    avatar: Optional[str] = None
    token: Optional[str] = None

class ChildCreate(BaseModel):
    name: str
    age: int
    gender: Optional[str] = "male"
    phone: Optional[str] = None
    avatar: Optional[str] = None
    device_id: Optional[str] = None
    daily_screen_limit_minutes: Optional[int] = 180

class ChildUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    avatar: Optional[str] = None
    device_id: Optional[str] = None
    battery_level: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    current_noise_db: Optional[float] = None
    daily_screen_limit_minutes: Optional[int] = None
    used_screen_minutes: Optional[int] = None

class GeofenceCreate(BaseModel):
    child_id: str
    name: str
    latitude: float
    longitude: float
    radius_meters: float
    notify_on_exit: bool = True
    notify_on_entry: bool = True

class GeofenceUpdate(BaseModel):
    name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meters: Optional[float] = None
    is_active: Optional[bool] = None
    notify_on_exit: Optional[bool] = None
    notify_on_entry: Optional[bool] = None

class ScheduleCreate(BaseModel):
    child_id: str
    title: str
    start_time: str
    end_time: str
    days: str
    block_apps: bool = True

class ScheduleUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    days: Optional[str] = None
    is_active: Optional[bool] = None
    block_apps: Optional[bool] = None

class ContactCreate(BaseModel):
    child_id: str
    name: str
    phone: str
    relationship: str
    is_sos_contact: bool = False
    avatar: Optional[str] = None

class ContactUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    relationship: Optional[str] = None
    is_sos_contact: Optional[bool] = None
    avatar: Optional[str] = None

class NoiseLogCreate(BaseModel):
    child_id: str
    decibel: float
    status: str
    timestamp: str
    note: Optional[str] = None

class SOSTicketCreate(BaseModel):
    child_id: str
    child_name: str
    parent_name: Optional[str] = None
    parent_phone: Optional[str] = None
    latitude: float
    longitude: float
    noise_level: Optional[float] = 0.0
    reason: str

class SOSTicketUpdate(BaseModel):
    status: Optional[str] = None
    assigned_staff_id: Optional[str] = None
    resolution_notes: Optional[str] = None
