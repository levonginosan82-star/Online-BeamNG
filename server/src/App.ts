import express, { Express, Request, Response } from "express";
import cors from "cors";
import path from "path";
import fs from "fs";
import http from "http";
import { Server as GameServer } from "./Server";
import { ServerConfig, defaultConfig } from "./config";
import { Logger } from "./logger";

export class App {
  private app: Express;
  private httpServer!: http.Server;
  private gameServer: GameServer | null = null;
  private logger: Logger;
  private config: ServerConfig;
  private logHistory: string[] = [];
  private adminPort: number;
  private logCapture: ((msg: string) => void) | null = null;

  constructor() {
    this.config = { ...defaultConfig };
    this.adminPort = parseInt(process.env.ADMIN_PORT || "30815", 10);
    this.logger = new Logger("Admin", this.config.logLevel);
    this.interceptLogs();

    this.app = express();
    this.app.use(cors());
    this.app.use(express.json());

    this.app.use("/api", this.createApiRouter());

    const distWeb = path.join(__dirname, "web");
    const srcWeb = path.join(__dirname, "..", "src", "web");
    const webPath = fs.existsSync(distWeb) ? distWeb : srcWeb;

    console.log(`[App] Serving web from: ${webPath}`);
    this.app.use(express.static(webPath));

    this.app.use((_req: Request, res: Response) => {
      const indexPath = path.join(webPath, "index.html");
      if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
      } else {
        res.status(200).json({ api: "Online BeamNG Admin API", docs: "/api/status" });
      }
    });
  }

  private interceptLogs(): void {
    const self = this;
    const originalConsoleLog = console.log;
    const originalConsoleError = console.error;
    const originalConsoleWarn = console.warn;

    console.log = function (...args: any[]) {
      const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a) : String(a))).join(" ");
      self.addLog("info", msg);
      originalConsoleLog.apply(console, args);
    };

    console.error = function (...args: any[]) {
      const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a) : String(a))).join(" ");
      self.addLog("error", msg);
      originalConsoleError.apply(console, args);
    };

    console.warn = function (...args: any[]) {
      const msg = args.map((a) => (typeof a === "object" ? JSON.stringify(a) : String(a))).join(" ");
      self.addLog("warn", msg);
      originalConsoleWarn.apply(console, args);
    };
  }

  private addLog(level: string, message: string): void {
    const timestamp = new Date().toISOString();
    this.logHistory.push(JSON.stringify({ timestamp, level, message }));
    if (this.logHistory.length > 1000) {
      this.logHistory.splice(0, this.logHistory.length - 1000);
    }
  }

  private createApiRouter(): express.Router {
    const router = express.Router();

    router.get("/status", (_req: Request, res: Response) => {
      res.json({
        running: this.gameServer !== null,
        players: this.gameServer ? (this.gameServer as any).getStats().players : 0,
        maxPlayers: this.config.maxPlayers,
        uptime: this.gameServer ? (this.gameServer as any).getStats().uptime : 0,
        config: this.sanitizeConfig(),
        adminPort: this.adminPort,
      });
    });

    router.get("/config", (_req: Request, res: Response) => {
      res.json(this.sanitizeConfig());
    });

    router.put("/config", (req: Request, res: Response) => {
      if (this.gameServer) {
        res.status(400).json({ error: "Stop the server before changing config" });
        return;
      }
      const updates = req.body;
      const allowedKeys = [
        "port", "host", "maxPlayers", "name", "description",
        "password", "map", "maxVehicles", "tickRate", "logLevel",
        "enableDamageSync", "enableNodeSync", "enableModCheck", "private",
      ];
      for (const key of allowedKeys) {
        if (updates[key] !== undefined) {
          (this.config as any)[key] = updates[key];
        }
      }
      this.logger.info("Configuration updated");
      res.json({ success: true, config: this.sanitizeConfig() });
    });

    router.post("/start", (_req: Request, res: Response) => {
      if (this.gameServer) {
        res.status(400).json({ error: "Server is already running" });
        return;
      }
      try {
        this.gameServer = new GameServer(this.config);
        (this.gameServer as any).start();
        this.logger.info("Game server started via admin panel");
        res.json({ success: true });
      } catch (err: any) {
        this.logger.error("Failed to start game server: " + err.message);
        res.status(500).json({ error: err.message });
      }
    });

    router.post("/stop", (_req: Request, res: Response) => {
      if (!this.gameServer) {
        res.status(400).json({ error: "Server is not running" });
        return;
      }
      try {
        (this.gameServer as any).stop();
        this.gameServer = null;
        this.logger.info("Game server stopped via admin panel");
        res.json({ success: true });
      } catch (err: any) {
        this.logger.error("Failed to stop game server: " + err.message);
        res.status(500).json({ error: err.message });
      }
    });

    router.post("/restart", (_req: Request, res: Response) => {
      try {
        if (this.gameServer) {
          (this.gameServer as any).stop();
          this.gameServer = null;
        }
        this.gameServer = new GameServer(this.config);
        (this.gameServer as any).start();
        this.logger.info("Game server restarted via admin panel");
        res.json({ success: true });
      } catch (err: any) {
        this.logger.error("Failed to restart game server: " + err.message);
        res.status(500).json({ error: err.message });
      }
    });

    router.get("/logs", (req: Request, res: Response) => {
      const count = parseInt(req.query.count as string) || 100;
      const logs = this.logHistory.slice(-count);
      res.json({ logs });
    });

    router.get("/players", (_req: Request, res: Response) => {
      if (!this.gameServer) {
        res.json({ players: [] });
        return;
      }
      const stats = (this.gameServer as any).getStats();
      res.json({ players: stats.playersList || [], count: stats.players });
    });

    router.get("/config-template", (_req: Request, res: Response) => {
      res.json(defaultConfig);
    });

    return router;
  }

  private sanitizeConfig(): any {
    const c = { ...this.config } as any;
    if (c.password) c.password = "********";
    if (c.authKey) c.authKey = "********";
    return c;
  }

  start(): void {
    this.httpServer = this.app.listen(this.adminPort, "0.0.0.0", () => {
      console.log(`Admin panel: http://localhost:${this.adminPort}`);
      console.log(`API: http://localhost:${this.adminPort}/api`);
    });
  }

  stop(): void {
    if (this.gameServer) {
      (this.gameServer as any).stop();
      this.gameServer = null;
    }
    this.httpServer.close();
  }
}
