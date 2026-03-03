from google import genai
from storage.vector_store import load_vector_store
from dotenv import load_dotenv
import os

load_dotenv()

_client = None

def get_client():
    global _client
    if _client is None:
        _client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    return _client

def summarize_document(userId: str, projectId: str) -> dict:

    vectorstore = load_vector_store(userId, projectId)

    results = vectorstore.similarity_search(
        "main topic overview summary introduction conclusion",
        k=10
    )

    if not results:
        return {
            "summary": "Could not generate summary, no content found.",
            "session_id": f"{userId}__{projectId}"
        }

    context = "\n\n".join([doc.page_content for doc in results])

    prompt = f"""You are a research assistant. Based on the document excerpts below, write a clear and concise summary.

The summary should:
- Be 3-5 sentences long
- Cover the main topic and key points
- Be easy to understand
- Not reference "the document" or "the text" — just state the information directly

Document excerpts:
{context}

Summary:"""

    response = get_client().models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )
    print("summary is - ")
    print(response.text.strip())
    return {
        "summary": response.text.strip(),
        "session_id": f"{userId}__{projectId}"
    }