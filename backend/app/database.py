from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Use a unique env var name to avoid collision with sandbox defaults
SQLALCHEMY_DATABASE_URL = os.getenv(
    "HUMSUKHAN_DATABASE_URL", 
    "postgresql+psycopg2://humsukhan:humsukhan_pass@localhost/humsukhan_db"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
