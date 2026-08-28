# HumSukhan — Full-Stack Accessibility Companion

HumSukhan is a privacy-first accessibility app designed for clear live communication, on-device captions, and professional session management.

## Architecture

This project follows a production-oriented full-stack architecture:

- **Frontend:** Flutter Android app with offline-first capabilities.
- **Backend:** FastAPI (Python) for user management, data synchronization, and AI orchestration.
- **Database:** PostgreSQL for persistent, scalable storage of records and user profiles.
- **AI Orchestration:** Backend-driven summarization and insights (extensible to LLMs).
- **Offline Speech:** Sherpa-ONNX streaming ASR (Zipformer/Whisper) for on-device privacy.

## Project Structure

```
.
├── android/             # Android native host
├── backend/             # FastAPI backend
│   ├── app/             # Application logic
│   └── main.py          # Entry point
├── lib/                 # Flutter source code
├── assets/              # App branding and offline models
└── README.md            # Project overview
```

## Getting Started

### Backend Setup
1. Navigate to `backend/`.
2. Install dependencies: `pip install -r requirements.txt`.
3. Set up PostgreSQL and configure `DATABASE_URL`.
4. Run the server: `uvicorn app.main:app --reload`.

### Frontend Setup
1. Ensure Flutter 3.47+ is installed.
2. Run `flutter pub get`.
3. Configure backend URL in `lib/backend_provider.dart`.
4. Build or run: `flutter run`.

## Privacy & Retention
- **Offline-First:** Speech recognition happens locally.
- **Encrypted Store:** Local credentials use AES-GCM.
- **Deterministic Retention:** Professional records are automatically purged within 15 days.
- **No Audio Persistence:** Raw audio is never stored or sent to the cloud.
