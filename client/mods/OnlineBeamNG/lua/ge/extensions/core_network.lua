local M = {}
local connected = false
local socket = nil
local reconnectTimer = nil
local reconnectAttempt = 0
local pendingMessages = {}

local handlers = {}

function M.onInit()
  log("I", "core_network", "Network module initialized")
end

function M.connect(ip, port, username, password)
  if connected then
    log("W", "core_network", "Already connected")
    return
  end

  local url = "ws://" .. ip .. ":" .. tostring(port)

  local ok, err = socketconnect(url, {
    onopen = function()
      connected = true
      reconnectAttempt = 0
      log("I", "core_network", "Connected to " .. url)

      local helloMsg = {
        type = "Hello",
        data = {
          clientVersion = "1.0.0",
          protocolVersion = 1,
        }
      }
      M.sendRaw(jsonEncode(helloMsg))

      local authMsg = {
        type = "Auth",
        data = {
          username = username or "Player",
          password = password or "",
        }
      }
      M.sendRaw(jsonEncode(authMsg))

      for _, msg in ipairs(pendingMessages) do
        M.sendRaw(msg)
      end
      pendingMessages = {}

      if M.onConnected then
        M.onConnected()
      end
    end,

    onmessage = function(data)
      M.handleMessage(data)
    end,

    onerror = function(err)
      log("E", "core_network", "Socket error: " .. tostring(err))
    end,

    onclose = function()
      connected = false
      socket = nil
      log("W", "core_network", "Connection closed")
      if M.onDisconnected then
        M.onDisconnected()
      end
      M.scheduleReconnect()
    end,
  })

  if not ok then
    log("E", "core_network", "Failed to connect: " .. tostring(err))
    M.scheduleReconnect()
    return false
  end

  return true
end

function M.disconnect()
  if socket then
    socketclose(socket)
  end
  connected = false
  socket = nil
  if reconnectTimer then
    timedefer(reconnectTimer)
    reconnectTimer = nil
  end
end

function M.send(type, data)
  local msg = jsonEncode({ type = type, data = data })
  if connected then
    M.sendRaw(msg)
  else
    table.insert(pendingMessages, msg)
  end
end

function M.sendRaw(data)
  if socket and connected then
    socketsend(socket, data)
  end
end

function M.isConnected()
  return connected
end

function M.handleMessage(data)
  local ok, parsed = pcall(jsonDecode, data)
  if not ok or not parsed then
    log("E", "core_network", "Failed to parse message")
    return
  end

  local msgType = parsed.type
  local msgData = parsed.data

  if handlers[msgType] then
    for _, handler in ipairs(handlers[msgType]) do
      local hOk, hErr = pcall(handler, msgData)
      if not hOk then
        log("E", "core_network", "Handler error for " .. tostring(msgType) .. ": " .. tostring(hErr))
      end
    end
  else
    log("D", "core_network", "Unhandled message type: " .. tostring(msgType))
  end

  -- Special handling for server messages that need to be routed
  if msgType == "SystemMessage" or msgType == "TimeSync" or msgType == "WeatherSync" then
    if handlers[msgType] then
      for _, handler in ipairs(handlers[msgType]) do
        local hOk, hErr = pcall(handler, msgData)
        if not hOk then
          log("E", "core_network", "Handler error for " .. tostring(msgType) .. ": " .. tostring(hErr))
        end
      end
    end
  end
end

function M.on(type, handler)
  if not handlers[type] then
    handlers[type] = {}
  end
  table.insert(handlers[type], handler)
end

function M.scheduleReconnect()
  if reconnectAttempt >= (mp_config.get("maxReconnects") or 3) then
    log("W", "core_network", "Max reconnects reached")
    return
  end

  local delay = mp_config.get("reconnectDelay") or 5
  reconnectAttempt = reconnectAttempt + 1

  log("I", "core_network", "Reconnecting in " .. tostring(delay) .. "s (attempt " .. tostring(reconnectAttempt) .. ")")

  reconnectTimer = timedelay(function()
    local ip = mp_config.get("serverIP") or "127.0.0.1"
    local port = mp_config.get("serverPort") or 30814
    local name = mp_config.get("username") or "Player"
    M.connect(ip, port, name, "")
  end, delay * 1000)
end

return M
