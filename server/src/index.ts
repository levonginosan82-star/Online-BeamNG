import { App } from "./App";

const app = new App();

process.on("SIGINT", () => {
  console.log("\nShutting down...");
  app.stop();
  process.exit(0);
});

process.on("SIGTERM", () => {
  app.stop();
  process.exit(0);

});

app.start();

console.log("========================================");
console.log("  Online BeamNG.drive - Server Manager");
console.log("========================================");
