local M = {}

local defaults = {
  serverIP = "127.0.0.1",
  serverPort = 30814,
  username = "Player",
  autoConnect = false,
  reconnectDelay = 5,
  maxReconnects = 3,
}

function M.loadConfig()
  local config = {}
  local path = "mods/OnlineBeamNG/settings/config.json"
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, parsed = pcall(jsonDecode, content)
    if ok and type(parsed) == "table" then
      config = parsed
    end
  end
  for k, v in pairs(defaults) do
    if config[k] == nil then
      config[k] = v
    end
  end
  M.config = config
  return config
end

function M.saveConfig()
  local path = "mods/OnlineBeamNG/settings/config.json"
  local file = io.open(path, "w")
  if file then
    file:write(jsonEncode(M.config))
    file:close()
  end
end

function M.get(key)
  if not M.config then
    M.loadConfig()
  end
  return M.config[key]
end

function M.set(key, value)
  if not M.config then
    M.loadConfig()
  end
  M.config[key] = value
  M.saveConfig()
end

M.loadConfig()

return M
