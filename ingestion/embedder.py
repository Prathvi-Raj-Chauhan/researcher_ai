from sentence_transformers import SentenceTransformer

model = SentenceTransformer("BAAI/bge-small-en-v1.5")

def embed_texts(texts: list[str]) -> list[list[float]]:
    """Takes a list of strings, returns a list of embedding vectors"""
    embeddings = model.encode(texts, show_progress_bar=True)
    return embeddings.tolist()

def embed_query(query: str) -> list[float]:
    """Single query embedding — used at search time"""
    embedding = model.encode(query)
    return embedding.tolist()
