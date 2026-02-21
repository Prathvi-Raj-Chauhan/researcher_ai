from google import genai
from storage.vector_store import load_vector_store
from dotenv import load_dotenv
import os

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

def summarize_document(session_id: str) -> dict:
    
    # Step 1 - load the vector store for this session
    vectorstore = load_vector_store(session_id)
    
    # Step 2 - get a broad sample of chunks to summarize
    # we use a generic query to pull a wide variety of chunks
    results = vectorstore.similarity_search(
        "main topic overview summary introduction conclusion",
        k=10
    )
    
    if not results:
        return {
            "summary": "Could not generate summary, no content found.",
            "session_id": session_id
        }
    
    # Step 3 - combine chunks into one context
    context = "\n\n".join([doc.page_content for doc in results])
    
    # Step 4 - ask Gemini to summarize
    prompt = f"""You are a research assistant. Based on the document excerpts below, write a clear and concise summary.

The summary should:
- Be 3-5 sentences long
- Cover the main topic and key points
- Be easy to understand
- Not reference "the document" or "the text" — just state the information directly

Document excerpts:
{context}

Summary:"""

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    return {
        "summary": response.text.strip(),
        "session_id": session_id
    }