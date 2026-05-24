export enum MessageType {
  // Handshake
  HELLO = "Hello",
  HELLO_RESPONSE = "HelloResponse",
  AUTH = "Auth",
  AUTH_RESPONSE = "AuthResponse",

  // Player management
  PLAYER_JOIN = "PlayerJoin",
  PLAYER_LEAVE = "PlayerLeave",
  PLAYER_LIST = "PlayerList",

  // Vehicle state
  VEHICLE_UPDATE = "VehicleUpdate",
  VEHICLE_SPAWN = "VehicleSpawn",
  VEHICLE_DESPAWN = "VehicleDespawn",
  VEHICLE_INPUT = "VehicleInput",
  VEHICLE_ELECTRICS = "VehicleElectrics",

  // Chat
  CHAT_MESSAGE = "ChatMessage",

  // Damage/Physics
  VEHICLE_DAMAGE = "VehicleDamage",
  VEHICLE_NODES = "VehicleNodes",

  // Server management
  KICK = "Kick",
  BAN = "Ban",
  MOD_LIST = "ModList",

  // Time/Weather sync (future)
  TIME_SYNC = "TimeSync",
  WEATHER_SYNC = "WeatherSync",
}

export interface MPacket {
  type: MessageType;
  data: any;
  sender?: string;
  timestamp?: number;
}

export interface Position {
  x: number;
  y: number;
  z: number;
}

export interface Rotation {
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface VehicleState {
  id: string;
  position: Position;
  rotation: Rotation;
  velocity: Position;
  angularVelocity: Position;
  engineRunning: boolean;
  speed: number;
  gear: number;
  rpm: number;
  steering: number;
  throttle: number;
  braking: number;
  clutch: number;
}

export interface PlayerInfo {
  id: string;
  name: string;
  role: string;
  ping: number;
}

export interface ChatData {
  sender: string;
  senderId: string;
  message: string;
  type: "global" | "local" | "team";
}
