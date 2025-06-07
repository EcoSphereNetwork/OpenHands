# Claude Agent Guide

These notes target Claude-powered agents interacting with this repository.

## Repository Structure
- `openhands/` – backend services
- `microagents/` – prompt library
- `frontend/` – user interface
- `tests/` – unit tests
- `docs/` – documentation
- `evaluation/` – benchmarks

## Coding Standards
- Target **Python 3.12** and modern JavaScript/TypeScript.
- Install pre-commit hooks via `make install-pre-commit-hooks` before editing.
- Use the existing configuration in `dev_config/python` for formatting with `ruff` and static checks via `mypy`.
- Frontend changes must pass `npm run lint:fix` and `npm run build`.

## Testing
- Run backend tests with `poetry run pytest ./tests/unit/test_*.py`.
- For the frontend, execute `npm run test` (and `npm run test:coverage` when needed).

## Development and PR Workflow
1. Follow `Development.md` for environment setup.
2. Ensure pre-commit hooks and all tests pass locally.
3. Create a pull request using `.github/pull_request_template.md`. Keep working on the same branch after the PR is opened.
4. Use the `fix-me` label or mention **@openhands-agent** to invoke automated issue resolution.

## Repository Secrets
Configure the following secrets for OpenHands automation:
- `LLM_MODEL`
- `OPENHANDS_MAX_ITER`
- `OPENHANDS_MACRO`
- `TARGET_BRANCH`
- `TARGET_RUNNER`
