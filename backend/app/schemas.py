from pydantic import BaseModel, EmailStr
from typing import List, Optional
import datetime

class TranscriptLineBase(BaseModel):
    speaker: str
    text: str
    timestamp: datetime.datetime

class TranscriptLineCreate(TranscriptLineBase):
    pass

class TranscriptLine(TranscriptLineBase):
    id: int
    record_id: str

    class Config:
        from_attributes = True

class ProfessionalRecordBase(BaseModel):
    id: str
    title: str
    type: str
    folder: str
    language: str
    created_at: datetime.datetime
    expires_at: datetime.datetime
    started_at: Optional[datetime.datetime] = None
    stopped_at: Optional[datetime.datetime] = None
    deletion_status: str = "active"
    insights: Optional[dict] = None

class ProfessionalRecordCreate(ProfessionalRecordBase):
    transcript: List[TranscriptLineCreate]

class ProfessionalRecord(ProfessionalRecordBase):
    transcript: List[TranscriptLine]
    user_id: int

    class Config:
        from_attributes = True

class FolderBase(BaseModel):
    name: str

class FolderCreate(FolderBase):
    pass

class Folder(FolderBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: EmailStr
    username: str
    gender: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    created_at: datetime.datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
