# MCP-Integration für OpenHands: Entwicklerdokumentation

## Einführung

Diese Dokumentation bietet einen umfassenden Leitfaden zur Implementation des Model Context Protocol (MCP) in OpenHands. Sie basiert auf aktuellen Feature-Requests, Pull-Requests und Diskussionen in der OpenHands-Community sowie bewährten Praktiken aus dem breiteren MCP-Ökosystem.

## Inhaltsverzeichnis

1. [Was ist das Model Context Protocol (MCP)?](#was-ist-das-model-context-protocol-mcp)
2. [Aktueller Status von MCP in OpenHands](#aktueller-status-von-mcp-in-openhands)
3. [Architekturüberblick](#architekturüberblick)
4. [Implementation von MCP in OpenHands](#implementation-von-mcp-in-openhands)
   - [Microagent-basierte Integration](#microagent-basierte-integration)
   - [Kernkomponenten](#kernkomponenten)
   - [MCP-Client-Implementation](#mcp-client-implementation)
   - [Konfiguration](#konfiguration)
5. [Beispiel: Integration von n8n über MCP](#beispiel-integration-von-n8n-über-mcp)
6. [Best Practices und Sicherheitsüberlegungen](#best-practices-und-sicherheitsüberlegungen)
7. [Ressourcen und Referenzen](#ressourcen-und-referenzen)

## Was ist das Model Context Protocol (MCP)?

Das Model Context Protocol (MCP) ist ein offener Standard, der von Anthropic entwickelt wurde und die standardisierte Interaktion zwischen KI-Modellen und externen Tools/Datenquellen ermöglicht. MCP fungiert als "USB für KI-Integrationen" und löst das Problem fragmentierter Integrationen zwischen KI-Anwendungen und externen Tools.

MCP verwendet drei Hauptkomponenten:
- **MCP-Hosts**: Programme wie Claude Desktop oder OpenHands, die Zugriff auf externe Daten benötigen
- **MCP-Clients**: Protokollclients, die 1:1-Verbindungen mit Servern herstellen
- **MCP-Server**: Leichtgewichtige Programme, die spezifische Funktionen über das standardisierte Protokoll bereitstellen

## Aktueller Status von MCP in OpenHands

Derzeit gibt es mehrere Feature-Requests für MCP-Unterstützung in OpenHands, wobei mit PR #7620 bereits ein erster Implementierungsansatz eingereicht wurde. Diese Implementation ermöglicht die Integration von MCP-Servern über das Microagent-System von OpenHands.

## Architekturüberblick

Die MCP-Integration in OpenHands folgt einem modularen Ansatz, der Microagents als Einstiegspunkt nutzt. Hier ein Überblick der Architektur:

```
┌────────────────────────────────────────────────────────┐
│                     OpenHands UI                       │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    Microagent-System                   │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│  │ MCP-Client  │   │ Tool-Manager│   │MCP-Konfigu- │   │
│  │ Manager     │   │             │   │ration       │   │
│  └──────┬──────┘   └─────────────┘   └─────────────┘   │
└─────────┼──────────────────────────────────────────────┘
          │
┌─────────▼─────────┐       ┌───────────────────────────┐
│                   │       │    Externe MCP-Server     │
│  MCP-Clients      ├───────►  (lokale & remote Server) │
│                   │       │                           │
└───────────────────┘       └───────────────────────────┘
```

## Implementation von MCP in OpenHands

### Microagent-basierte Integration

Die aktuelle Implementation von MCP in OpenHands nutzt das bestehende Microagent-System. Hier ein Beispiel aus PR #7620:

```yaml
---
name: postgresql-db-local
type: knowledge
agent: CodeActAgent
version: 1.0.0
triggers:
  - postgres
  - postgresql
mcp_servers:
  postgres:
    command: "npx"
    args: 
      - "-y"
      - "@modelcontextprotocol/server-postgres"
      - "postgresql://postgres:yourpassword@localhost:5432/postgres"
---
# Use MCP server to interact with a local PostgreSQL database
```

Die Konfiguration eines MCP-Servers erfolgt in der YAML-Frontmatter des Microagents unter dem Schlüssel `mcp_servers`. Jeder Server erhält einen Namen (hier: `postgres`) und Konfigurationsoptionen.

### Kernkomponenten

Die Hauptkomponenten der MCP-Integration in OpenHands sind:

1. **MCP-Client-Manager**: Verwaltet die Verbindungen zu MCP-Servern
2. **Tool-Manager**: Registriert MCP-Tools beim Agenten
3. **MCP-Server-Proxy**: Leitet Anfragen an die entsprechenden Server weiter

### MCP-Client-Implementation

Die Implementation des MCP-Clients in OpenHands umfasst folgende Funktionalitäten:

1. **Starten und Verbinden mit MCP-Servern**
2. **Laden von Tools von MCP-Servern**
3. **Aufrufen von Tools und Verarbeiten von Antworten**

Hier ein konzeptioneller Code für die MCP-Client-Implementation:

```python
class MCPClient:
    """Client für die Kommunikation mit MCP-Servern."""
    
    def __init__(self, server_config):
        """Initialisiert den MCP-Client mit Server-Konfiguration.
        
        Args:
            server_config: Konfiguration des MCP-Servers
        """
        self.config = server_config
        self.transport_type = server_config.get("transport_type", "stdio")
        self.command = server_config.get("command")
        self.args = server_config.get("args", [])
        self.env = server_config.get("env", {})
        self.process = None
        self.request_id = 0
        
    async def start(self):
        """Startet den MCP-Server-Prozess und initialisiert die Verbindung."""
        if self.transport_type == "stdio":
            # Starte Prozess mit Subprocess
            self.process = await asyncio.create_subprocess_exec(
                self.command, *self.args,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=self.env
            )
        elif self.transport_type == "sse":
            # Implementiere SSE-Transport
            pass
        else:
            raise ValueError(f"Unsupported transport type: {self.transport_type}")
        
    async def list_tools(self):
        """Fragt die verfügbaren Tools vom MCP-Server ab."""
        return await self.send_request("mcp.listTools")
        
    async def call_tool(self, tool_name, arguments):
        """Ruft ein Tool auf dem MCP-Server auf.
        
        Args:
            tool_name: Name des aufzurufenden Tools
            arguments: Parameter für den Tool-Aufruf
            
        Returns:
            Das Ergebnis des Tool-Aufrufs
        """
        return await self.send_request("mcp.callTool", {
            "name": tool_name,
            "arguments": arguments
        })
        
    async def send_request(self, method, params=None):
        """Sendet eine JSON-RPC-Anfrage an den MCP-Server.
        
        Args:
            method: Die aufzurufende RPC-Methode
            params: Parameter für die Methode
            
        Returns:
            Die Antwort des Servers
        """
        self.request_id += 1
        request = {
            "jsonrpc": "2.0",
            "id": self.request_id,
            "method": method,
            "params": params or {}
        }
        
        # Sende Anfrage an Server
        request_str = json.dumps(request) + "\n"
        self.process.stdin.write(request_str.encode())
        await self.process.stdin.drain()
        
        # Warte auf Antwort
        response_line = await self.process.stdout.readline()
        response = json.loads(response_line.decode())
        
        if "error" in response:
            raise Exception(f"MCP error: {response['error']}")
            
        return response.get("result")
        
    async def stop(self):
        """Beendet den MCP-Server-Prozess."""
        if self.process:
            self.process.terminate()
            await self.process.wait()
```

### Konfiguration

Die Konfiguration von MCP-Servern in OpenHands erfolgt über Microagents. Ein Microagent kann eine Liste von MCP-Servern definieren, die beim Laden des Microagents initialisiert werden.

Beispiel für einen Microagent mit MCP-Konfiguration:

```yaml
---
name: github-tools
type: knowledge
agent: CodeActAgent
version: 1.0.0
triggers:
  - github
  - issue
  - pull request
mcp_servers:
  github:
    command: "npx"
    args: 
      - "-y"
      - "@modelcontextprotocol/server-github"
    env:
      GITHUB_TOKEN: "${GITHUB_TOKEN}"
---
# Use GitHub MCP server to interact with repositories, issues, and pull requests
```

## Beispiel: Integration von n8n über MCP

Die Integration von n8n mit OpenHands über MCP ermöglicht die Ausführung von n8n-Workflows direkt aus dem KI-Agenten. Hier ein Beispiel für einen n8n-MCP-Server:

```yaml
---
name: n8n-workflows
type: knowledge
agent: CodeActAgent
version: 1.0.0
triggers:
  - workflow
  - automation
  - n8n
mcp_servers:
  n8n:
    transport_type: "sse"
    url: "http://localhost:5678/mcp/endpoint"
    auth:
      type: "bearer"
      token: "${N8N_API_TOKEN}"
---
# Use n8n MCP server to create and execute workflows
# 
# You can use this microagent to:
# 1. List available workflows
# 2. Execute workflows with parameters
# 3. Create new workflows
```

Die tatsächliche Implementation des n8n-MCP-Servers müsste separat erfolgen, aber OpenHands könnte diesen Server über das MCP-Protokoll nutzen.

## Best Practices und Sicherheitsüberlegungen

Bei der Implementation von MCP in OpenHands sollten folgende Best Practices und Sicherheitsaspekte berücksichtigt werden:

1. **Validierung der Eingaben**: Alle Eingaben für MCP-Tools sollten validiert werden, um Injection-Angriffe zu verhindern.
2. **Sichere Handhabung von Anmeldedaten**: Anmeldedaten wie API-Tokens sollten sicher gespeichert und übertragen werden, z.B. über Umgebungsvariablen.
3. **Berechtigungsmodell**: Implementieren Sie ein Berechtigungsmodell, das Benutzer über Aktionen von MCP-Tools informiert und Genehmigungen einholt.
4. **Tool-Einschränkungen**: Beschränken Sie die verfügbaren Tools basierend auf den Benutzerberechtigungen.
5. **Protokollierung**: Protokollieren Sie MCP-Aufrufe für Audit-Zwecke.

## Ressourcen und Referenzen

- [Model Context Protocol - Offizielle Dokumentation](https://modelcontextprotocol.io/)
- [MCP Server-Sammlung](https://github.com/modelcontextprotocol/servers)
- [OpenHands GitHub Repository](https://github.com/All-Hands-AI/OpenHands)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [MCP JavaScript SDK](https://github.com/modelcontextprotocol/js-sdk)
