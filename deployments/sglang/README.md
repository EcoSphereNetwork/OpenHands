# OpenHands mit mehreren lokalen LLMs über SGLang

Diese Lösung ermöglicht die Verwendung von drei lokalen OpenHands-Modellen innerhalb einer einzigen OpenHands-Instanz über SGLang. Der Wechsel zwischen den Modellen erfolgt direkt über die OpenHands-Benutzeroberfläche.

## Unterstützte Modelle

- **OpenHands-LM 1.5B (v0.1)** - Kompaktes, schnelles Modell für einfache Aufgaben
- **OpenHands-LM 7B (v0.1)** - Mittelgroßes Modell mit gutem Gleichgewicht aus Geschwindigkeit und Fähigkeiten
- **OpenHands-LM 32B (v0.1)** - Großes Modell für komplexe Aufgaben (erfordert leistungsfähige Hardware)

## Voraussetzungen

- **Docker** und **Docker Compose** (neueste stabile Version)
- **NVIDIA-GPU mit CUDA-Unterstützung** (oder leistungsstarke CPU für das 1.5B-Modell)
- **NVIDIA Container Toolkit** (nvidia-docker)

Empfohlene Hardware:
- Für 1.5B: GPU mit mind. 4GB VRAM oder moderne CPU
- Für 7B: GPU mit mind. 8GB VRAM (z.B. RTX 3060 oder besser)
- Für 32B: GPU mit mind. 24GB VRAM (z.B. RTX 4090, A5000 oder besser)

## Schnellstart

1. **Repository klonen oder Setup-Skript ausführen:**

```bash
# Option 1: Repository klonen
git clone https://github.com/EcoSphereNetwork/OpenHands.git
cd deployments/sglang
chmod +x setup-openhands-multimodel.sh
./setup-openhands-multimodel.sh
cd ~/openhands-multi-model

# Option 2: Setup-Skript herunterladen und ausführen
curl -o setup-openhands-multimodel.sh https://raw.githubusercontent.com/EcoSphereNetwork/OpenHands/main/deployments/sglang/multi-model-openhands-setup.sh
chmod +x setup-openhands-multimodel.sh
./setup-openhands-multimodel.sh
cd ~/openhands-multi-model
```

2. **Umgebungsvariablen konfigurieren:**

```bash
cp env.example .env
# Optional: Bearbeiten Sie die .env-Datei nach Ihren Bedürfnissen
```

3. **Container starten:**

```bash
docker-compose up -d
```

4. **Modelle initialisieren:**

```bash
./setup-models.sh
```

5. **Zugriff auf die Dienste:**
   - OpenHands: http://localhost:3004
   - SGLang Admin-Interface: http://localhost:30001

## Konfiguration

Die Konfiguration erfolgt über die `.env`-Datei und die `config.toml`:

### Wichtige Umgebungsvariablen

| Variable | Beschreibung | Standardwert |
|----------|--------------|--------------|
| `SGLANG_MODEL` | Standard-Modell beim Start | `all-hands/openhands-lm-1.5b-v0.1` |
| `SGLANG_DEVICE_MAP` | Geräteauswahl-Strategie | `auto` |
| `SGLANG_QUANTIZATION` | Quantisierungsmethode | `none` (Optionen: `none`, `8bit`, `4bit`) |
| `SGLANG_MAX_MODEL_LEN` | Maximale Kontextlänge | `8192` |
| `SGLANG_UNLOAD_INACTIVE_MODELS` | Entladen nicht aktiver Modelle | `true` |
| `SGLANG_DISK_CACHE` | Modell-Caching aktivieren | `true` |
| `SGLANG_SAFE_MODE` | Verhindert Laden zu großer Modelle | `true` |
| `SGLANG_FALLBACK_MODEL` | Ausweichmodell bei Ressourcenmangel | `all-hands/openhands-lm-1.5b-v0.1` |

### Hardware-spezifische Konfigurationen

#### Systeme mit begrenztem VRAM (8-12GB)

```
SGLANG_QUANTIZATION=4bit
SGLANG_MAX_MODEL_LEN=4096
SGLANG_UNLOAD_INACTIVE_MODELS=true
SGLANG_FORCE_RELEASE_MEMORY=true
```

#### Leistungsstarke Systeme (24GB+ VRAM)

