# OpenHands Deployments

Dieses Verzeichnis enthält Konfigurationen und Skripte für die Bereitstellung mehrerer OpenHands-Instanzen in Docker-Containern.

## Übersicht

Das Projekt ist wie folgt strukturiert:

- **base/**: Gemeinsame Basis-Konfigurationen für alle Instanzen
- **anthropic/**: Setup für OpenHands mit Anthropic/Claude
- **openai/**: Setup für OpenHands mit OpenAI
- **ollama/**: Setup für OpenHands mit Ollama (inkl. Ollama-Server)
- **issue-resolver/**: Setup für OpenHands als Issue-Resolver für GitHub-Repositories
- **scripts/**: Hilfreiche Skripte für die Verwaltung der Instanzen

## Voraussetzungen

- Docker und Docker Compose
- Git
- API-Keys für die verwendeten LLM-Provider (Anthropic, OpenAI)
- GitHub-Token für die Issue-Resolver-Funktionalität

## Installation

1. Navigiere zum deployments-Verzeichnis:
   ```bash
   cd deployments
   ```

2. Erstelle eine `.env`-Datei basierend auf `.env.example`:
   ```bash
   cp .env.example .env
   ```

3. Bearbeite die `.env`-Datei und füge deine API-Keys und Tokens ein.

4. Mache die Skripte ausführbar:
   ```bash
   chmod +x scripts/*.sh
   chmod +x issue-resolver/setup-repositories.sh
   chmod +x ollama/setup-models.sh
   ```

## Verwendung

### Alle Instanzen starten

```bash
./scripts/start-all.sh
```

### Alle Instanzen stoppen

```bash
./scripts/stop-all.sh
```

### Einen neuen Issue-Resolver erstellen

```bash
./scripts/create-resolver.sh <repository-name> <port>
```

### Issue-Resolver für alle EcoSphereNetwork-Repositories einrichten

```bash
./issue-resolver/setup-repositories.sh
```

## Zugriff auf die Instanzen

Nach dem Start sind die Instanzen unter folgenden URLs erreichbar:

- Anthropic: http://localhost:3001
- OpenAI: http://localhost:3002
- Ollama: http://localhost:3003
- Issue-Resolver: http://localhost:3100 und folgende Ports

## Anpassung

### Konfigurationsdateien

Jede Instanz hat ihre eigene Konfigurationsdatei (`config.toml`), die angepasst werden kann. Die Basis-Konfiguration befindet sich in `base/config.base.toml`.

### Dockerfiles

Die Dockerfiles für die verschiedenen Instanzen basieren auf `base/Dockerfile.base` und können bei Bedarf angepasst werden.

### Issue-Resolver-Anweisungen

Für jeden Issue-Resolver kann eine `.openhands_instructions`-Datei erstellt werden, die spezifische Anweisungen für den Resolver enthält.

## Persistenz

Alle Instanzen verwenden Docker-Volumes für die Persistenz der Daten:

- Anthropic: `openhands-anthropic-state`
- OpenAI: `openhands-openai-state`
- Ollama: `openhands-ollama-state` und `ollama-data`
- Issue-Resolver: `openhands-resolver-<repo-name>-state`

## Fehlerbehebung

### Logs anzeigen

```bash
docker logs <container-name>
```

### In einen Container einsteigen

```bash
docker exec -it <container-name> bash
```

### Container neu starten

```bash
docker restart <container-name>
```

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) für Details.