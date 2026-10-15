# AGENTS.md — litellm proxy stack

Docker Compose stack: LiteLLM gateway (`litellm`) + Postgres (`db`). No app code, tests, lint, or CI.

## Sources of truth

- `config.yaml` — models/providers. Admin UI shows them read-only; edit here.
- `.env` (gitignored) — all secrets. Never put keys in `config.yaml`; use `os.environ/VAR`.
- `docker-compose.yml` — wiring. `DATABASE_URL` comes from compose env, not `.env`.

## Reload rules (easy to get wrong)

- `config.yaml` change only: `docker compose exec litellm kill -USR2 1` (or `restart litellm`).
- `.env` change: `docker compose up -d --force-recreate litellm` — plain `restart` does NOT reload env.
- Verify: `curl http://localhost:4000/v1/models -H "Authorization: Bearer $(grep ^LITELLM_MASTER_KEY .env | cut -d= -f2)"`

## Model conventions

- `assistant-free` is the ONLY active `model_name`: all 32 deployments share it (LiteLLM load-balances/fallbacks across them). Keep original alias as trailing comment, e.g. `model_name: assistant-free # openrouter-inkling-free`. AVISO: mezcla rutas gratuitas, baratas y de pago (`openrouter-auto`, `openrouter-claude`, `gemini-2.5-pro`, `gpt-oss:120b`) — el tráfico puede facturar.
- Free OpenRouter: only >8B total params (totals from OpenRouter `description`, not active MoE params — so `laguna-xs` 33B, `north-mini-code` 30B, `lightning` 30B stay). Excluded: `openrouter/free` router, `lfm-2.5-2.6b` (2.6B), `nemotron-3.5-content-safety` (4B guardrail).
- Ollama Cloud has NO $0 models — Free plan = starter credits + pay-as-you-go per `ollama.com/pricing`. Cloud tags use `:cloud` / `:30b-cloud` suffix; `gpt-oss` uses plain `:20b/:120b`. Cheapest input first: `nemotron-3-super:cloud` ($0.015/M).
- `gemini-flash/pro` still point at 2.5, which Google limits to prior users — the `3.1/3.5-flash-lite` deployments (both with Free Tier) are the low-cost ones.
- Local: `ollama_chat/lfm2.5:8b` (5.2GB) + `ollama_chat/lfm2.5:24b` (15GB) via `os.environ/OLLAMA_LOCAL_API_BASE`, no key. Require `ollama serve` + `ollama pull lfm2.5:8b|lfm2.5:24b` on the host; if down, requests fall back with extra latency — comment them out when unused. LM Studio via `LM_STUDIO_API_BASE`/`LM_STUDIO_API_KEY` (any key value); template stays commented until you set your loaded model ID.
- Groq + Cloudflare blocks stay commented out (do not re-enable without asking).
- Provider prefix quirks: `openrouter/...`, `gemini/...`, `groq/openai/...`, `cloudflare/@cf/...`, Ollama Cloud and AnyAPI use `openai/...` + `api_base`. AnyAPI Qwen Coder ID has NO `:free` suffix — do not add it.
- Free catalog snapshot 2026-10-15; re-check `https://openrouter.ai/api/v1/models` and authenticated AnyAPI `/v1/models` before trusting availability.

## Gotchas

- Image pinned at `berriai/litellm-database:1.105.0`; do not switch to `:latest`.
- `LITELLM_MASTER_KEY` must start with `sk-`; generate with `openssl rand -hex 32`. Never rotate `LITELLM_SALT_KEY` once the DB holds encrypted creds.
- `config.yaml` is mounted read-only at `/app/config.yaml`; `drop_params: true` and `store_model_in_db: true` are intentional.
- Local-provider template at bottom of `config.yaml` uses `http://host.docker.internal:11434`.
