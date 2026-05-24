local M = {}
local mainWindow = nil
local chatHistory = {}
local windowVisible = false

function M.onInit()
  log("I", "mp_ui", "UI module initialized")

  mp_network.onAuthenticated = function(data)
    log("I", "mp_ui", "Authenticated with server")
    M.showMainUI(data)
  end

  mp_network.onAuthFailed = function(reason)
    log("W", "mp_ui", "Auth failed: " .. tostring(reason))
  end

  mp_network.onPlayerJoin = function(data)
    M.showToast(data.name .. " joined", "info")
  end

  mp_network.onPlayerLeave = function(data)
    M.showToast(data.name .. " left", "info")
  end

  mp_network.onChatMessage = function(data)
    table.insert(chatHistory, data)
    if #chatHistory > 100 then table.remove(chatHistory, 1) end
  end

  mp_network.onKicked = function(reason)
    M.showToast("Kicked: " .. tostring(reason), "error")
    M.showConnectUI()
  end

  M.showConnectUI()
end

function M.onUpdate(dt)
  if not windowVisible and core_network and not core_network.isConnected() then
    M.showConnectUI()
    windowVisible = true
  end
  if core_network and core_network.isConnected() and mainWindow then
    M.refreshMainUI()
  end
end

function M.showConnectUI()
  if mainWindow then
    guihooks.closeWindow(mainWindow)
    mainWindow = nil
  end

  mainWindow = guihooks.createWindow({
    id = "onlineBeamNG_connect",
    title = "Online BeamNG",
    width = 380,
    height = 320,
    resizable = false,
    content = function()
      return [[
        <div style="padding:20px;font-family:'Segoe UI',sans-serif;color:#fff;">
          <h2 style="color:#4fc3f7;margin-bottom:16px;">Online BeamNG</h2>
          <div style="margin-bottom:12px;">
            <label style="display:block;font-size:12px;color:#888;margin-bottom:4px;">Server IP</label>
            <input type="text" id="serverIP" value="127.0.0.1" style="width:100%;padding:8px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:14px;" />
          </div>
          <div style="margin-bottom:12px;">
            <label style="display:block;font-size:12px;color:#888;margin-bottom:4px;">Port</label>
            <input type="number" id="serverPort" value="30814" style="width:100%;padding:8px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:14px;" />
          </div>
          <div style="margin-bottom:20px;">
            <label style="display:block;font-size:12px;color:#888;margin-bottom:4px;">Username</label>
            <input type="text" id="username" value="Player" style="width:100%;padding:8px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:14px;" />
          </div>
          <button onclick="connectToServer()" style="width:100%;padding:10px;background:#4fc3f7;border:none;border-radius:4px;color:#000;font-size:14px;font-weight:600;cursor:pointer;">Connect</button>
        </div>
      ]]
    end,
  })
  windowVisible = true
end

function M.showMainUI(data)
  if mainWindow then
    guihooks.closeWindow(mainWindow)
    mainWindow = nil
  end

  M.refreshMainUI()
end

function M.refreshMainUI()
  if not core_network.isConnected() then
    M.showConnectUI()
    return
  end

  if not mainWindow then
    mainWindow = guihooks.createWindow({
      id = "onlineBeamNG_main",
      title = "Online BeamNG",
      width = 480,
      height = 380,
      content = function() return M.renderMainContent() end,
    })
  else
    guihooks.updateWindow(mainWindow, { content = function() return M.renderMainContent() end })
  end
end

function M.renderMainContent()
  local players = mp_network.getPlayers()
  local playerCount = 0
  local playerHtml = ""
  for _, p in pairs(players) do
    playerCount = playerCount + 1
    playerHtml = playerHtml .. "<div style='padding:4px 0;border-bottom:1px solid #333;font-size:13px;'>" .. p.name .. " <span style='color:#666;'>(" .. tostring(p.ping or 0) .. "ms)</span></div>"
  end

  local chatHtml = ""
  for i = math.max(1, #chatHistory - 15), #chatHistory do
    local msg = chatHistory[i]
    if msg then
      chatHtml = chatHtml .. "<div style='margin-bottom:2px;font-size:12px;'><span style='color:#4fc3f7;font-weight:600;'>" .. msg.sender .. ":</span> " .. (msg.message or "") .. "</div>"
    end
  end

  return [[
    <div style="padding:12px;font-family:'Segoe UI',sans-serif;color:#fff;display:flex;flex-direction:column;height:100%;">
      <div style="margin-bottom:8px;">
        <div style="font-size:13px;color:#4fc3f7;font-weight:600;margin-bottom:4px;">Players (]] .. playerCount .. [[)</div>
        <div style="max-height:100px;overflow-y:auto;background:rgba(0,0,0,0.3);border-radius:4px;padding:6px;">]] .. playerHtml .. [[</div>
      </div>
      <div style="flex:1;display:flex;flex-direction:column;">
        <div style="font-size:13px;color:#4fc3f7;font-weight:600;margin-bottom:4px;">Chat</div>
        <div id="chatMessages" style="flex:1;overflow-y:auto;background:rgba(0,0,0,0.3);border-radius:4px;padding:6px;font-size:12px;margin-bottom:6px;">]] .. chatHtml .. [[</div>
        <div style="display:flex;gap:6px;">
          <input type="text" id="chatInput" placeholder="Type a message..." style="flex:1;padding:6px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:13px;" onkeydown="if(event.key==='Enter')sendChatMessage()" />
          <button onclick="sendChatMessage()" style="padding:6px 14px;background:#4fc3f7;border:none;border-radius:4px;color:#000;font-weight:600;cursor:pointer;">Send</button>
        </div>
      </div>
      <div style="margin-top:8px;display:flex;gap:6px;">
        <button onclick="disconnectFromServer()" style="flex:1;padding:6px;background:#ef5350;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Disconnect</button>
        <button onclick="showVehicleSpawn()" style="flex:1;padding:6px;background:#4caf50;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Spawn Vehicle</button>
      </div>
    </div>
  ]]
end

function M.showToast(message, msgType)
  guihooks.trigger("toastrMsg", { type = msgType or "info", title = "OnlineBeamNG", msg = message })
end

-- JS bridge functions (called from HTML)
function M.connectToServer()
  local ip = guihooks.getInputValue("serverIP") or "127.0.0.1"
  local port = tonumber(guihooks.getInputValue("serverPort") or 30814)
  local username = guihooks.getInputValue("username") or "Player"

  mp_config.set("serverIP", ip)
  mp_config.set("serverPort", port)
  mp_config.set("username", username)

  core_network.connect(ip, port, username, "")
end

function M.disconnectFromServer()
  core_network.disconnect()
  M.showConnectUI()
end

function M.sendChatMessage()
  local message = guihooks.getInputValue("chatInput") or ""
  if message ~= "" then
    mp_network.sendChat(message)
    guihooks.setInputValue("chatInput", "")
  end
end

function M.showVehicleSpawn()
  log("I", "mp_ui", "Vehicle spawn requested")
end

return M
