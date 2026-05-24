export interface ServerConfig {
  port: number;
  host: string;
  maxPlayers: number;
  name: string;
  description: string;
  password: string;
  authKey: string;
  map: string;
  maxVehicles: number;
  tickRate: number;
  logLevel: "debug" | "info" | "warn" | "error";
  enableDamageSync: boolean;
  enableNodeSync: boolean;
  enableModCheck: boolean;
  private: boolean;
}

export const defaultConfig: ServerConfig = {
  port: 30814,
  host: "0.0.0.0",
  maxPlayers: 16,
  name: "BeamNG Online Server",
  description: "A BeamNG.drive multiplayer server",
  password: "",
  authKey: "",
  map: "gridmap",
  maxVehicles: 4,
  tickRate: 20,
  logLevel: "info",
  enableDamageSync: true,
  enableNodeSync: false,
  enableModCheck: true,
  private: false,
};

export function loadConfig(path?: string): ServerConfig {
  const config = { ...defaultConfig };
  const envMap: Record<string, keyof ServerConfig> = {
    BEMP_PORT: "port",
    BEMP_HOST: "host",
    BEMP_MAX_PLAYERS: "maxPlayers",
    BEMP_SERVER_NAME: "name",
    BEMP_DESCRIPTION: "description",
    BEMP_PASSWORD: "password",
    BEMP_AUTH_KEY: "authKey",
    BEMP_MAP: "map",
    BEMP_MAX_VEHICLES: "maxVehicles",
    BEMP_TICK_RATE: "tickRate",
    BEMP_LOG_LEVEL: "logLevel",
  };

  for (const [env, key] of Object.entries(envMap)) {
    const val = process.env[env];
    if (val !== undefined) {
      const current = config[key];
      if (typeof current === "number") {
        (config as any)[key] = parseInt(val, 10);
      } else {
        (config as any)[key] = val;
      }
    }
  }

  return config;
}
