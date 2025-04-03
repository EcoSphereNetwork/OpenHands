FROM ../base/Dockerfile.base

ARG CONFIG_PATH=./deployments/issue-resolver/config.toml
ARG REPO_NAME

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands Issue Resolver für ${REPO_NAME}"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml

# Kopieren der .openhands_instructions, falls vorhanden
COPY ./deployments/issue-resolver/repositories/${REPO_NAME}/.openhands_instructions /app/.openhands_instructions