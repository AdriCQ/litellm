# Atajos del stack LiteLLM (usa los de AGENTS.md como referencia).
.PHONY: restart up down logs

restart:  # recarga config.yaml (NO recarga .env: ver AGENTS.md)
	docker compose restart litellm

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f litellm
