FROM ../base/Dockerfile.base

ARG CONFIG_PATH=./deployments/sglang/config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit SGLang für lokale LLMs"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml
