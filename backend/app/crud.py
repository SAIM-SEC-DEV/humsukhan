from sqlalchemy.orm import Session
from . import models, schemas, auth

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password,
        gender=user.gender
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_folders(db: Session, user_id: int):
    return db.query(models.Folder).filter(models.Folder.user_id == user_id).all()

def create_folder(db: Session, folder: schemas.FolderCreate, user_id: int):
    db_folder = models.Folder(**folder.dict(), user_id=user_id)
    db.add(db_folder)
    db.commit()
    db.refresh(db_folder)
    return db_folder

def get_records(db: Session, user_id: int):
    return db.query(models.ProfessionalRecord).filter(models.ProfessionalRecord.user_id == user_id).all()

def create_record(db: Session, record: schemas.ProfessionalRecordCreate, user_id: int):
    db_record = models.ProfessionalRecord(
        id=record.id,
        title=record.title,
        type=record.type,
        folder=record.folder,
        language=record.language,
        created_at=record.created_at,
        expires_at=record.expires_at,
        started_at=record.started_at,
        stopped_at=record.stopped_at,
        user_id=user_id,
        deletion_status=record.deletion_status,
        insights=record.insights
    )
    db.add(db_record)
    db.commit()
    
    for line in record.transcript:
        db_line = models.TranscriptLine(**line.dict(), record_id=record.id)
        db.add(db_line)
    
    db.commit()
    db.refresh(db_record)
    return db_record

def delete_record(db: Session, record_id: str, user_id: int):
    db_record = db.query(models.ProfessionalRecord).filter(
        models.ProfessionalRecord.id == record_id,
        models.ProfessionalRecord.user_id == user_id
    ).first()
    if db_record:
        db.delete(db_record)
        db.commit()
        return True
    return False
