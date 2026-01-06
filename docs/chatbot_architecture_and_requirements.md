# Chatbot Architecture and Requirements

This document details the architecture, functionality, and requirements of the "ShopSpark" Chatbot (formerly Concierge). It is intended to serve as a reference for rewriting or refactoring the system.

## 1. System Overview

The chatbot is a **Retrieve-Augmented Generation (RAG)** system designed to act as a virtual shop assistant. It uses a **Hybrid Search** approach (Vector + Lexical) to retrieve relevant store policy and product information before generating a response using a large language model (LLM).

### Core Components

1.  **Frontend Widget**: A lightweight, dependency-free JavaScript class (`ChatConcierge`) embedded in the Shopify theme. Handles UI, streaming, and rich entity rendering.
2.  **Backend API**: A Node.js service (external to the theme) that handles authentication, search, and generation.
3.  **Search Engine**: A hybrid system combining MySQL `FULLTEXT` search (lexical) and Google Gemini Embeddings (vector), fused via Reciprocal Rank Fusion (RRF).

---

## 2. Frontend Implementation

The frontend is implemented in `assets/chat-concierge.js` as a class `ChatConcierge`.

### 2.1 Initialization & Configuration

- **Constructor**: Accepts a config object.
  - `apiUrl`: Defaults to `http://localhost:8001/api/concierge/chat` (needs to be configurable for production).
  - `mascotName`: Defaults to "Sweetie".
- **Dependencies**:
  - `FingerprintJS`: Used for persistent visitor identification.
  - `ChatMarkdownRenderer`: Custom class for safe markdown rendering.

### 2.2 Visitor Identification (Fingerprinting)

- **Mechanism**: The bot uses `FingerprintJS` to generate a unique Visitor ID (`cfpid`).
- **Persistence**: This ID is cached in `localStorage` (`cfpid`) to maintain session continuity across page reloads.
- **Usage**: The `cfpid` is sent with every API request to allow the backend to thread conversations.

### 2.3 State Management

- **Local State**: Tracks `isOpen`, `isLoading`, `messages[]`, and `history[]`.
- **Persistence**:
  - _Current Status_: **Disabled**. The `saveHistory` and `loadHistory` methods exist but `localStorage` logic is intentionally commented out to ensure a fresh session on reload (per user requirement).
  - _Requirement_: If persistence is re-enabled, it must handle `Date` object revival and tool-response HTML regeneration.

### 2.4 Mobile Viewport Handling

- **Problem**: Mobile browsers resize the viewport when the on-screen keyboard opens, often hiding the input field.
- **Solution**: The class uses the `Visual Viewport API` to dynamically resize the chat interface when keyboard appears.
  - Listeners: `visualViewport.resize`, `visualViewport.scroll`.
  - Logic: hard-sets `height` and `top` styles to match the visual viewport when screen width < 480px.

---

## 3. API & Network Layer

The communication between frontend and backend is **stateless** (REST-like) but uses **Streaming** for responses.

### 3.1 Request Contract

**Method**: `POST`
**URL**: `/api/concierge/chat`
**Headers**: `Content-Type: application/json`

**Payload**:

```json
{
  "message": "User's query text",
  "history": [
    { "role": "user", "text": "Previous msg" },
    { "role": "model", "text": "Previous response" }
  ],
  "cfpid": "visitor-unique-id"
}
```

### 3.2 Response Contract (Streaming NDJSON)

The backend responds with a stream of **Newline Delimited JSON (NDJSON)**. The frontend `TextDecoder` reads this stream chunk by chunk.

**Stream Event Types**:

1.  **Text Chunk** (`type: "text"`)

    - Standard streaming token. Appended to the current message bubble.
    - ```json
      { "type": "text", "content": "Hello" }
      ```

2.  **Rich Entities** (`type: "entities"`) _Crucial for UX_

    - Sent when the LLM decides to show products or policies.
    - **Frontend Logic**:
      - `product`: Renders a Carousel (if multiple) or a Card (if single).
      - `policy`: Renders a distinct Policy Card.
    - ```json
      {
        "type": "entities",
        "entities": [
          { "type": "product", "name": "Praline Box", "price": "24.00", "imageUrl": "...", ... },
          { "type": "policy", "title": "Shipping", "url": "..." }
        ]
      }
      ```

3.  **Error** (`type: "error"`)
    - Graceful failure. The frontend removes the "typing" bubble and shows a fallback message ("My apologies, darlin'...").

---

## 4. Backend Logic Requirements (Reconstruction)

If rewriting the backend, the following logic must be preserved to maintain parity.

### 4.1 Hybrid Search Strategy

The bot does _not_ rely on simple vector similarity alone. It uses an **"Entrance Exam"** strategy:

1.  **Vector Search**: Google Gemini `text-embedding-004`. Chunks must have cosine similarity > **0.55**.
2.  **Lexical Search**: MySQL `FULLTEXT` search for exact industry terms (e.g., "gluten-free").
3.  **Fusion (RRF)**: Results are combined using **Reciprocal Rank Fusion** ($k=60$).
    $$ Score = \sum \frac{1}{60 + rank} $$
    _Requirement_: The backend must verify both semantic meaning and keyword presence to avoid hallucinations.

### 4.2 Persona Configuration ("Spark")

- **Identity**: Southern Hostess.
- **Tone**: Warm, polite, professional ("Sugar", "Darlin'").
- **Constraint**: Must never break character.
- **Mascot Prompt**: Pre-pended to every system instruction.

### 4.3 Content Data Structure

- **Chunks**: Text is split into ~400 char overlapping chunks.
- **Augmentation**:
  - **Context Labels**: AI-generated headers (e.g., `[Context: Refund Policy]`) to prevent context bleeding.
  - **Keywords**: Synonyms attached to chunks to boost Lexical Search discovery.

---

## 5. UI/UX Requirements

### 5.1 Widget Components

- **FAB (Floating Action Button)**: Toggles chat.
- **Tooltip**: "How can I help you?" bubble.
  - _Logic_: Appears after 2s. Reappears every 2 mins if inactive (timer controlled). Hides on click.
- **Typing Indicator**: 3-dot animation (`isTyping: true` state).

### 5.2 Rich Rendering

- **Markdown**: Basic formatting (bold, italic) + Links (`[label](url)`).
- **Product Carousel**:
  - Horizontal scroll with snap.
  - Navigation arrows.
  - Active dots indicator.
- **Product/Policy Cards**: Distinct visual styles (White background for products, Off-white `#fffcf8` for policies).

### 5.3 Error Recovery

- If the stream fails or network breaks, the bot must **not** crash.
- It should remove the pending typing bubble.
- It should insert a polite, in-character error message.