```
SGLANG_QUANTIZATION=none
SGLANG_MAX_MODEL_LEN=16384
SGLANG_PRELOAD_MODELS=all-hands/openhands-lm-1.5b-v0.1,all-hands/openhands-lm-7b-v0.1
```

#### Multi-GPU-Systeme

```
SGLANG_DEVICE_MAP=balanced
SGLANG_NUM_GPUS=2
```

## Verwendung

### Wechseln zwischen Modellen

1. Öffnen Sie die OpenHands-Benutzeroberfläche (http://localhost:3004)
2. Suchen Sie nach dem Modellauswahl-Dropdown-Menü (in der Regel oben in der UI)
3. Wählen Sie eines der konfigurierten Modelle:
   - OpenHands 1.5B
   - OpenHands 7B
   - OpenHands 32B

*Hinweis: Der erste Wechsel zu einem Modell kann einige Zeit dauern, da das Modell geladen werden muss.*

### Empfohlene Anwendungsfälle für jedes Modell

- **1.5B-Modell**: Schnelle, einfache Anfragen, Code-Vervollständigung, grundlegende Assistenz
- **7B-Modell**: Allgemeine Aufgaben, Textgenerierung, einfache bis mittelkomplexe Code-Generierung
- **32B-Modell**: Komplexe Reasoning-Aufgaben, anspruchsvolle Code-Generierung, ausführliche Erklärungen

## Komponenten des Systems

### Architektur

```
OpenHands UI (Port 3004)
      │
      ▼
OpenHands Backend
      │
      ▼
 SGLang-Server (Port 30000/30001)
      │
      ▼
Lokale OpenHands-Modelle
```

### Docker-Container

- **openhands-sglang**: OpenHands-Instanz mit Modellauswahl-UI
- **sglang-server**: Führt die Inferenz der LLMs durch

### Volumes

- **sglang-data**: Speichert heruntergeladene Modelle und Cache
- **sglang-openhands-state**: Persistenter Speicher für OpenHands

## Fehlerbehebung

### Häufige Probleme

| Problem | Mögliche Lösung |
|---------|-----------------|
| Container startet nicht | `docker logs sglang-server` überprüfen |
| "Out of Memory"-Fehler | `SGLANG_QUANTIZATION=4bit` und `SGLANG_MAX_MODEL_LEN` reduzieren |
| Modell nicht gefunden | HF_TOKEN überprüfen (falls Modell privat ist) |
| Sehr langsame Antworten | GPU-Nutzung prüfen, eventuell zu kleines Modell wählen |
| OpenHands-UI reagiert nicht | Logs prüfen: `docker logs openhands-sglang` |

### Diagnose-Befehle

```bash
# Logs des SGLang-Servers ansehen
docker logs sglang-server

# GPU-Nutzung überwachen
nvidia-smi -l 1

# Status der Container prüfen
docker ps -a | grep "sglang\|openhands"

# In den Container einsteigen
docker exec -it sglang-server bash
```

## Erweiterte Konfiguration

### Hinzufügen weiterer Modelle

1. Bearbeiten Sie die `config.toml` und fügen Sie neue Modelleinträge hinzu:

```toml
[model_selector]
enabled = true
models = [
    # Vorhandene Modelle...
    { name = "Neues Modell", model_id = "org/model-name", description = "Beschreibung" },
]
```

2. Aktualisieren Sie das `setup-models.sh` Script, um das neue Modell zu konfigurieren

### Anpassung der SGLang-Parameter

Die SGLang-Konfiguration kann über zusätzliche Umgebungsvariablen in der `docker-compose.yml` angepasst werden:

```yaml
environment:
  - SGLANG_BATCH_SIZE=8            # Größere Batch-Größe für höheren Durchsatz
  - SGLANG_KV_CACHE_PRECISION=fp16 # Reduziert Speicherverbrauch
```

## Ressourcen

- [SGLang Dokumentation](https://docs.sglang.ai/)
- [OpenHands Dokumentation](https://docs.all-hands.dev/)
- [HuggingFace - OpenHands-Modelle](https://huggingface.co/all-hands)
- [NVIDIA Container Toolkit Installation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz - siehe die LICENSE-Datei für Details.

## Mitwirkende

- Ihr Name/Organisation

## Danksagungen

- SGLang-Team für die effiziente LLM-Inferenz-Engine
- All-Hands-AI für die OpenHands-Plattform und die verfügbaren Modelle
