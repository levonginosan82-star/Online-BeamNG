import { Client } from "./Client";
import { VehicleState, MessageType, ChatData, PlayerInfo } from "./protocol";
import { Logger } from "./logger";
import { ServerConfig } from "./config";

export class Room {
  public clients: Map<string, Client> = new Map();
  public vehicles: Map<string, { clientId: string; state: VehicleState }> = new Map();
  public map: string;
  private logger: Logger;

  constructor(
    public id: string,
    public name: string,
    private config: ServerConfig
  ) {
    this.map = config.map;
    this.logger = new Logger(`Room:${id}`, config.logLevel);
  }

  addClient(client: Client): void {
    this.clients.set(client.id, client);
    if (this.clients.size === 1 && client.role === "user") {
      client.role = "admin";
    }

    this.broadcast(MessageType.PLAYER_JOIN, client.toInfo(), client.id);

    const playerList: PlayerInfo[] = [];
    for (const c of this.clients.values()) {
      playerList.push(c.toInfo());
    }
    client.send(MessageType.PLAYER_LIST, { players: playerList });

    this.logger.info(`${client.name} joined the room`);
  }

  removeClient(clientId: string): void {
    const client = this.clients.get(clientId);
    if (!client) return;

    for (const [vid, entry] of this.vehicles) {
      if (entry.clientId === clientId) {
        this.vehicles.delete(vid);
        this.broadcast(MessageType.VEHICLE_DESPAWN, { vehicleId: vid }, clientId);
      }
    }

    this.clients.delete(clientId);
    this.broadcast(MessageType.PLAYER_LEAVE, { playerId: clientId, name: client.name }, clientId);
    this.logger.info(`${client.name} left the room`);
  }

  handleVehicleUpdate(clientId: string, state: VehicleState): void {
    this.vehicles.set(state.id, { clientId, state });
    this.broadcast(MessageType.VEHICLE_UPDATE, state, clientId);
  }

  handleVehicleSpawn(clientId: string, data: any): void {
    const vehicleId = data.id || `v_${clientId}_${Date.now()}`;
    const state: VehicleState = {
      id: vehicleId,
      position: data.position || { x: 0, y: 0, z: 0 },
      rotation: data.rotation || { x: 0, y: 0, z: 0, w: 1 },
      velocity: { x: 0, y: 0, z: 0 },
      angularVelocity: { x: 0, y: 0, z: 0 },
      engineRunning: false,
      speed: 0,
      gear: 0,
      rpm: 0,
      steering: 0,
      throttle: 0,
      braking: 0,
      clutch: 0,
    };

    this.vehicles.set(vehicleId, { clientId, state });
    this.broadcast(MessageType.VEHICLE_SPAWN, {
      vehicleId,
      ownerId: clientId,
      ...data,
    });
  }

  handleVehicleDespawn(clientId: string, vehicleId: string): void {
    this.vehicles.delete(vehicleId);
    this.broadcast(MessageType.VEHICLE_DESPAWN, { vehicleId }, clientId);
  }

  handleChat(clientId: string, message: string): void {
    const client = this.clients.get(clientId);
    if (!client) return;

    const chatData: ChatData = {
      sender: client.name,
      senderId: clientId,
      message: message.slice(0, 256),
      type: "global",
    };

    this.broadcast(MessageType.CHAT_MESSAGE, chatData);
  }

  handleVehicleDamage(clientId: string, data: any): void {
    if (!this.config.enableDamageSync) return;
    this.broadcast(MessageType.VEHICLE_DAMAGE, data, clientId);
  }

  broadcast(type: MessageType, data: any, excludeId?: string): void {
    for (const [id, client] of this.clients) {
      if (id !== excludeId) {
        client.send(type, data);
      }
    }
  }

  getClientCount(): number {
    return this.clients.size;
  }

  getPlayerList(): PlayerInfo[] {
    const list: PlayerInfo[] = [];
    for (const client of this.clients.values()) {
      list.push(client.toInfo());
    }
    return list;
  }
}
