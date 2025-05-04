# Konzeptioneller Ansatz zur Integration von MCP in OpenHands

Ich werde einen konzeptionellen Ansatz skizzieren, wie Sie MCP in Ihren OpenHands-Fork implementieren könnten. Dieser Ansatz berücksichtigt die Architektur von OpenHands und die Anforderungen des Model Context Protocols.

## 1. Architekturübersicht

```
OpenHands + MCP Integration
┌────────────────────────────────────────────────────────┐
│                     OpenHands UI                       │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                   MCP-Manager-Modul                    │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│  │ MCP-Client  │   │MCP-Registry │   │MCP-Konfigu- │   │
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

## 2. Hauptkomponenten der Integration

### 2.1 MCP-Manager-Modul

Dieses zentrale Modul würde die MCP-Funktionalität in OpenHands koordinieren:

```python
# Beispiel für ein mcp_manager.py Modul

class MCPManager:
    def __init__(self, config):
        self.config = config
        self.client_manager = MCPClientManager()
        self.registry = MCPRegistry()
        self.load_configuration()
    
    def load_configuration(self):
        # Lädt MCP-Server-Konfigurationen aus config
        pass
    
    def initialize_servers(self):
        # Initialisiert die konfigurierten MCP-Server
        pass
    
    async def list_available_tools(self):
        # Fragt alle verbundenen Server nach ihren Tools
        pass
    
    async def call_tool(self, tool_name, args):
        # Ruft ein bestimmtes Tool auf dem entsprechenden Server auf
        pass
```

### 2.2 MCP-Client-Manager

Verwaltet die Verbindungen zu MCP-Servern:

```python
class MCPClientManager:
    def __init__(self):
        self.clients = {}  # server_id -> client
    
    async def create_client(self, server_config):
        # Erstellt einen Client basierend auf Transport-Typ (stdio, sse, etc.)
        if server_config.transport_type == "stdio":
            return await self.create_stdio_client(server_config)
        elif server_config.transport_type == "sse":
            return await self.create_sse_client(server_config)
        else:
            raise ValueError(f"Unsupported transport type: {server_config.transport_type}")
    
    async def create_stdio_client(self, server_config):
        # Implementierung eines stdio-basierten MCP-Clients
        pass
    
    async def create_sse_client(self, server_config):
        # Implementierung eines SSE-basierten MCP-Clients
        pass
```

### 2.3 MCP-Registry

Verwaltet die verfügbaren MCP-Server und deren Tools:

```python
class MCPRegistry:
    def __init__(self):
        self.servers = {}  # server_id -> server_info
        self.tools = {}    # tool_name -> (server_id, tool_info)
    
    def register_server(self, server_id, server_info):
        self.servers[server_id] = server_info
    
    def register_tools(self, server_id, tools):
        for tool in tools:
            self.tools[tool.name] = (server_id, tool)
    
    def get_tool_server(self, tool_name):
        if tool_name in self.tools:
            return self.tools[tool_name][0]
        return None
```

## 3. Integration in OpenHands-Workflow

### 3.1 Erweiterung der Konfigurationsdatei

Ähnlich wie bei Claude Desktop würden Sie eine Konfigurationsoption für MCP-Server hinzufügen:

```json
{
  "mcp": {
    "enabled": true,
    "servers": {
      "github-mcp": {
        "transport_type": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-github"],
        "env": {
          "GITHUB_TOKEN": "${GITHUB_TOKEN}"
        }
      },
      "filesystem-mcp": {
        "transport_type": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "${WORKSPACE_DIR}"]
      },
      "custom-n8n-mcp": {
        "transport_type": "sse",
        "url": "http://localhost:5678/mcp/endpoint",
        "auth": {
          "type": "bearer",
          "token": "${N8N_API_TOKEN}"
        }
      }
    }
  }
}
```

### 3.2 Integration in die Agent-Klasse

OpenHands nutzt LLM-Agenten für Aufgaben. Sie müssten die Agent-Klasse erweitern, um MCP-Tools zu unterstützen:

```python
class Agent:
    def __init__(self, config, mcp_manager=None):
        self.config = config
        self.mcp_manager = mcp_manager
        # ... Existierender Code ...
    
    async def prepare_tools_for_llm(self):
        tools = []
        # Bestehende Tools hinzufügen
        tools.extend(self.get_standard_tools())
        
        # MCP-Tools hinzufügen, falls MCP-Manager aktiviert ist
        if self.mcp_manager:
            mcp_tools = await self.mcp_manager.list_available_tools()
            tools.extend(self.adapt_mcp_tools_for_llm(mcp_tools))
        
        return tools
    
    def adapt_mcp_tools_for_llm(self, mcp_tools):
        # Konvertiert MCP-Tool-Beschreibungen in das Format, das vom LLM erwartet wird
        adapted_tools = []
        for tool in mcp_tools:
            adapted_tools.append({
                "name": tool.name,
                "description": tool.description,
                "parameters": tool.parameter_schema,
                "function": lambda params, tool=tool: self.call_mcp_tool(tool.name, params)
            })
        return adapted_tools
    
    async def call_mcp_tool(self, tool_name, params):
        # Ruft ein MCP-Tool auf und handhabt die Antwort
        return await self.mcp_manager.call_tool(tool_name, params)
