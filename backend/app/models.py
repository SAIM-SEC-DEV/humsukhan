from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text, JSON
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    gender = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    folders = relationship("Folder", back_populates="owner")
    records = relationship("ProfessionalRecord", back_populates="owner")

class Folder(Base):
    __tablename__ = "folders"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    owner = relationship("User", back_populates="folders")
    records = relationship("ProfessionalRecord", back_populates="folder_rel")

class ProfessionalRecord(Base):
    __tablename__ = "professional_records"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, index=True)
    type = Column(String)
    folder = Column(String) # For legacy/sync compatibility
    folder_id = Column(Integer, ForeignKey("folders.id"), nullable=True)
    language = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    expires_at = Column(DateTime)
    started_at = Column(DateTime)
    stopped_at = Column(DateTime)
    user_id = Column(Integer, ForeignKey("users.id"))
    deletion_status = Column(String, default="active")
    insights = Column(JSON, nullable=True)

    owner = relationship("User", back_populates="records")
    folder_rel = relationship("Folder", back_populates="records")
    transcript = relationship("TranscriptLine", back_populates="record", cascade="all, delete-orphan")

class TranscriptLine(Base):
    __tablename__ = "transcript_lines"

    id = Column(Integer, primary_key=True, index=True)
    record_id = Column(String, ForeignKey("professional_records.id"))
    speaker = Column(String)
    text = Column(Text)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    record = relationship("ProfessionalRecord", back_populates="transcript")
