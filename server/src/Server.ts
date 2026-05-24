import WebSocket, { WebSocketServer } from "ws";
import { Client } from "./Client";
import { Room } from "./Room";
import { Logger } from "./logger";
import { ServerConfig, loadConfig } from "./config";
import { MessageType, MPacket, VehicleState, ChatData } from "./protocol";

export class Server {
  private wss!: WebSocketServer;
  private clients: Map<string, Client> = new Map();
  private room: Room;
  private logger: Logger;
  private config: ServerConfig;
  private tickInterval: NodeJS.Timeout | null = null;

  constructor(config?: Partial<ServerConfig>) {
    this.config = { ...loadConfig(), ...config };
    this.logger = new Logger("Server", this.config.logLevel);
    this.room = new Room("main", this.config.name, this.config);
  }

  start(): void {
    this.wss = new WebSocketServer({
      port: this.config.port,
      host: this.config.host,
    });

    this.wss.on("connection", (ws: WebSocket) => {
      const client = new Client(ws, this.logger);
      this.clients.set(client.id, client);

      ws.on("message", (data: WebSocket.Data) => {
        this.handleMessage(client, data);
      });

      ws.on("close", () => {
        this.handleDisconnect(client);
      });

      ws.on("pong", () => {
        client.onPing();
      });

      client.onOpen();
    });

    this.startTickLoop();

    this.logger.info(`Server started on ${this.config.host}:${this.config.port}`);
    this.logger.info(`Server name: ${this.config.name}`);
    this.logger.info(`Max players: ${this.config.maxPlayers}`);
  }

  stop(): void {
    if (this.tickInterval) {
      clearInterval(this.tickInterval);
    }

    for (const client of this.clients.values()) {
      client.ws.close(1001, "Server shutting down");
    }

    this.wss.close();
    this.logger.info("Server stopped");
  }

  private handleMessage(client: Client, data: WebSocket.Data): void {
    try {
      const raw = data.toString();
      const packet: MPacket = JSON.parse(raw);

      switch (packet.type) {
        case MessageType.HELLO:
          client.send(MessageType.HELLO_RESPONSE, {
            serverVersion: "1.0.0",
            protocolVersion: 1,
            serverName: this.config.name,
          });
          break;

        case MessageType.AUTH:
          this.handleAuth(client, packet);
          break;

        case MessageType.VEHICLE_UPDATE:
          this.room.handleVehicleUpdate(client.id, packet.data as VehicleState);
          break;

        case MessageType.VEHICLE_SPAWN:
          this.room.handleVehicleSpawn(client.id, packet.data);
          break;

        case MessageType.VEHICLE_DESPAWN:
          this.room.handleVehicleDespawn(client.id, packet.data?.vehicleId);
          break;

        case MessageType.CHAT_MESSAGE:
          this.room.handleChat(client.id, packet.data?.message || "");
          break;

        case MessageType.VEHICLE_DAMAGE:
          this.room.handleVehicleDamage(client.id, packet.data);
          break;

        case MessageType.VEHICLE_INPUT:
          this.room.broadcast(MessageType.VEHICLE_INPUT, packet.data, client.id);
          break;

        case MessageType.VEHICLE_ELECTRICS:
          this.room.broadcast(MessageType.VEHICLE_ELECTRICS, packet.data, client.id);
          break;

        case MessageType.VEHICLE_NODES:
          if (this.config.enableNodeSync) {
            this.room.broadcast(MessageType.VEHICLE_NODES, packet.data, client.id);
          }
          break;

        default:
          this.logger.debug(`Unknown packet type: ${packet.type}`);
      }
    } catch (err) {
      this.logger.error(`Error handling message from ${client.id}:`, err);
    }
  }

  private handleAuth(client: Client, packet: MPacket): void {
    const { username } = packet.data || {};
    if (this.room.getClientCount() >= this.config.maxPlayers) {
      client.send(MessageType.AUTH_RESPONSE, {
        success: false,
        reason: "Server is full",
      });
      client.ws.close(4001, "Server is full");
      return;
    }

    if (this.config.password && packet.data?.password !== this.config.password) {
      client.send(MessageType.AUTH_RESPONSE, {
        success: false,
        reason: "Wrong password",
      });
      return;
    }

    if (username) {
      client.name = username.slice(0, 24);
    }
    client.authenticated = true;

    client.send(MessageType.AUTH_RESPONSE, {
      success: true,
      playerId: client.id,
      role: client.role,
    });

    this.room.addClient(client);
  }

  private handleDisconnect(client: Client): void {
    this.room.removeClient(client.id);
    this.clients.delete(client.id);
  }

  private startTickLoop(): void {
    const tickMs = 1000 / this.config.tickRate;
    this.tickInterval = setInterval(() => {
      this.tick();
    }, tickMs);
  }

  private tick(): void {
    const now = Date.now();

    for (const client of this.clients.values()) {
      if (client.authenticated) {
        try {
          client.ws.ping();
        } catch {
          this.handleDisconnect(client);
        }
      }
    }
  }

  getStats(): object {
    return {
      uptime: process.uptime(),
      players: this.room.getClientCount(),
      maxPlayers: this.config.maxPlayers,
      vehicles: this.room.vehicles.size,
      map: this.room.map,
      serverName: this.config.name,
      playersList: this.room.getPlayerList(),
    };
  }
}