```

### 3.3 Benutzeroberfläche Erweiterung

Fügen Sie eine UI-Komponente zur Verwaltung von MCP-Servern hinzu:

```tsx
// Beispiel für eine React-Komponente (vereinfacht)
const MCPServerConfig = () => {
  const [servers, setServers] = useState([]);
  const [activeServers, setActiveServers] = useState([]);
  
  useEffect(() => {
    // Lädt die MCP-Server-Konfiguration
    fetchMCPConfiguration().then(config => {
      setServers(config.servers || []);
    });
    
    // Lädt die aktuell aktiven MCP-Server
    fetchActiveMCPServers().then(activeServers => {
      setActiveServers(activeServers);
    });
  }, []);
  
  return (
    <div className="mcp-config-panel">
      <h2>MCP Server Configuration</h2>
      
      <div className="server-list">
        {servers.map(server => (
          <ServerConfigItem 
            key={server.id}
            server={server}
            active={activeServers.includes(server.id)}
            onToggle={() => toggleServer(server.id)}
            onEdit={() => editServer(server.id)}
          />
        ))}
      </div>
      
      <button onClick={addNewServer}>Add MCP Server</button>
    </div>
  );
};
```

## 4. Implementierung der MCP-Client-Bibliothek

Sie benötigen eine Implementierung des MCP-Protokolls. Sie könnten entweder:

1. Eine bestehende MCP-Client-Bibliothek einbinden:
   ```bash
   npm install @modelcontextprotocol/client
   # oder
   pip install mcp-client
   ```

2. Eine eigene minimale Implementierung erstellen, die sich auf die benötigten Funktionen konzentriert:

```python
# Beispiel einer einfachen MCP-Client-Implementierung
import asyncio
import json
import subprocess

class StdioMCPClient:
    def __init__(self, command, args=None, env=None):
        self.command = command
        self.args = args or []
        self.env = env or {}
        self.process = None
        self.request_id = 0
        
    async def start(self):
        self.process = await asyncio.create_subprocess_exec(
            self.command, *self.args,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=self.env
        )
        
    async def send_request(self, method, params=None):
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
        
    async def list_tools(self):
        return await self.send_request("mcp.listTools")
        
    async def call_tool(self, tool_name, arguments):
        return await self.send_request("mcp.callTool", {
            "name": tool_name,
            "arguments": arguments
        })
        
    async def stop(self):
        if self.process:
            self.process.terminate()
            await self.process.wait()
```

## 5. Integration mit n8n über MCP

Um speziell die Integration mit n8n über MCP zu ermöglichen:

```python
class N8nMCPIntegration:
    def __init__(self, config):
        self.config = config
        self.mcp_client = None
        
    async def initialize(self):
        # Initialisiere den MCP-Client für n8n
        server_config = self.config.get("n8n_mcp_server", {})
        transport_type = server_config.get("transport_type", "sse")
        
        if transport_type == "sse":
            self.mcp_client = await create_sse_client(
                server_config.get("url"),
                server_config.get("auth", {})
            )
        else:
            raise ValueError(f"Unsupported transport for n8n: {transport_type}")
            
        # Initialisiere die Verbindung
        await self.mcp_client.start()
        
    async def get_workflow_tools(self):
        # Erhalte alle n8n-Workflow-bezogenen Tools
        tools = await self.mcp_client.list_tools()
        return [tool for tool in tools if tool.name.startswith("workflow_")]
        
    async def create_workflow(self, workflow_data):
        # Erstelle einen n8n-Workflow über MCP
        return await self.mcp_client.call_tool(
            "workflow_create", 
            {"workflow_data": workflow_data}
        )
        
    async def execute_workflow(self, workflow_id, input_data=None):
        # Führe einen n8n-Workflow aus
        return await self.mcp_client.call_tool(
            "workflow_execute",
            {
                "workflow_id": workflow_id,
                "input_data": input_data or {}
            }
        )
```

## 6. Implementierungsschritte

1. **Phase 1: Grundlegende MCP-Infrastruktur**
   - Implementieren Sie das MCP-Manager-Modul
   - Fügen Sie Unterstützung für stdio-basierte Server hinzu
   - Integrieren Sie die Konfigurationsverwaltung

2. **Phase 2: Agent-Integration**
   - Erweitern Sie die Agent-Klasse für MCP-Tools
   - Implementieren Sie Tool-Aufrufe und -Antworten
   - Fügen Sie Tool-Beschreibungskonvertierung hinzu

3. **Phase 3: UI-Integration**
   - Fügen Sie MCP-Server-Konfigurationsschnittstelle hinzu
   - Implementieren Sie Serverstatusanzeige
   - Fügen Sie Tool-Verwendungsstatistiken hinzu

4. **Phase 4: n8n-spezifische Integration**
   - Implementieren Sie den n8n-MCP-Server-Connector
   - Fügen Sie Workflow-Verwaltungsfunktionen hinzu
   - Testen Sie Workflow-Erstellung und -Ausführung

5. **Phase 5: Erweiterungen und Verbesserungen**
   - Unterstützung für weitere Transporte (z.B. WebSocket)
   - Caching von Tool-Metadaten
   - Verbessertes Fehlerhandling

## 7. Sicherheitsüberlegungen

- Implementieren Sie ein Berechtigungssystem für MCP-Tool-Aufrufe
- Validieren Sie alle Eingaben und Ausgaben
- Behandeln Sie Anmeldeinformationen sicher
- Protokollieren Sie MCP-Aufrufe für Auditzwecke
- Beschränken Sie Werkzeuge basierend auf Benutzerberechtigungen

Diese Architektur bietet einen modularen Ansatz zur Integration von MCP in OpenHands, der sowohl flexibel als auch erweiterbar ist. Sie könnten schrittweise mit grundlegenden Funktionen beginnen und diese später erweitern.
