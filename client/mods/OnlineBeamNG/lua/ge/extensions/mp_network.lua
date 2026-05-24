local M = {}
local players = {}
local myPlayerId = nil

function M.onInit()
  log("I", "mp_network", "Network manager initialized")

  core_network.on("HelloResponse", function(data)
    log("I", "mp_network", "Server version: " .. tostring(data.serverVersion))
  end)

  core_network.on("AuthResponse", function(data)
    if data.success then
      myPlayerId = data.playerId
      log("I", "mp_network", "Authenticated with ID: " .. tostring(myPlayerId))
      if M.onAuthenticated then
        M.onAuthenticated(data)
      end
    else
      log("E", "mp_network", "Auth failed: " .. tostring(data.reason))
      if M.onAuthFailed then
        M.onAuthFailed(data.reason)
      end
    end
  end)

  core_network.on("PlayerJoin", function(data)
    players[data.id] = data
    log("I", "mp_network", "Player joined: " .. tostring(data.name))
    if M.onPlayerJoin then
      M.onPlayerJoin(data)
    end
  end)

  core_network.on("PlayerLeave", function(data)
    players[data.playerId] = nil
    log("I", "mp_network", "Player left: " .. tostring(data.name))
    if M.onPlayerLeave then
      M.onPlayerLeave(data)
    end
  end)

  core_network.on("PlayerList", function(data)
    if data.players then
      for _, p in ipairs(data.players) do
        players[p.id] = p
      end
    end
    if M.onPlayerList then
      M.onPlayerList(data.players)
    end
  end)

  core_network.on("Kick", function(data)
    log("W", "mp_network", "Kicked: " .. tostring(data.reason))
    if M.onKicked then
      M.onKicked(data.reason)
    end
  end)

  core_network.on("ChatMessage", function(data)
    if M.onChatMessage then
      M.onChatMessage(data)
    end
  end)

  core_network.on("SystemMessage", function(data)
    if M.onSystemMessage then
      M.onSystemMessage(data)
    end
  end)

  core_network.on("TimeSync", function(data)
    if M.onTimeSync then
      M.onTimeSync(data)
    end
  end)

  core_network.on("WeatherSync", function(data)
    if M.onWeatherSync then
      M.onWeatherSync(data)
    end
  end)

  core_network.on("VehicleUpdate", function(data)
    if M.onVehicleUpdate then
      M.onVehicleUpdate(data)
    end
  end)

  core_network.on("VehicleSpawn", function(data)
    if M.onVehicleSpawn then
      M.onVehicleSpawn(data)
    end
  end)

  core_network.on("VehicleDespawn", function(data)
    if M.onVehicleDespawn then
      M.onVehicleDespawn(data)
    end
  end)

  core_network.on("VehicleDamage", function(data)
    if M.onVehicleDamage then
      M.onVehicleDamage(data)
    end
  end)

  core_network.on("VehicleInput", function(data)
    if M.onVehicleInput then
      M.onVehicleInput(data)
    end
  end)

  core_network.on("VehicleElectrics", function(data)
    if M.onVehicleElectrics then
      M.onVehicleElectrics(data)
    end
  end)
end

function M.getMyId()
  return myPlayerId
end

function M.getPlayers()
  return players
end

function M.getPlayer(id)
  return players[id]
end

function M.sendChat(message)
  core_network.send("ChatMessage", { message = message })
end

function M.sendChatCommand(command)
  core_network.send("ChatCommand", { command = command })
end

function M.sendAdminLogin(password)
  core_network.send("AdminAuth", { adminPassword = password })
end

function M.sendVehicleUpdate(state)
  core_network.send("VehicleUpdate", state)
end

function M.sendVehicleSpawn(data)
  core_network.send("VehicleSpawn", data)
end

function M.sendVehicleDespawn(vehicleId)
  core_network.send("VehicleDespawn", { vehicleId = vehicleId })
end

function M.sendVehicleDamage(data)
  core_network.send("VehicleDamage", data)
end

function M.sendVehicleInput(data)
  core_network.send("VehicleInput", data)
end

function M.sendVehicleElectrics(data)
  core_network.send("VehicleElectrics", data)
end

return M
