# 🔍 Research Helper — RAG-Powered Document Intelligence

> Upload any document or URL and instantly query it with natural language. A full-stack AI application with a Flutter mobile frontend and a FastAPI RAG backend.

---

## Overview

Research Helper is a full-stack **Retrieval-Augmented Generation (RAG)** application that transforms static documents into interactive, queryable knowledge bases — right from your phone.

The mobile app lets you create and manage research projects, ingest PDFs or URLs with live progress tracking, and have a natural language conversation with your documents. The backend handles all the heavy lifting: semantic chunking, vector embeddings, and grounded answer generation via Gemini 2.5 Flash.

Built to be fast, accurate, and hallucination-resistant — every answer is strictly grounded in your documents with source citations included.

---

## ✨ Features

### 📱 Mobile App (Flutter)
- **Beautiful dark theme** with polished, intuitive UX
- **Project-based organisation** — manage multiple research projects independently
- **Swipeable project tiles** — swipe left to delete, swipe right to edit
- **Multi-document projects** — add multiple PDFs or URLs to a single project
- **Live ingestion progress** — real-time SSE streaming shows exactly what's happening step by step
- **Persistent local storage** — projects and sessions stored locally with Hive
- **Anonymous user identity** — auto-generated UUID via SharedPreferences, no sign-up required
- **Conversational Q&A** — multi-turn chat with full conversation history

### ⚙️ Backend (FastAPI)
- **Multi-format ingestion** — PDFs, URLs, plain text, markdown, and JSON
- **Semantic search** — BGE embeddings with cosine similarity for deep contextual retrieval
- **Auto-summarization** — AI-generated document summary on every ingestion
- **Streaming responses** — real-time SSE for ingestion and summarization
- **Multi-user, multi-project** — fully isolated vector stores per user and project
- **Auto-cleanup** — scheduled session cleanup to manage storage efficiently

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         Flutter Mobile App          │
│  Dark Theme · Hive · SharedPrefs    │
└──────────────┬──────────────────────┘
               │ HTTP + SSE Streaming
               ▼
┌─────────────────────────────────────┐
│          FastAPI Backend            │
├─────────────┬───────────────────────┤
│  Ingestion  │  PDF / URL / Text     │
│  Pipeline   │  → Chunker            │
│             │  → BGE Embedder       │
│             │  → ChromaDB           │
├─────────────┼───────────────────────┤
│   Query     │  Semantic Search      │
│   Pipeline  │  → Gemini 2.5 Flash   │
│             │  → Cited Answer       │
└─────────────┴───────────────────────┘
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/ingest/file` | Upload and ingest a PDF or text file |
| `POST` | `/ingest/url` | Ingest content from a URL |
| `POST` | `/ingestUrl/stream` | Ingest URL with real-time SSE progress |
| `POST` | `/ingestUrl/add/stream` | Add a URL to an existing project |
| `POST` | `/ingest/file/stream` | Ingest file with real-time SSE progress |
| `POST` | `/query` | Query your document with natural language |
| `POST` | `/summarize` | Get an AI-generated document summary |
| `DELETE` | `/session` | Delete a user's project session |
| `POST` | `/admin/cleanup` | Manually trigger old session cleanup |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile App | Flutter (Dart) |
| Local Storage | Hive + SharedPreferences |
| API Framework | FastAPI |
| Vector Database | ChromaDB |
| Embeddings | BGE-small-en-v1.5 (BAAI) |
| LLM | Gemini 2.5 Flash |
| Document Parsing | pdfplumber, trafilatura |
| Text Splitting | LangChain RecursiveCharacterTextSplitter |
| Streaming | Server-Sent Events (SSE) |

---

## 📁 Project Structure

```
research-helper/
├── frontend/                        # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/                  # Project & message models
│   │   ├── screens/                 # UI screens
│   │   └── services/                # API & storage services
│   └── pubspec.yaml
│
└── backend/                         # FastAPI backend
    ├── main.py                      # App entry point & routes
    ├── requirements.txt
    ├── ingestion/
    │   ├── loader.py                # PDF, URL, text loaders
    │   ├── chunker.py               # Document splitting
    │   └── embedder.py              # BGE embedding model
    ├── storage/
    │   └── vector_store.py          # ChromaDB operations
    └── query/
        ├── search.py                # Semantic search
        ├── synthesizer.py           # Answer generation
        └── summarizer.py            # Document summarization
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to open a pull request or file an issue.

---

## 📄 License

MIT License — feel free to use, modify, and distribute.