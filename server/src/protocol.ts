export enum MessageType {
  // Handshake
  HELLO = "Hello",
  HELLO_RESPONSE = "HelloResponse",
  AUTH = "Auth",
  AUTH_RESPONSE = "AuthResponse",
  ADMIN_AUTH = "AdminAuth",
  ADMIN_AUTH_RESPONSE = "AdminAuthResponse",

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

  // Chat & Commands
  CHAT_MESSAGE = "ChatMessage",
  CHAT_COMMAND = "ChatCommand",
  SYSTEM_MESSAGE = "SystemMessage",

  // Damage/Physics
  VEHICLE_DAMAGE = "VehicleDamage",
  VEHICLE_NODES = "VehicleNodes",

  // Server management
  KICK = "Kick",
  BAN = "Ban",
  BAN_LIST = "BanList",
  MOD_LIST = "ModList",

  // Time/Weather sync
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

export interface ChatCommand {
  command: string;
  args: string[];
  sender: string;
  senderId: string;
}

export interface BanEntry {
  id: string;
  ip: string;
  bannedBy: string;
  banReason: string;
  banTime: number;
  expires?: number;
}

export interface WeatherData {
  weather: "clear" | "rain" | "fog" | "storm" | "clouds";
  time: number; // 0-24 hours
  timeScale: number;
  fogDensity: number;
  rain: number;
  wind: number;
}

export interface TimeData {
  time: number; // 0-24 hours
  timeScale: number;
}
