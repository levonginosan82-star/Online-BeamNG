type LogLevel = "debug" | "info" | "warn" | "error";

const levelOrder: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const colors: Record<LogLevel, string> = {
  debug: "\x1b[36m",
  info: "\x1b[32m",
  warn: "\x1b[33m",
  error: "\x1b[31m",
};

const reset = "\x1b[0m";

export class Logger {
  private minLevel: number;

  constructor(private name: string, level: LogLevel = "info") {
    this.minLevel = levelOrder[level];
  }

  setLevel(level: LogLevel): void {
    this.minLevel = levelOrder[level];
  }

  private log(level: LogLevel, message: string, ...args: any[]): void {
    if (levelOrder[level] < this.minLevel) return;

    const timestamp = new Date().toISOString().slice(11, 23);
    const color = colors[level];
    const prefix = `${color}[${timestamp}] [${level.toUpperCase()}] [${this.name}]${reset}`;
    console.log(prefix, message, ...args);
  }

  debug(message: string, ...args: any[]): void {
    this.log("debug", message, ...args);
  }

  info(message: string, ...args: any[]): void {
    this.log("info", message, ...args);
  }

  warn(message: string, ...args: any[]): void {
    this.log("warn", message, ...args);
  }

  error(message: string, ...args: any[]): void {
    this.log("error", message, ...args);
  }
}
