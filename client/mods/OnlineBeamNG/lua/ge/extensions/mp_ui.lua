local M = {}
local mainWindow = nil
local chatHistory = {}
local chatInput = ""

function M.onInit()
  log("I", "mp_ui", "UI module initialized")

  mp_network.onAuthenticated = function()
    M.showMainUI()
  end

  mp_network.onAuthFailed = function(reason)
    M.showToast("Auth failed: " .. tostring(reason), "error")
    M.showConnectUI()
  end

  mp_network.onPlayerJoin = function(data)
    M.showToast(data.name .. " joined the server", "info")
  end

  mp_network.onPlayerLeave = function(data)
    M.showToast(data.name .. " left the server", "info")
  end

  mp_network.onKicked = function(reason)
    M.showToast("Kicked: " .. tostring(reason), "error")
    M.showConnectUI()
  end

  mp_network.onChatMessage = function(data)
    table.insert(chatHistory, data)
    if #chatHistory > 100 then
      table.remove(chatHistory, 1)
    end
    M.refreshChatDisplay()
  end
end

function M.showConnectUI()
  mainWindow = guihooks.createWindow({
    id = "onlineBeamNG_connect",
    title = "Online BeamNG",
    width = 400,
    height = 350,
    resizable = false,
    content = function()
      return [[
        <div class="connect-panel">
          <h2>Online BeamNG</h2>
          <div class="form-group">
            <label>Server IP:</label>
            <input type="text" id="serverIP" value="]] .. (mp_config.get("serverIP") or "127.0.0.1") .. [[" />
          </div>
          <div class="form-group">
            <label>Port:</label>
            <input type="number" id="serverPort" value="]] .. tostring(mp_config.get("serverPort") or 30814) .. [[" />
          </div>
          <div class="form-group">
            <label>Username:</label>
            <input type="text" id="username" value="]] .. (mp_config.get("username") or "Player") .. [[" />
          </div>
          <button id="btnConnect" onclick="connectToServer()">Connect</button>
        </div>
      ]]
    end,
  })
end

function M.showMainUI()
  if mainWindow then
    guihooks.closeWindow(mainWindow)
  end

  mainWindow = guihooks.createWindow({
    id = "onlineBeamNG_main",
    title = "Online BeamNG",
    width = 500,
    height = 400,
    content = function()
      return M.renderMainUI()
    end,
  })
end

function M.renderMainUI()
  local players = mp_network.getPlayers()
  local playerListHtml = ""
  for _, p in pairs(players) do
    playerListHtml = playerListHtml .. "<div class='player-item'>" .. p.name .. " (" .. tostring(p.ping or 0) .. "ms)</div>"
  end

  local chatHtml = ""
  for i = math.max(1, #chatHistory - 20), #chatHistory do
    local msg = chatHistory[i]
    chatHtml = chatHtml .. "<div class='chat-msg'><span class='chat-sender'>" .. msg.sender .. ":</span> " .. msg.message .. "</div>"
  end

  return [[
    <div class="main-ui">
      <div class="player-list">
        <h3>Players (]] .. tostring(#players) .. [[)</h3>
        ]] .. playerListHtml .. [[
      </div>
      <div class="chat-box">
        <div class="chat-messages">]] .. chatHtml .. [[</div>
        <div class="chat-input">
          <input type="text" id="chatInput" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendChat()" />
        </div>
      </div>
      <div class="actions">
        <button onclick="disconnectFromServer()">Disconnect</button>
        <button onclick="showVehicleSpawn()">Spawn Vehicle</button>
      </div>
    </div>
  ]]
end

function M.refreshChatDisplay()
  if mainWindow then
    guihooks.updateWindow(mainWindow, { content = M.renderMainUI() })
  end
end

function M.showToast(message, msgType)
  guihooks.trigger("toastrMsg", { type = msgType or "info", title = "OnlineBeamNG", msg = message })
end

function M.connectToServer()
  local ip = guihooks.getInputValue("serverIP")
  local port = tonumber(guihooks.getInputValue("serverPort") or 30814)
  local username = guihooks.getInputValue("username") or "Player"

  mp_config.set("serverIP", ip)
  mp_config.set("serverPort", port)
  mp_config.set("username", username)

  core_network.onConnected = function()
    M.showToast("Connected to server", "success")
  end

  core_network.onDisconnected = function()
    M.showToast("Disconnected from server", "warning")
  end

  core_network.connect(ip, port, username, "")
end

function M.disconnectFromServer()
  core_network.disconnect()
  M.showConnectUI()
end

function M.sendChatMessage()
  local message = guihooks.getInputValue("chatInput")
  if message and message ~= "" then
    mp_network.sendChat(message)
    guihooks.setInputValue("chatInput", "")
  end
end

function M.showVehicleSpawn()
  -- Vehicle spawn UI placeholder
end

return M
