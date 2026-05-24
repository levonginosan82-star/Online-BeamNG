import WebSocket from "ws";
import { v4 as uuidv4 } from "uuid";
import { PlayerInfo, VehicleState, ChatData, MPacket, MessageType } from "./protocol";
import { Logger } from "./logger";

export class Client {
  public id: string;
  public name: string;
  public role: string = "user";
  public ping: number = 0;
  public authenticated: boolean = false;
  public inGame: boolean = false;
  public vehicles: Map<string, VehicleState> = new Map();
  public joinTime: number = Date.now();
  private lastPingTime: number = 0;
  private alive: boolean = true;

  constructor(
    public ws: WebSocket,
    private logger: Logger
  ) {
    this.id = uuidv4();
    this.name = `Player_${this.id.slice(0, 4)}`;
  }

  onOpen(): void {
    this.logger.info(`Client ${this.id} connected`);
  }

  onMessage(data: WebSocket.Data): void {
    try {
      const raw = data.toString();
      const packet: MPacket = JSON.parse(raw);

      if (packet.type === MessageType.HELLO) {
        this.handleHello(packet);
        return;
      }

      if (packet.type === MessageType.AUTH) {
        this.handleAuth(packet);
        return;
      }
    } catch (err) {
      this.logger.error(`Failed to parse message from ${this.id}:`, err);
    }
  }

  onClose(): void {
    this.logger.info(`Client ${this.id} (${this.name}) disconnected`);
    this.alive = false;
  }

  onPing(): void {
    this.lastPingTime = Date.now();
  }

  send(type: MessageType, data: any): void {
    if (this.ws.readyState !== WebSocket.OPEN) return;
    const packet: MPacket = {
      type,
      data,
      sender: this.id,
      timestamp: Date.now(),
    };
    this.ws.send(JSON.stringify(packet));
  }

  sendRaw(data: string): void {
    if (this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(data);
    }
  }

  kick(reason: string = "Kicked"): void {
    this.send(MessageType.KICK, { reason });
    this.ws.close(4000, reason);
  }

  private handleHello(packet: MPacket): void {
    this.send(MessageType.HELLO_RESPONSE, {
      serverVersion: "1.0.0",
      protocolVersion: 1,
      serverName: "BeamNG Online Server",
    });
  }

  private handleAuth(packet: MPacket): void {
    const { username, authKey } = packet.data || {};
    if (username) {
      this.name = username.slice(0, 24);
    }
    this.authenticated = true;
    this.send(MessageType.AUTH_RESPONSE, {
      success: true,
      playerId: this.id,
      role: this.role,
    });
  }

  isAdmin(): boolean {
    return this.role === "admin";
  }

  updatePing(): number {
    this.ping = Date.now() - this.lastPingTime;
    return this.ping;
  }

  toInfo(): PlayerInfo {
    return {
      id: this.id,
      name: this.name,
      role: this.role,
      ping: this.ping,
    };
  }
}
