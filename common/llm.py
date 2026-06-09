"""LLM factory dùng chung cho tất cả agents.

Sử dụng Gemini API qua Google's OpenAI-compatible endpoint, nên có thể
giữ nguyên LangChain ChatOpenAI integration hiện có.
"""

import os

from langchain_openai import ChatOpenAI


def get_llm() -> ChatOpenAI:
    """Trả về ChatOpenAI client kết nối đến Gemini API."""
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key or api_key.strip() in {"your_key_here", "your_gemini_key_here"}:
        raise ValueError(
            "Thiếu Gemini API key. Set GEMINI_API_KEY trong .env "
            "(hoặc GOOGLE_API_KEY trong environment)."
        )

    return ChatOpenAI(
        temperature=0.3,
        model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
        openai_api_key=api_key,
        openai_api_base=os.getenv(
            "GEMINI_API_BASE",
            "https://generativelanguage.googleapis.com/v1beta/openai/",
        ),
    )
