from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import tempfile
import os
import asyncio

load_dotenv()

from ingestion.loader import load_document
from ingestion.chunker import split_documents
from storage.vector_store import create_vector_store, delete_session, cleanup_old_sessions
from query.synthesizer import synthesize
from query.summarizer import summarize_document

# ---- AUTO CLEANUP EVERY 24 HOURS ----

async def scheduled_cleanup():
    """Runs in background, cleans old sessions every 24 hours"""
    while True:
        await asyncio.sleep(24 * 3600)
        deleted = cleanup_old_sessions(max_age_hours=24)
        print(f"[Cleanup] Deleted {deleted} old sessions")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # runs on startup
    asyncio.create_task(scheduled_cleanup())
    print("[Startup] Cleanup scheduler started")
    yield
    # runs on shutdown
    print("[Shutdown] Server shutting down")

app = FastAPI(
    title="Research Helper API",
    version="1.0.0",
    lifespan=lifespan
)


# ---- INGEST URL ----

class URLRequest(BaseModel):
    url: str
    session_id: str

@app.post("/ingest/url")
def ingest_url(request: URLRequest):
    try:
        docs = load_document(request.url)
        chunks = split_documents(docs)
        create_vector_store(chunks, session_id=request.session_id)
        return {
            "message": "URL ingested successfully",
            "source": request.url,
            "chunks_created": len(chunks),
            "session_id": request.session_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---- INGEST FILE ----

@app.post("/ingest/file")
async def ingest_file(file: UploadFile = File(...), session_id: str = "default"):
    try:
        suffix = os.path.splitext(file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            contents = await file.read()
            tmp.write(contents)
            tmp_path = tmp.name

        docs = load_document(tmp_path)
        chunks = split_documents(docs)
        create_vector_store(chunks, session_id=session_id)

        os.unlink(tmp_path)

        return {
            "message": "File ingested successfully",
            "filename": file.filename,
            "chunks_created": len(chunks),
            "session_id": session_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---- QUERY ----

class QueryRequest(BaseModel):
    query: str
    session_id: str
    k: int = 5

@app.post("/query")
def query(request: QueryRequest):
    try:
        result = synthesize(request.query, session_id=request.session_id, k=request.k)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class SessionRequest(BaseModel):
    session_id: str

@app.post("/summarize")
def summarize(request: SessionRequest):
    try:
        result = summarize_document(request.session_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---- CLEANUP ENDPOINTS ----

class SessionRequest(BaseModel):
    session_id: str

@app.delete("/session")
def delete_user_session(request: SessionRequest):
    """Flutter calls this when user wants to clear their data"""
    success = delete_session(request.session_id)
    if success:
        return {"message": "Session deleted successfully"}
    raise HTTPException(status_code=404, detail="Session not found")

@app.post("/admin/cleanup")
def manual_cleanup(max_age_hours: int = 24):
    """Manually trigger cleanup — for admin use"""
    deleted = cleanup_old_sessions(max_age_hours=max_age_hours)
    return {"deleted_sessions": deleted}




@app.get("/")
def root():
    return {"message": "Research Helper API is running"}