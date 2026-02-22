from storage.vector_store import load_vector_store



def search(query: str, session_id: str, k: int = 5) -> list:
    """Returns top k relevant chunks for a query for particular sessionid"""
    vectorstore = load_vector_store(session_id)
    results = vectorstore.similarity_search_with_score(query, k=k)
    
    output = []
    for doc, score in results:
        output.append({
            "content": doc.page_content,
            "source": doc.metadata.get("source", "unknown"),
            "score": round(float(score), 4)
        })
    return output