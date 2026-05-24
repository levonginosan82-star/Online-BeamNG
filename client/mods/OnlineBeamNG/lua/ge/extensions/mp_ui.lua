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

  mp_network.onSystemMessage = function(data)
    M.showToast(data.message, data.type or "info")
    if data.type == "admin" then
      log("I", "mp_ui", "Admin command: " .. data.message)
    end
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
        <button onclick="showVehicleSpawn()" style="flex:1;padding:6px;background:#4caf50;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Spawn</button>
      </div>
      <div style="margin-top:4px;display:flex;gap:6px;">
        <button onclick="spectateNext(true)" style="flex:1;padding:4px;background:#7e57c2;border:none;border-radius:4px;color:#fff;font-size:11px;cursor:pointer;">Spectate &gt;</button>
        <button onclick="spectateNext(false)" style="flex:1;padding:4px;background:#7e57c2;border:none;border-radius:4px;color:#fff;font-size:11px;cursor:pointer;">&lt; Spectate</button>
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

  function M.showAdminLoginDialog()
    if not mainWindow then
      mainWindow = guihooks.createWindow({
        id = "onlineBeamNG_admin",
        title = "Admin Login",
        width = 300,
        height = 200,
        resizable = false,
        content = function()
          return [[
            <div style="padding:20px;font-family:'Segoe UI',sans-serif;color:#fff;">
              <h3 style="color:#4fc3f7;margin-bottom:16px;">Admin Login</h3>
              <div style="margin-bottom:12px;">
                <input type="password" id="adminPassword" placeholder="Admin Password" style="width:100%;padding:8px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:14px;" />
              </div>
              <div style="display:flex;gap:6px;">
                <button onclick="submitAdminLogin()" style="flex:1;padding:8px;background:#4fc3f7;border:none;border-radius:4px;color:#000;font-weight:600;cursor:pointer;">Login</button>
                <button onclick="closeAdminLogin()" style="flex:1;padding:8px;background:#666;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Cancel</button>
              </div>
            </div>
          ]]
        end,
      })
    end
  end

  function M.submitAdminLogin()
    local password = guihooks.getInputValue("adminPassword") or ""
    mp_network.sendAdminLogin(password)
    guihooks.closeWindow(mainWindow)
    mainWindow = nil
  end

  function M.closeAdminLogin()
    if mainWindow then
      guihooks.closeWindow(mainWindow)
      mainWindow = nil
    end
  end

function M.sendChatMessage()
  local message = guihooks.getInputValue("chatInput") or ""
  if message ~= "" then
    -- Check for admin commands
    if string.sub(message, 1, 1) == "/" then
      log("I", "mp_ui", "Admin command: " .. message)
      mp_network.sendChatCommand(message)
    else
      mp_network.sendChat(message)
    end
    guihooks.setInputValue("chatInput", "")
  end
end

function M.showVehicleSpawn()
  if mainWindow then
    guihooks.updateWindow(mainWindow, {
      content = function()
        local vehicles = {
          "etk800", "sunburst", "moonhawk", "covet",
          "hopper", "roamer", "bluebuck", "pickup",
          "bastion", "burnside", "legran", "miramar",
          "sbr4", "scintilla", "suzuki", "vivace",
          "wendover", "pessima", "ibishu", "barstow"
        }
        local html = [[
          <div style="padding:20px;font-family:'Segoe UI',sans-serif;color:#fff;">
            <h3 style="color:#4fc3f7;margin-bottom:16px;">Spawn Vehicle</h3>
            <div style="margin-bottom:12px;">
              <label style="display:block;font-size:12px;color:#888;margin-bottom:4px;">Select Vehicle</label>
              <select id="vehicleSelect" style="width:100%;padding:8px 10px;background:#222;border:1px solid #444;border-radius:4px;color:#fff;font-size:13px;">
        ]]
        for _, v in ipairs(vehicles) do
          html = html .. '<option value="' .. v .. '">' .. v .. '</option>'
        end
        html = html .. [[
              </select>
            </div>
            <div style="display:flex;gap:6px;">
              <button onclick="spawnSelectedVehicle()" style="flex:1;padding:8px;background:#4caf50;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Spawn</button>
              <button onclick="closeSpawnMenu()" style="flex:1;padding:8px;background:#666;border:none;border-radius:4px;color:#fff;font-weight:600;cursor:pointer;">Cancel</button>
            </div>
          </div>
        ]]
        return html
      end,
    })
  end
end

function M.spawnSelectedVehicle()
  local model = guihooks.getInputValue("vehicleSelect") or "etk800"
  mp_network.sendVehicleSpawn({ model = model })
  guihooks.trigger("toastrMsg", { type = "info", title = "OnlineBeamNG", msg = "Spawning " .. model })
  if mainWindow then
    guihooks.closeWindow(mainWindow)
    mainWindow = nil
  end
  M.refreshMainUI()
end

function M.closeSpawnMenu()
  if mainWindow then
    guihooks.closeWindow(mainWindow)
    mainWindow = nil
  end
  M.refreshMainUI()
end

function M.spectateNext(forward)
  local remoteVehicles = mp_vehicle_ge.getRemoteVehicles()
  local vehicleList = {}
  for id, _ in pairs(remoteVehicles) do
    table.insert(vehicleList, id)
  end
  if #vehicleList == 0 then
    M.showToast("No vehicles to spectate", "info")
    return
  end
  local current = mp_vehicle_ge.getSpectatingId()
  local idx = 1
  if current then
    for i, id in ipairs(vehicleList) do
      if id == current then
        idx = i
        break
      end
    end
  end
  if forward then
    idx = idx + 1
    if idx > #vehicleList then idx = 1 end
  else
    idx = idx - 1
    if idx < 1 then idx = #vehicleList end
  end
  mp_vehicle_ge.spectate(vehicleList[idx])
end

function M.onKeyPress(key, isDown)
  if key == "F3" and not isDown then
    -- Toggle admin login dialog
    M.showAdminLoginDialog()
  end
end

return M
