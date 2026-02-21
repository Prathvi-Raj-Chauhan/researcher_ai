from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
import tempfile
import os

load_dotenv()

from ingestion.loader import load_document
from ingestion.chunker import split_documents
from storage.vector_store import create_vector_store
from query.synthesizer import synthesize

app = FastAPI(
    title="Research Helper API",
    version="1.0.0"
)

@app.get("/")
def root():
    return {"message": "Research Helper API is running"}


# ---- INGEST URL ----

class URLRequest(BaseModel):
    url: str

@app.post("/ingest/url")
def ingest_url(request: URLRequest):
    try:
        docs = load_document(request.url)
        chunks = split_documents(docs)
        create_vector_store(chunks)
        return {
            "message": "URL ingested successfully",
            "source": request.url,
            "chunks_created": len(chunks)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---- INGEST FILE ----

@app.post("/ingest/file")
async def ingest_file(file: UploadFile = File(...)):
    try:
        # save uploaded file to a temp location so loaders can read it
        suffix = os.path.splitext(file.filename)[1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            contents = await file.read()
            tmp.write(contents)
            tmp_path = tmp.name

        docs = load_document(tmp_path)
        chunks = split_documents(docs)
        create_vector_store(chunks)

        os.unlink(tmp_path)  # delete temp file after done

        return {
            "message": "File ingested successfully",
            "filename": file.filename,
            "chunks_created": len(chunks)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---- QUERY ----

class QueryRequest(BaseModel):
    query: str
    k: int = 5

@app.post("/query")
def query(request: QueryRequest):
    try:
        result = synthesize(request.query, k=request.k)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))