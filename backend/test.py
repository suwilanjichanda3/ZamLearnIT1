from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok", "message": "Test server is running"}

@app.get("/")
def root():
    return {"message": "Hello, test server!"}

if __name__ == "__main__":
    print("Starting test server on http://127.0.0.1:8000")
    uvicorn.run(app, host="127.0.0.1", port=8000)