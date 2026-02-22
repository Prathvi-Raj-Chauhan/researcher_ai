# vector_store.py
from langchain_chroma import Chroma
from ingestion.embedder import BGEEmbeddings

PERSIST_DIRECTORY = "chroma_db"

embedding_model = BGEEmbeddings()

def _collection_name(userId: str, projectId: str) -> str:
    return f"{userId}__{projectId}"

def create_vector_store(chunks, userId: str, projectId: str) -> Chroma:
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embedding_model,
        persist_directory=PERSIST_DIRECTORY,
        collection_name=_collection_name(userId, projectId),
        collection_metadata={"hnsw:space": "cosine"}
    )
    return vectorstore

def load_vector_store(userId: str, projectId: str) -> Chroma:
    return Chroma(
        persist_directory=PERSIST_DIRECTORY,
        embedding_function=embedding_model,
        collection_name=_collection_name(userId, projectId)
    )


def delete_vector_store(userId: str, projectId: str) -> bool:
    try:
        vectorstore = load_vector_store(userId, projectId)
        vectorstore.delete_collection()
        return True
    except Exception:
        return False

def cleanup_old_sessions(max_age_hours: int = 24) -> int:
    """Delete sessions older than max_age_hours, returns count deleted"""
    import time
    deleted = 0

    if not os.path.exists(PERSIST_DIRECTORY):
        return 0

    chroma_client = Chroma(
        persist_directory=PERSIST_DIRECTORY,
        embedding_function=embedding_model
    ).client

    collections = chroma_client.list_collections()
    now = time.time()

    for collection in collections:
        metadata = collection.metadata or {}
        created_at = metadata.get("created_at", None)

        if created_at and (now - created_at) > max_age_hours * 3600:
            chroma_client.delete_collection(collection.name)
            deleted += 1

    return deleted
