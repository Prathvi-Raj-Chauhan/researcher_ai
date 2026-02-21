# vector_store.py
from langchain_chroma import Chroma
from ingestion.embedder import BGEEmbeddings

PERSIST_DIRECTORY = "chroma_db"

embedding_model = BGEEmbeddings()

def create_vector_store(chunks) -> Chroma:
    print("Creating vector store...")
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embedding_model,
        persist_directory=PERSIST_DIRECTORY,
        collection_metadata={"hnsw:space": "cosine"}
    )
    print(f"Vector store saved to {PERSIST_DIRECTORY}")
    return vectorstore

def load_vector_store() -> Chroma:
    """Load existing vector store from disk"""
    return Chroma(
        persist_directory=PERSIST_DIRECTORY,
        embedding_function=embedding_model
    )