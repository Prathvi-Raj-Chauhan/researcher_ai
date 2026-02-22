from google import genai
from query.search import search
from dotenv import load_dotenv
import os

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

def build_context(chunks: list) -> str:
    context = ""
    for i, chunk in enumerate(chunks):
        context += f"[Source {i+1}: {chunk['source']}]\n"
        context += chunk['content'] + "\n\n"
    return context.strip()

def synthesize(query: str, session_id: str, k: int = 5) -> dict:
    # Step 1 - retrieve relevant chunks
    chunks = search(query, session_id=session_id, k=k)
    

    
    if not chunks:
        return {
            "answer": "No relevant information found in the knowledge base.",
            "sources": [],
            "chunks_used": 0
        }
    
    # Step 2 - build context from chunks
    context = build_context(chunks)
    
    # Step 3 - generate answer
    prompt = f"""You are a helpful research assistant. Answer the user's question using ONLY the provided context below.
If the answer is not in the context, say "I couldn't find this in the provided documents."
Always be concise and accurate. Cite which source you used.

Context:
{context}

Question: {query}

Answer:"""

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    answer = response.text.strip()
    sources = list(set([chunk["source"] for chunk in chunks]))

    return {
        "answer": answer,
        "sources": sources,
        "chunks_used": len(chunks)
    }