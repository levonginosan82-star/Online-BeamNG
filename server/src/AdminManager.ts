import { Client } from "./Client";
import { BanEntry, WeatherData, TimeData, ChatCommand, MessageType } from "./protocol";
import { Logger } from "./logger";
import fs from "fs";
import path from "path";

export class AdminManager {
  private admins: Set<string> = new Set();
  private banList: Map<string, BanEntry> = new Map();
  private adminPassword: string;
  private weather: WeatherData = {
    weather: "clear",
    time: 12.0,
    timeScale: 1.0,
    fogDensity: 0.0,
    rain: 0.0,
    wind: 0.0,
  };
  private time: TimeData = {
    time: 12.0,
    timeScale: 1.0,
  };
  private logger: Logger;
  private dataDir: string;
  private broadcastSystemMessage: (message: string) => void = () => {};

  constructor(logger: Logger, dataDir: string, adminPassword: string) {
    this.logger = logger;
    this.dataDir = dataDir;
    this.adminPassword = adminPassword;
    this.ensureDataDir();
    this.loadBanList();
  }

  private ensureDataDir(): void {
    try {
      if (!fs.existsSync(this.dataDir)) {
        fs.mkdirSync(this.dataDir, { recursive: true });
      }
    } catch (err) {
      this.logger.error("Failed to create data directory:", err);
    }
  }

  setBroadcastCallback(callback: (message: string) => void): void {
    this.broadcastSystemMessage = callback;
  }

  authenticateAdmin(client: Client, password: string): boolean {
    if (!this.adminPassword) {
      this.logger.warn(`Admin login rejected - no admin password set`);
      return false;
    }
    if (password === this.adminPassword) {
      client.role = "admin";
      this.admins.add(client.id);
      this.logger.info(`Admin login: ${client.name} (${client.id})`);
      return true;
    }
    this.logger.warn(`Failed admin login attempt: ${client.name} (${client.id})`);
    return false;
  }

  parseCommand(message: string, sender: string, senderId: string): ChatCommand | null {
    if (message.startsWith("/")) {
      const parts = message.substring(1).split(/\s+/);
      const command = parts[0].toLowerCase();
      const args = parts.slice(1);
      return { command, args, sender, senderId };
    }
    return null;
  }

  executeCommand(command: ChatCommand, serverClients: Map<string, Client>): boolean {
    const { command: cmd, args, sender, senderId } = command;
    const senderClient = serverClients.get(senderId);
    
    if (!senderClient || !senderClient.isAdmin()) {
      return false;
    }

    this.logger.info(`Admin command: ${cmd} ${args.join(" ")} by ${sender}`);

    switch (cmd) {
      case "kick":
        this.handleKick(args, serverClients);
        break;
      case "ban":
        this.handleBan(args, serverClients, sender);
        break;
      case "unban":
        this.handleUnban(args);
        break;
      case "list":
        this.handleList(args, serverClients);
        break;
      case "time":
        this.handleTime(args);
        break;
      case "weather":
        this.handleWeather(args);
        break;
      case "admins":
        this.handleAdmins(serverClients);
        break;
      case "help":
        this.handleHelp(senderClient);
        break;
      default:
        senderClient.send(MessageType.SYSTEM_MESSAGE, { 
          message: `Unknown command: ${cmd}. Use /help for available commands.`,
          type: "system"
        });
        return false;
    }

    return true;
  }

  private handleKick(args: string[], serverClients: Map<string, Client>): void {
    if (args.length === 0) {
      this.broadcastSystemMessage("Usage: /kick <playerName> [reason]");
      return;
    }

    const targetName = args[0];
    const reason = args.slice(1).join(" ") || "Kicked by admin";
    
    let targetClient: Client | null = null;
    for (const client of serverClients.values()) {
      if (client.name === targetName) {
        targetClient = client;
        break;
      }
    }

    if (targetClient) {
      targetClient.kick(reason);
      this.broadcastSystemMessage(`${targetName} was kicked: ${reason}`);
    } else {
      this.broadcastSystemMessage(`Player "${targetName}" not found`);
    }
  }

  private handleBan(args: string[], serverClients: Map<string, Client>, sender?: string): void {
    if (args.length === 0) {
      this.broadcastSystemMessage("Usage: /ban <playerName> [reason]");
      return;
    }

    const targetName = args[0];
    const reason = args.slice(1).join(" ") || "Banned by admin";
    
    let targetClient: Client | null = null;
    for (const client of serverClients.values()) {
      if (client.name === targetName) {
        targetClient = client;
        break;
      }
    }

    if (targetClient) {
      const banEntry: BanEntry = {
        id: targetClient.id,
        ip: targetClient.ip || "0.0.0.0",
        bannedBy: sender || "unknown",
        banReason: reason,
        banTime: Date.now(),
        expires: undefined,
      };

      this.banList.set(targetClient.id, banEntry);
      this.saveBanList();
      targetClient.kick(`Banned: ${reason}`);
      this.broadcastSystemMessage(`${targetName} was banned by ${sender || "admin"}: ${reason}`);
    } else {
      this.broadcastSystemMessage(`Player "${targetName}" not found`);
    }
  }

