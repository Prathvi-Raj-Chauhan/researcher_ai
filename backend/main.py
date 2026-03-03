from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from pydantic import BaseModel
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import tempfile
import os
import asyncio
import json 
from fastapi.responses import StreamingResponse  

load_dotenv()

from ingestion.loader import load_document
from ingestion.chunker import split_documents
from storage.vector_store import create_vector_store, delete_vector_store, cleanup_old_sessions, load_vector_store
from query.synthesizer import synthesize
from query.summarizer import summarize_document

# ---- STARTUP / SHUTDOWN ----

async def scheduled_cleanup():
    while True:
        await asyncio.sleep(24 * 3600)
        deleted = cleanup_old_sessions(max_age_hours=24)
        print(f"[Cleanup] Deleted {deleted} old sessions")

@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(scheduled_cleanup())
    print("[Startup] Cleanup scheduler started")
    yield
    print("[Shutdown] Server shutting down")

app = FastAPI(
    title="Research Helper API",
    version="1.0.0",
    lifespan=lifespan
)

# ---- REQUEST MODELS ----

class URLRequest(BaseModel):
    url: str
    userId: str
    projectId: str

class QueryRequest(BaseModel):
    query: str
    userId: str
    projectId: str
    k: int = 5
    history: list[dict] = []

class ProjectRequest(BaseModel):
    userId: str
    projectId: str

# ---- ROUTES ----

@app.get("/")
def root():
    return {"message": "Research Helper API is running"}


@app.post("/ingest/url")
def ingest_url(request: URLRequest):
    try:
        docs = load_document(request.url)
        chunks = split_documents(docs)
        create_vector_store(chunks, userId=request.userId, projectId=request.projectId)
        return {
            "message": "URL ingested successfully",
            "source": request.url,
            "chunks_created": len(chunks),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ingest/file")
async def ingest_file(
    file: UploadFile = File(...),
    userId: str = Form(...),       # Form() because multipart request
    projectId: str = Form(...),
):
    try:
        suffix = os.path.splitext(file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            contents = await file.read()
            tmp.write(contents)
            tmp_path = tmp.name

        docs = load_document(tmp_path)
        chunks = split_documents(docs)
        create_vector_store(chunks, userId=userId, projectId=projectId)

        os.unlink(tmp_path)

        return {
            "message": "File ingested successfully",
            "filename": file.filename,
            "chunks_created": len(chunks),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/query")
def query(request: QueryRequest):
    try:
        result = synthesize(
            query=request.query,
            userId=request.userId,
            projectId=request.projectId,
            history=request.history,
            k=request.k,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/summarize")
def summarize(request: ProjectRequest):
    try:
        result = summarize_document(
            userId=request.userId,
            projectId=request.projectId,
        )
        print("Sent summary is ")
        print(result)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/session")
def delete_user_session(request: ProjectRequest):
    success = delete_vector_store(
        userId=request.userId,
        projectId=request.projectId,
    )
    if success:
        return {"message": "Session deleted successfully"}
    raise HTTPException(status_code=404, detail="Session not found")


@app.post("/admin/cleanup")
def manual_cleanup(max_age_hours: int = 24):
    deleted = cleanup_old_sessions(max_age_hours=max_age_hours)
    return {"deleted_sessions": deleted}

@app.post("/ingestUrl/stream") 
async def ingest_url_stream(request: URLRequest):
    async def event_stream():
        try:
            yield f"data: {json.dumps({'step': 0, 'message': 'Reading document...'})}\n\n"
            docs = load_document(request.url)

            yield f"data: {json.dumps({'step': 1, 'message': 'Chunking content...'})}\n\n"
            chunks = split_documents(docs)

            yield f"data: {json.dumps({'step': 2, 'message': 'Storing embeddings...'})}\n\n"
            create_vector_store(chunks, userId=request.userId, projectId=request.projectId)  # fixed

            yield f"data: {json.dumps({'step': 3, 'message': 'Generating summary...'})}\n\n"
            summary_result = summarize_document(userId=request.userId, projectId=request.projectId)  # fixed

            yield f"data: {json.dumps({'step': 4, 'message': 'Done!', 'summary': summary_result['summary']})}\n\n"

        except Exception as e:
            yield f"data: {json.dumps({'step': -1, 'message': str(e)})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")

@app.post("/ingestUrl/add/stream")
async def ingest_url_add_stream(request: URLRequest):
    async def event_stream():
        try:
            yield f"data: {json.dumps({'step': 0, 'message': 'Reading document...'})}\n\n"
            docs = load_document(request.url)

            yield f"data: {json.dumps({'step': 1, 'message': 'Chunking content...'})}\n\n"
            chunks = split_documents(docs)

            yield f"data: {json.dumps({'step': 2, 'message': 'Storing embeddings...'})}\n\n"
            chroma = load_vector_store(userId=request.userId, projectId=request.projectId)
            chroma.add_documents(chunks)

            yield f"data: {json.dumps({'step': 3, 'message': 'Done!'})}\n\n"

        except Exception as e:
            yield f"data: {json.dumps({'step': -1, 'message': str(e)})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")



@app.post("/ingest/file/stream")
async def ingest_file_stream(
    file: UploadFile = File(...),
    userId: str = Form(...),      
    projectId: str = Form(...),
):
    contents = await file.read()
    suffix = os.path.splitext(file.filename)[1]

    async def event_stream():
        tmp_path = None
        try:
            yield f"data: {json.dumps({'step': 0, 'message': 'Reading document...'})}\n\n"
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                tmp.write(contents)
                tmp_path = tmp.name
            docs = load_document(tmp_path)

            yield f"data: {json.dumps({'step': 1, 'message': 'Chunking content...'})}\n\n"
            chunks = split_documents(docs)

            yield f"data: {json.dumps({'step': 2, 'message': 'Storing embeddings...'})}\n\n"
            create_vector_store(chunks, userId=userId, projectId=projectId)  # fixed

            yield f"data: {json.dumps({'step': 3, 'message': 'Generating summary...'})}\n\n"
            summary_result = summarize_document(userId=userId, projectId=projectId)  # fixed

            yield f"data: {json.dumps({'step': 4, 'message': 'Done!', 'summary': summary_result['summary']})}\n\n"

        except Exception as e:
            yield f"data: {json.dumps({'step': -1, 'message': str(e)})}\n\n"
        finally:
            if tmp_path and os.path.exists(tmp_path):
                os.unlink(tmp_path)

    return StreamingResponse(event_stream(), media_type="text/event-stream")