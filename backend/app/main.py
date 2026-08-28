from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List

from . import models, schemas, crud, auth, database
from .database import engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="HumSukhan API")

@app.post("/token", response_model=schemas.Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = crud.get_user_by_username(db, form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = crud.get_user_by_username(db, user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_user(db=db, user=user)

@app.get("/users/me/", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

@app.get("/folders/", response_model=List[schemas.Folder])
def read_folders(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return crud.get_folders(db, user_id=current_user.id)

@app.post("/folders/", response_model=schemas.Folder)
def create_folder(folder: schemas.FolderCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return crud.create_folder(db, folder=folder, user_id=current_user.id)

@app.get("/records/", response_model=List[schemas.ProfessionalRecord])
def read_records(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return crud.get_records(db, user_id=current_user.id)

@app.post("/records/", response_model=schemas.ProfessionalRecord)
def create_record(record: schemas.ProfessionalRecordCreate, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    return crud.create_record(db, record=record, user_id=current_user.id)

@app.delete("/records/{record_id}")
def delete_record(record_id: str, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    success = crud.delete_record(db, record_id=record_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Record not found")
    return {"detail": "Record deleted"}

@app.post("/ai/summarize")
async def summarize_transcript(transcript: List[schemas.TranscriptLineBase], current_user: models.User = Depends(auth.get_current_user)):
    # Placeholder for AI orchestration (e.g. calling OpenAI/Claude)
    # In a real scenario, this would use an LLM to generate insights
    text = " ".join([line.text for line in transcript])
    return {
        "summary": f"Backend summary of {len(transcript)} lines.",
        "vocabulary": ["example", "terms"],
        "action_items": ["Review transcript"],
    }
