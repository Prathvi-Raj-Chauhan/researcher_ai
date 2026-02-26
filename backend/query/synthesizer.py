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

def build_history_string(history: list[dict], max_messages: int = 5, max_chars: int = 2000) -> str:

    if not history:
        return ""
    # Normalize roles and take last N
    last = history[-max_messages:]
    parts = []
    for item in last:
        role = item.get("role").lower()
        content = str(item.get("content", "")).strip()
        # map role to readable label
        if role in ("system",):
            label = "System"
        elif role in ("assistant", "bot", "ai"):
            label = "Assistant"
        else:
            label = "User"
        parts.append(f"[{label}]: {content}")
    hist_str = "\n".join(parts)
    # Truncate safely (char-level) if too long
    if len(hist_str) > max_chars:
        hist_str = hist_str[-max_chars:]  # keep the last part of conversation
        hist_str = "..." + hist_str  # indicate truncation
    return hist_str


def get_collection_name(userId: str, projectId: str) -> str:
    return f"{userId}__{projectId}"


def synthesize(query: str, projectId: str, userId: str, history: list[dict], k: int = 5) -> dict:
    # Step 1 - retrieve relevant chunks
    collectionName = get_collection_name(userId, projectId)
    print("searching in -> ")
    print(collectionName)
    chunks = search(projectId, query, userId, k=k)
    
    
    if not chunks:
        return {
            "answer": "No relevant information found in the knowledge base.",
            "sources": [],
            "chunks_used": 0
        }
    
    # Step 2 - build context from chunks
    context = build_context(chunks)

    # Step 2.5 - build context from chunks
    history_text = build_history_string(history, max_messages=5, max_chars=1800)
    
    # Step 3 - generate answer
    prompt = f"""
You are a helpful research assistant. Use ONLY the provided 'Context' (below) to answer the user's question.
If the answer is not in the context or is not matching even a little bit then only, respond exactly: "I couldn't find this in the provided documents."

Always be concise and accurate. Cite sources you used in square brackets like [Source 1], [Source 2].

--- Conversation history (most recent first) ---
{history_text if history_text else "(no recent history)"}

--- Context (documents) ---
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