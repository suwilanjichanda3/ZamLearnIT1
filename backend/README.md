---
title: ZamLearnIT Translation API
emoji: 🌍
colorFrom: blue
colorTo: green
sdk: docker
app_port: 7860
---

# ZamLearnIT Translation API




# ZamLearnIT - Zambian Language Translation App

An English to Bemba/Nyanja translation app using Facebook's NLLB-200 AI model.

## Features
- 🔄 Translate English to Bemba and Nyanja
- 📱 Mobile app built with Flutter
- 🧠 Powered by Facebook's NLLB-200 AI model
- 📜 Translation history saved locally
- 🔊 Text-to-speech output

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **AI Model**: Facebook NLLB-200
- **Database**: SQLite

## Installation

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
