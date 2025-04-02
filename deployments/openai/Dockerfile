FROM ../base/Dockerfile.base

ARG CONFIG_PATH=./deployments/openai/config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit OpenAI"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml