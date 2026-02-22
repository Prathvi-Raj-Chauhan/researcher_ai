# vector_store.py
from langchain_chroma import Chroma
from ingestion.embedder import BGEEmbeddings

PERSIST_DIRECTORY = "chroma_db"

embedding_model = BGEEmbeddings()

# def create_vector_store(chunks) -> Chroma:
#     print("Creating vector store...")
#     vectorstore = Chroma.from_documents(
#         documents=chunks,
#         embedding=embedding_model,
#         persist_directory=PERSIST_DIRECTORY,
#         collection_metadata={"hnsw:space": "cosine"}
#     )
#     print(f"Vector store saved to {PERSIST_DIRECTORY}")
#     return vectorstore

# def load_vector_store() -> Chroma:
#     """Load existing vector store from disk"""
#     return Chroma(
#         persist_directory=PERSIST_DIRECTORY,
#         embedding_function=embedding_model
#     )
def create_vector_store(chunks, session_id: str) -> Chroma:
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embedding_model,
        persist_directory=PERSIST_DIRECTORY,
        collection_name=session_id,
        collection_metadata={"hnsw:space": "cosine"}
    )
    return vectorstore

def load_vector_store(session_id: str) -> Chroma:
    return Chroma(
        persist_directory=PERSIST_DIRECTORY,
        embedding_function=embedding_model,
        collection_name=session_id
    )

def delete_session(session_id: str) -> bool:
    """Delete a specific session's collection"""
    try:
        vectorstore = load_vector_store(session_id)
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
