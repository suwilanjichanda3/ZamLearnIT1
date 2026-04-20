from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from translator import translate_text
from database import init_db, save_translation, get_history
import uvicorn

app = FastAPI(title="Zambian Language Translator API")

# Add CORS middleware - THIS IS IMPORTANT for Flutter to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

# Initialize database
init_db()

class TranslationRequest(BaseModel):
    text: str
    target_language: str

# ========== HEALTH ENDPOINT ==========
@app.get("/health")
def health():
    return {"status": "healthy", "model_loaded": True}  # Better response

# ========== ROOT ENDPOINT ==========
@app.get("/")
def root():
    return {"message": "ZamLearnIT Translation API is running"}

# ========== LANGUAGES ENDPOINT ==========
@app.get("/languages")
def languages():
    return {"languages": ["bemba", "nyanja"]}  # Removed "success" for consistency

# ========== TRANSLATE ENDPOINT ==========
@app.post("/translate")
def translate(request: TranslationRequest):
    try:
        # Call your translation function
        translated = translate_text(request.text, request.target_language)
        
        # Save to database
        save_translation(request.text, translated, request.target_language)
        
        # Return response matching what Flutter expects
        return {
            "success": True,
            "original_text": request.text,
            "translated_text": translated,
            "target_language": request.target_language
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

# ========== GET HISTORY ENDPOINT ==========
@app.get("/history")
def history():
    return {"history": get_history()}

# ========== DELETE SINGLE HISTORY ITEM ==========
@app.delete("/history/{item_id}")
def delete_history_item(item_id: int):
    from database import delete_history_item as db_delete
    success = db_delete(item_id)
    if success:
        return {"message": "Item deleted"}
    raise HTTPException(status_code=404, detail="Item not found")

# ========== CLEAR ALL HISTORY ==========
@app.delete("/history/all")
def clear_all_history():
    from database import clear_all_history as db_clear
    db_clear()
    return {"message": "All history cleared"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=10000)