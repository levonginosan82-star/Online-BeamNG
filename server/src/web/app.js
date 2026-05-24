const API = "/api";
let pollInterval = null;
let autoScroll = true;

document.addEventListener("DOMContentLoaded", () => {
  initNav();
  initConfig();
  initControls();
  initLogs();
  pollStatus();
  pollInterval = setInterval(pollStatus, 3000);
});

function initNav() {
  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      document.querySelectorAll(".tab-content").forEach(t => t.classList.remove("active"));
      document.getElementById(`tab-${btn.dataset.tab}`).classList.add("active");
    });
  });
}

async function api(method, path, body) {
  const opts = { method, headers: { "Content-Type": "application/json" } };
  if (body) opts.body = JSON.stringify(body);
  try {
    const res = await fetch(`${API}${path}`, opts);
    return await res.json();
  } catch (e) {
    console.error("API error:", e);
    return { error: e.message };
  }
}

async function pollStatus() {
  const data = await api("GET", "/status");
  if (data.error) return;

  const running = data.running;
  const dot = document.getElementById("statusDot");
  const text = document.getElementById("statusText");
  dot.className = "status-indicator " + (running ? "running" : "stopped");
  text.textContent = running ? "Running" : "Stopped";

  document.getElementById("btnStart").disabled = running;
  document.getElementById("btnStop").disabled = !running;
  document.getElementById("btnRestart").disabled = !running;

  document.getElementById("statPlayers").textContent = data.players;
  document.getElementById("statMaxPlayers").textContent = data.maxPlayers;
  document.getElementById("statVehicles").textContent = data.vehicles || 0;
  document.getElementById("statUptime").textContent = formatUptime(data.uptime);
  document.getElementById("infoName").textContent = data.config?.name || "-";
  document.getElementById("infoMap").textContent = data.config?.map || "-";
  document.getElementById("infoAdminPort").textContent = data.adminPort;

  if (data.config) populateConfig(data.config);
}

async function initConfig() {
  const data = await api("GET", "/config");
  if (data) populateConfig(data);

  document.getElementById("btnSaveConfig").addEventListener("click", saveConfig);
}

function populateConfig(cfg) {
  setVal("cfg_name", cfg.name);
  setVal("cfg_description", cfg.description);
  setVal("cfg_port", cfg.port);
  setVal("cfg_host", cfg.host);
  setVal("cfg_maxPlayers", cfg.maxPlayers);
  setVal("cfg_password", cfg.password === "********" ? "" : (cfg.password || ""));
  setVal("cfg_map", cfg.map);
  setVal("cfg_maxVehicles", cfg.maxVehicles);
  setVal("cfg_tickRate", cfg.tickRate);
  setVal("cfg_logLevel", cfg.logLevel);
  setChecked("cfg_enableDamageSync", cfg.enableDamageSync);
  setChecked("cfg_enableNodeSync", cfg.enableNodeSync);
  setChecked("cfg_enableModCheck", cfg.enableModCheck);
  setChecked("cfg_private", cfg.private);
}

async function saveConfig() {
  const cfg = {
    name: getVal("cfg_name"),
    description: getVal("cfg_description"),
    port: parseInt(getVal("cfg_port")) || 30814,
    host: getVal("cfg_host"),
    maxPlayers: parseInt(getVal("cfg_maxPlayers")) || 16,
    password: getVal("cfg_password"),
    map: getVal("cfg_map"),
    maxVehicles: parseInt(getVal("cfg_maxVehicles")) || 4,
    tickRate: parseInt(getVal("cfg_tickRate")) || 20,
    logLevel: getVal("cfg_logLevel"),
    enableDamageSync: getChecked("cfg_enableDamageSync"),
    enableNodeSync: getChecked("cfg_enableNodeSync"),
    enableModCheck: getChecked("cfg_enableModCheck"),
    private: getChecked("cfg_private"),
  };

  const res = await api("PUT", "/config", cfg);
  const status = document.getElementById("configStatus");
  if (res.success) {
    status.textContent = "Configuration saved";
    status.style.color = "#4caf50";
  } else {
    status.textContent = res.error || "Error saving config";
    status.style.color = "#ef5350";
  }
  setTimeout(() => { status.textContent = ""; }, 3000);
}

function initControls() {
  document.getElementById("btnStart").addEventListener("click", async () => {
    const res = await api("POST", "/start");
    if (res.error) showToast(res.error, "error");
    else pollStatus();
  });
  document.getElementById("btnStop").addEventListener("click", async () => {
    const res = await api("POST", "/stop");
    if (res.error) showToast(res.error, "error");
    else pollStatus();
  });
  document.getElementById("btnRestart").addEventListener("click", async () => {
    const res = await api("POST", "/restart");
    if (res.error) showToast(res.error, "error");
    else pollStatus();
  });
}

function initLogs() {
  const container = document.getElementById("logsContainer");

  document.getElementById("btnAutoScroll").addEventListener("click", function () {
    autoScroll = !autoScroll;
    this.classList.toggle("active");
  });

  document.getElementById("btnClearLogs").addEventListener("click", () => {
    container.innerHTML = "";
  });

  setInterval(async () => {
    const data = await api("GET", "/logs?count=50");
    if (!data.logs) return;

    container.innerHTML = "";
    data.logs.forEach(line => {
      try {
        const parsed = JSON.parse(line);
        const el = document.createElement("div");
        el.className = "log-line";
        const time = parsed.timestamp ? parsed.timestamp.slice(11, 23) : "";
        const level = (parsed.level || "info").toLowerCase();
        el.innerHTML = `<span class="time">[${time}]</span> <span class="level-${CSS.escape(level)}">[${level.toUpperCase()}]</span> ${escapeHtml(parsed.message)}`;
        container.appendChild(el);
      } catch {
        const el = document.createElement("div");
        el.className = "log-line";
        el.textContent = line;
        container.appendChild(el);
      }
    });

    if (autoScroll) container.scrollTop = container.scrollHeight;
  }, 2000);
}

function formatUptime(seconds) {
  if (!seconds) return "0s";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) return `${h}h ${m}m ${s}s`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

function getVal(id) { return document.getElementById(id)?.value || ""; }
function setVal(id, val) { const el = document.getElementById(id); if (el) el.value = val ?? ""; }
function getChecked(id) { return document.getElementById(id)?.checked || false; }
function setChecked(id, val) { const el = document.getElementById(id); if (el) el.checked = !!val; }

function escapeHtml(text) {
  const d = document.createElement("div");
  d.textContent = text;
  return d.innerHTML;
}

function showToast(msg, type) {
  console.log(`[${type}] ${msg}`);
}