  private handleUnban(args: string[]): void {
    if (args.length === 0) {
      this.broadcastSystemMessage("Usage: /unban <playerId>");
      return;
    }

    const targetId = args[0];
    const banned = this.banList.get(targetId);
    
    if (banned) {
      this.banList.delete(targetId);
      this.saveBanList();
      this.broadcastSystemMessage(`Player ${targetId} was unbanned`);
    } else {
      this.broadcastSystemMessage(`No ban found for player ${targetId}`);
    }
  }

  private handleList(args: string[], serverClients: Map<string, Client>): void {
    const listType = args[0] || "players";
    
    if (listType === "players") {
      let playerList = "Online players:\n";
      for (const client of serverClients.values()) {
        const status = client.isAdmin() ? "[ADMIN]" : "[USER]";
        playerList += `  ${client.name} (${client.id}) ${status}\n`;
      }
      this.broadcastSystemMessage(playerList);
    } else if (listType === "bans") {
      let banList = "Banned players:\n";
      for (const ban of this.banList.values()) {
        banList += `  ${ban.id}: ${ban.banReason} (by ${ban.bannedBy})\n`;
      }
      this.broadcastSystemMessage(banList);
    } else {
      this.broadcastSystemMessage("Usage: /list [players|bans]");
    }
  }

  private handleTime(args: string[]): void {
    if (args.length === 0) {
      this.broadcastSystemMessage(`Current time: ${this.time.time.toFixed(1)}h (scale: ${this.time.timeScale}x)`);
      return;
    }

    const timeArg = args[0];
    if (timeArg === "set" && args[1]) {
      const newTime = parseFloat(args[1]);
      if (!isNaN(newTime) && newTime >= 0 && newTime <= 24) {
        this.time.time = newTime;
        this.broadcastSystemMessage(`Time set to ${newTime.toFixed(1)}h`);
      } else {
        this.broadcastSystemMessage("Invalid time. Use 0-24 format (e.g., 14.5 for 2:30 PM)");
      }
    } else if (timeArg === "scale" && args[1]) {
      const newScale = parseFloat(args[1]);
      if (!isNaN(newScale) && newScale >= 0) {
        this.time.timeScale = newScale;
        this.broadcastSystemMessage(`Time scale set to ${newScale}x`);
      } else {
        this.broadcastSystemMessage("Invalid time scale");
      }
    } else {
      this.broadcastSystemMessage("Usage: /time set <0-24> | /time scale <scale>");
    }
  }

  private handleWeather(args: string[]): void {
    if (args.length === 0) {
      this.broadcastSystemMessage(`Current weather: ${this.weather.weather}`);
      return;
    }

    const weatherArg = args[0].toLowerCase();
    const validWeathers = ["clear", "rain", "fog", "storm", "clouds"];
    
    if (validWeathers.includes(weatherArg)) {
      this.weather.weather = weatherArg as any;
      this.broadcastSystemMessage(`Weather set to ${weatherArg}`);
    } else {
      this.broadcastSystemMessage(`Available weather: ${validWeathers.join(", ")}`);
    }
  }

  private handleAdmins(serverClients: Map<string, Client>): void {
    let adminList = "Online admins:\n";
    for (const client of serverClients.values()) {
      if (client.isAdmin()) {
        adminList += `  ${client.name}\n`;
      }
    }
    this.broadcastSystemMessage(adminList);
  }

  private handleHelp(adminClient: Client): void {
    const helpText = [
      "Available admin commands:",
      "/kick <player> [reason] - Kick a player",
      "/ban <player> [reason] - Ban a player",
      "/unban <playerId> - Unban a player",
      "/list [players|bans] - List players or bans",
      "/time set <0-24> - Set game time",
      "/time scale <scale> - Set time scale",
      "/weather <type> - Set weather (clear, rain, fog, storm, clouds)",
      "/admins - List online admins",
      "/help - Show this help"
    ].join("\n");
    
    adminClient.send(MessageType.SYSTEM_MESSAGE, { 
      message: helpText,
      type: "system"
    });
  }

  checkBan(clientId: string, clientIp: string): BanEntry | null {
    const ban = this.banList.get(clientId);
    if (ban) {
      // Check if ban has expired
      if (ban.expires && ban.expires < Date.now()) {
        this.banList.delete(clientId);
        this.saveBanList();
        return null;
      }
      return ban;
    }
    return null;
  }

  getWeather(): WeatherData {
    return { ...this.weather };
  }

  getTime(): TimeData {
    return { ...this.time };
  }

  private loadBanList(): void {
    try {
      const banFile = path.join(this.dataDir, "bans.json");
      if (fs.existsSync(banFile)) {
        const data = fs.readFileSync(banFile, "utf8");
        const bans = JSON.parse(data);
        this.banList = new Map(Object.entries(bans));
        this.logger.info(`Loaded ${this.banList.size} bans`);
      }
    } catch (err) {
      this.logger.error("Failed to load ban list:", err);
    }
  }

  private saveBanList(): void {
    try {
      const banFile = path.join(this.dataDir, "bans.json");
      const data = Object.fromEntries(this.banList);
      fs.writeFileSync(banFile, JSON.stringify(data, null, 2));
    } catch (err) {
      this.logger.error("Failed to save ban list:", err);
    }
  }

  private loadAdmins(): void {
    // TODO: Load admin list from config file
    // For now, we'll use a hardcoded admin password
  }
}