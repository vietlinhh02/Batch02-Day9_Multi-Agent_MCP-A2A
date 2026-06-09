# VinUni Legal AI Multi-Agent System

Hệ thống tư vấn pháp lý phân tán sử dụng nhiều AI agents phối hợp với [A2A Protocol](https://github.com/google/A2A) của Google. Được xây dựng bằng **LangGraph**, **LangChain**, và **a2a-sdk**, project này là demo thực tế vừa là lộ trình học tập từ cơ bản đến nâng cao — từ gọi LLM đơn giản (Stage 1) đến mạng multi-agent phân tán hoàn chỉnh (Stage 5).

## Kiến Trúc

```
                     ┌─────────────────────┐
                     │  Registry Service   │  :10000
                     │  /register          │
                     │  /discover/{task}   │
                     └─────────┬───────────┘
                               │  (agents self-register on startup)
          ┌────────────────────┼─────────────────────┐
          │                    │                     │
   Tax Agent :10102   Law Agent :10101    Compliance Agent :10103
          │                    │                     │
          └─────────► delegates in parallel ◄────────┘
                               │
                        Customer Agent :10100
                               │
                             User
```

**Customer Agent** tiếp nhận câu hỏi từ người dùng và chuyển cho **Law Agent** phân tích các khía cạnh pháp lý, sau đó dispatch song song đến **Tax Agent** và **Compliance Agent** thông qua LangGraph's `Send` API. Kết quả được tổng hợp thành phân tích pháp lý toàn diện.

Tất cả agent discovery đều động — các agents đăng ký capabilities với **Registry** khi khởi động và tự khám phá nhau tại runtime. Không hardcode URLs.

### Chi Tiết Agents

| Agent | Port | LangGraph Pattern | Vai trò |
|---|---|---|---|
| Customer Agent | 10100 | A2A gateway | Điểm vào — chuyển câu hỏi đến Law Agent |
| Law Agent | 10101 | Custom `StateGraph` | Điều phối — phân tích luật, delegate song song |
| Tax Agent | 10102 | `create_react_agent` | Chuyên gia — thuế IRS, penalties, FBAR/FATCA |
| Compliance Agent | 10103 | `create_react_agent` | Chuyên gia — SEC, SOX, FCPA, GDPR, AML |
| Registry | 10000 | FastAPI (not an agent) | Service discovery và đăng ký agent |

### Luồng Request

```
Câu hỏi người dùng
  → Customer Agent: LLM phát hiện domain pháp lý, gọi delegate tool
    → Registry: discover("legal_question") → Law Agent endpoint
    → Law Agent:
        [analyze_law]      Phân tích hợp đồng/tort
        [check_routing]    LLM quyết định: cần_tax? cần_compliance?
        [call_tax]         ──→ Registry discover → Tax Agent (A2A)     ┐
        [call_compliance]  ──→ Registry discover → Compliance (A2A)    ├ song song
        [aggregate]        Tổng hợp tất cả phân tích thành response   ┘
  → Customer Agent trả response cho người dùng
```

### Thiết kế chính

- **Dynamic discovery** — agents tìm nhau thông qua Registry, không hardcode URLs
- **Parallel delegation** — LangGraph `Send` API dispatch nhánh tax và compliance đồng thời
- **Trace propagation** — `trace_id` và `context_id` truyền qua mỗi A2A hop để debug
- **Depth guards** — `MAX_DELEGATION_DEPTH = 3` ngăn vòng lặp delegation vô hạn
- **Annotated reducers** — `Annotated[str, _last_wins]` xử lý ghi song song vào state fields

## Công Nghệ

| Layer | Công nghệ |
|---|---|
| Agent framework | [LangGraph](https://langchain-ai.github.io/langgraph/) |
| LLM provider | Gemini API qua Google's OpenAI-compatible endpoint |
| A2A transport | [a2a-sdk](https://pypi.org/project/a2a-sdk/) |
| Registry | FastAPI + in-memory store |
| Package manager | [uv](https://docs.astral.sh/uv/) |

## 📚 Codelab cho Sinh viên VinUni

**Thời gian:** 2 giờ | **Ngôn ngữ:** Tiếng Việt

Codelab hướng dẫn từng bước xây dựng hệ thống multi-agent, từ đơn giản đến phức tạp:

- **[CODELAB.md](CODELAB.md)** - Hướng dẫn chi tiết cho sinh viên
- **[INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md)** - Hướng dẫn cho giảng viên
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Tài liệu tham khảo nhanh
- **[exercises/](exercises/)** - Bài tập thực hành với skeleton code
- **[exercises/SOLUTIONS.md](exercises/SOLUTIONS.md)** - Đáp án chi tiết

### Lộ Trình Học

```
Stage 1: Direct LLM (20 phút)
    ↓
Stage 2: RAG + Tools (30 phút)
    ↓
Stage 3: ReAct Agent (25 phút)
    ↓
Stage 4: Multi-Agent (30 phút)
    ↓
Stage 5: Distributed A2A (30 phút)
    ↓
Tổng kết & Q&A (15 phút)
```

**Bắt đầu:** Đọc [CODELAB.md](CODELAB.md)

---

## Bắt Đầu

### Yêu cầu

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) package manager
- [Gemini API key](https://aistudio.google.com/app/apikey)

### Cài đặt

```bash
# Clone và cài đặt
git clone <repo-url>
cd vinuni-legal-ai-agents
uv sync

# Cấu hình environment
cp .env.example .env
# Sửa .env với Gemini API key của bạn
```

### Chạy toàn bộ hệ thống (Stage 5)

```bash
# Khởi động 5 services (registry + 4 agents)
./start_all.sh

# Ở terminal khác, gửi câu hỏi test
uv run python test_client.py
```

### Chạy demo từng Stage

Không cần servers — mỗi demo chạy như script độc lập:

```bash
uv run python stages/stage_1_direct_llm/main.py
uv run python stages/stage_2_rag_tools/main.py
uv run python stages/stage_3_single_agent/main.py
uv run python stages/stage_4_multi_agent/main.py
```

## Các Giai Đoạn Phát Triển LLM

Thư mục `stages/` chứa các demo tiến triển từ đơn giản đến phức tạp, khớp với roadmap trong `docs/10_llm_roadmap.svg`:

| Stage | Tên | Nội dung |
|---|---|---|
| **1** | Direct LLM Calling | Gọi LLM đơn giản, không tools, không memory. |
| **2** | LLM + RAG / Tools | Tool calling với knowledge base và damage calculator. |
| **3** | Single Agent (ReAct) | Vòng lặp Think → Act → Observe tự động qua `create_react_agent`. |
| **4** | Multi-Agent (In-Process) | Nhiều agents chuyên môn hóa chạy song song qua `StateGraph` + `Send` API. |
| **5** | Distributed A2A (Project này) | Hệ thống phân tán hoàn chỉnh — mỗi agent là HTTP service độc lập giao tiếp qua A2A. |

Mỗi stage có `architecture.svg` diagram và `main.py` tự chứa.

## Cấu Trúc Project

```
vinuni-legal-ai-agents/
├── start_all.sh               # Khởi động tất cả services
├── test_client.py             # Test client E2E
├── pyproject.toml             # Dependencies (uv-managed)
├── .env.example               # Environment variables
│
├── common/                    # Utilities chia sẻ
│   ├── llm.py                 # get_llm() → ChatOpenAI qua Gemini API
│   ├── a2a_client.py          # delegate() — gửi message A2A
│   └── registry_client.py     # discover() / register() — Registry API
│
├── registry/                  # Service discovery (port 10000)
├── customer_agent/            # Agent điểm vào (port 10100)
├── law_agent/                 # Agent điều phối luật (port 10101)
├── tax_agent/                 # Agent chuyên thuế (port 10102)
├── compliance_agent/          # Agent tuân thủ (port 10103)
│
├── stages/                    # Demo tiến triển (1-4)
│   ├── stage_1_direct_llm/
│   ├── stage_2_rag_tools/
│   ├── stage_3_single_agent/
│   └── stage_4_multi_agent/
│
└── docs/                      # Architecture diagrams (SVG)
```

Mỗi agent module có cấu trúc giống nhau:
- **`graph.py`** — Định nghĩa LangGraph graph (toàn bộ logic agent)
- **`agent_executor.py** — Cầu nối giữa A2A SDK và LangGraph
- **`__main__.py`** — Server bootstrap, agent card, registration

## Cấu Hình

| Biến Môi Trường | Mô tả | Mặc định |
|---|---|---|
| `GEMINI_API_KEY` | Gemini API key từ Google AI Studio | (bắt buộc) |
| `GEMINI_MODEL` | Gemini model identifier | `gemini-2.5-flash` |
| `REGISTRY_URL` | Registry service URL | `http://localhost:10000` |

Có thể đổi sang model Gemini khác được hỗ trợ bởi Gemini API.

## Sơ Đồ Tài Liệu

Thư mục `docs/` chứa các sơ đồ kiến trúc SVG:

| Sơ Đồ | Chủ Đề |
|---|---|
| `01_why_multiagent` | Tại sao dùng multi-agent thay vì LLM đơn lẻ |
| `02_a2a_vs_traditional` | A2A protocol so với multi-agent truyền thống |
| `03_a2a_protocol` | Chi tiết kỹ thuật A2A protocol |
| `04_system_architecture` | Kiến trúc toàn bộ hệ thống |
| `05_law_agent_graph` | Phân tích sâu Law Agent StateGraph |
| `06_request_flow` | Luồng request end-to-end với trace propagation |
| `07_a2a_intro` | Giới thiệu A2A protocol |
| `08_a2a_core_concepts` | Khái niệm cốt lõi A2A (Agent Cards, Tasks, Parts) |
| `09_a2a_interaction_flow` | Các mẫu luồng tương tác A2A |
| `10_llm_roadmap` | Lộ trình phát triển LLM (Stages 1–5) |
