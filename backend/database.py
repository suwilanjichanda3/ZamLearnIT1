import sqlite3
from datetime import datetime

DB_NAME = "translations.db"

def init_db():
    """Initialize the database and create tables if they don't exist"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            original_text TEXT NOT NULL,
            translated_text TEXT NOT NULL,
            language TEXT NOT NULL,
            timestamp TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()
    print("✓ Database initialized successfully")

def save_translation(original, translated, language):
    """Save a translation to the database with timestamp"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    timestamp = datetime.now().isoformat()
    cursor.execute(
        "INSERT INTO history (original_text, translated_text, language, timestamp) VALUES (?, ?, ?, ?)",
        (original, translated, language, timestamp)
    )
    conn.commit()
    conn.close()
    print(f"✓ Translation saved: '{original}' -> '{translated}'")

def get_history():
    """Get all translation history, ordered by newest first"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT id, original_text, translated_text, language, timestamp FROM history ORDER BY id DESC")
    rows = cursor.fetchall()
    conn.close()
    
    history = []
    for row in rows:
        history.append({
            "id": row[0],
            "original": row[1],
            "translated": row[2],
            "language": row[3],
            "timestamp": row[4]
        })
    return history

def delete_history_item(item_id):
    """Delete a single history item by ID"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM history WHERE id = ?", (item_id,))
    affected_rows = cursor.rowcount
    conn.commit()
    conn.close()
    return affected_rows > 0

def clear_all_history():
    """Delete all history items"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM history")
    conn.commit()
    conn.close()
    print("✓ All history cleared")
    return True

# Optional: Function to get count of translations
def get_history_count():
    """Get total number of translations in history"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM history")
    count = cursor.fetchone()[0]
    conn.close()
    return count