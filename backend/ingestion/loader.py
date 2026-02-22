import pdfplumber
import trafilatura
import json
from pathlib import Path
from langchain_core.documents import Document

def load_pdf(file_path: str) -> str:
    text = ""
    with pdfplumber.open(file_path) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
    return text.strip()

def load_url(url: str) -> str:
    downloaded = trafilatura.fetch_url(url)
    text = trafilatura.extract(downloaded)
    return text.strip() if text else ""

def load_text(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()

def load_json(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return json.dumps(data, indent=2)

def load_document(source: str) -> list[Document]:
    
    if source.startswith("http://") or source.startswith("https://"):
        text = load_url(source)
    else:
        ext = Path(source).suffix.lower()
        if ext == ".pdf":
            text = load_pdf(source)
        elif ext == ".json":
            text = load_json(source)
        elif ext in (".txt", ".md", ".markdown"):
            text = load_text(source)
        else:
            raise ValueError(f"Unsupported file type: {ext}")

    if not text:
        raise ValueError(f"Could not extract text from {source}")

    return [Document(page_content=text, metadata={"source": source})]
