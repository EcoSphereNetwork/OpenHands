# ChatGPT Agent Guide

This document provides instructions for ChatGPT-based agents working in this repository.

## Repository Structure
- `openhands/` – core backend code
- `microagents/` – reusable agent prompts
- `frontend/` – React application
- `tests/` – unit tests
- `docs/` – documentation assets
- `evaluation/` – benchmark tasks and scripts

## Coding Guidelines
- Use **Python 3.12** and **TypeScript/JavaScript** via Node 22.
- Run `make install-pre-commit-hooks` before modifying code.
- Python style is enforced by **ruff**, **mypy** and other pre-commit hooks defined in `dev_config/python/.pre-commit-config.yaml`.
- Frontend code should pass `npm run lint:fix` and build successfully.

## Testing Instructions
- Backend: `poetry run pytest ./tests/unit/test_*.py`
- Frontend: `npm run test`
- Some workflows also run `npm run test:coverage`.

## Development Workflow
1. Install dependencies with `make build` or follow `Development.md`.
2. Ensure pre-commit hooks pass: `pre-commit run --config ./dev_config/python/.pre-commit-config.yaml`.
3. Run the relevant tests listed above.
4. Open a pull request using `.github/pull_request_template.md` and keep the same branch after creation.

## Available Microagents
The `microagents/` folder contains additional prompts such as `github.md`, `docker.md`, `security.md`, and more. Consult each file for specialist instructions.

## OpenHands Issue Resolver
This repository uses the [OpenHands Resolver](https://github.com/All-Hands-AI/openhands-resolver). Trigger it on issues or comments with the `fix-me` label or by mentioning **@openhands-agent**.

Repository secrets should define:
- `LLM_MODEL`
- `OPENHANDS_MAX_ITER`
- `OPENHANDS_MACRO`
- `TARGET_BRANCH`
- `TARGET_RUNNER`
