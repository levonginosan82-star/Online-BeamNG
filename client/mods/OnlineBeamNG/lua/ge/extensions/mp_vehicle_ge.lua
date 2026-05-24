local M = {}
local remoteVehicles = {}
local updateTimer = nil
local sendInterval = 50
local myVehicleId = nil
local spectatingId = nil
local previousCameraMode = nil

function M.onInit()
  log("I", "mp_vehicle_ge", "Vehicle GE initialized")
  myVehicleId = mp_network.getMyId() .. "_vehicle"

  mp_network.onVehicleSpawn = function(data)
    M.spawnRemoteVehicle(data)
  end

  mp_network.onVehicleDespawn = function(data)
    M.despawnRemoteVehicle(data.vehicleId)
  end

  mp_network.onVehicleUpdate = function(data)
    M.updateRemoteVehicle(data)
  end

  mp_network.onVehicleDamage = function(data)
    M.applyRemoteDamage(data)
  end

  mp_network.onVehicleInput = function(data)
    M.applyRemoteInput(data)
  end

  mp_network.onVehicleElectrics = function(data)
    M.applyRemoteElectrics(data)
  end

  updateTimer = timedelay(M.updateLoop, sendInterval)
end

function M.onDestroy()
  if updateTimer then
    timedefer(updateTimer)
    updateTimer = nil
  end
end

function M.updateLoop()
  if not core_network.isConnected() then return end

  local veh = getPlayerVehicle(0)
  if not veh then return end

  local pos = veh:getPosition()
  local rot = veh:getRotation()
  local vel = veh:getVelocity()
  local angVel = veh:getAngularVelocity()

  local state = {
    id = (mp_network.getMyId() or "player") .. "_vehicle",
    position = { x = pos.x, y = pos.y, z = pos.z },
    rotation = { x = rot.x, y = rot.y, z = rot.z, w = rot.w },
    velocity = { x = vel.x, y = vel.y, z = vel.z },
    angularVelocity = { x = angVel.x, y = angVel.y, z = angVel.z },
    engineRunning = veh:getEngineRunning(),
    speed = veh:getSpeed(),
    gear = veh:getGear(),
    rpm = veh:getRPM(),
    steering = veh:getSteering(),
    throttle = veh:getThrottle(),
    braking = veh:getBraking(),
    clutch = veh:getClutch(),
  }

  mp_network.sendVehicleUpdate(state)
  updateTimer = timedelay(M.updateLoop, sendInterval)
end

function M.spawnRemoteVehicle(data)
  if remoteVehicles[data.vehicleId] then return end

  local vehData = {
    model = data.jBeam or "etk800",
    position = data.position or { x = 0, y = 0, z = 100 },
    rotation = data.rotation or { x = 0, y = 0, z = 0, w = 1 },
  }

  local ok, err = pcall(function()
    local veh = spawnPlayerVehicle(data.vehicleId, vehData.model, vehData.position, vehData.rotation)
    if veh then
      remoteVehicles[data.vehicleId] = {
        obj = veh,
        owner = data.ownerId,
        model = vehData.model,
      }
      log("I", "mp_vehicle_ge", "Spawned remote vehicle: " .. tostring(data.vehicleId))
    end
  end)

  if not ok then
    log("E", "mp_vehicle_ge", "Failed to spawn vehicle: " .. tostring(err))
  end
end

function M.despawnRemoteVehicle(vehicleId)
  local entry = remoteVehicles[vehicleId]
  if not entry then return end

  pcall(function()
    deleteVehicle(entry.obj)
  end)
  remoteVehicles[vehicleId] = nil
end

function M.updateRemoteVehicle(data)
  local entry = remoteVehicles[data.id]
  if not entry then return end

  local veh = entry.obj
  if not veh then return end

  pcall(function()
    veh:setPosition(data.position)
    veh:setRotation(data.rotation)
    if data.velocity then
      veh:setVelocity(data.velocity)
    end
    if data.angularVelocity then
      veh:setAngularVelocity(data.angularVelocity)
    end
  end)
end

function M.applyRemoteDamage(data)
  local entry = remoteVehicles[data.vehicleId]
  if not entry or not entry.obj then return end

  pcall(function()
    if data.nodes then
      for _, nodeData in ipairs(data.nodes) do
        entry.obj:setNodePosition(nodeData.index, nodeData.position)
      end
    end
    if data.damage then
      entry.obj:setDamage(data.damage)
    end
  end)
end

function M.applyRemoteInput(data)
  -- Input sync placeholder (future: sync steering/throttle/brake)
end

function M.applyRemoteElectrics(data)
  local entry = remoteVehicles[data.vehicleId]
  if not entry or not entry.obj then return end

  pcall(function()
    if data.lights then
      entry.obj:setLights(data.lights)
    end
  end)
end

function M.getRemoteVehicles()
  return remoteVehicles
end

function M.spectate(vehicleId)
  local entry = remoteVehicles[vehicleId]
  if not entry or not entry.obj then
    log("W", "mp_vehicle_ge", "Cannot spectate vehicle " .. tostring(vehicleId) .. ": not found")
    return
  end
  spectatingId = vehicleId
  pcall(function()
    setCameraTarget(entry.obj)
    setCameraMode("chase")
  end)
  log("I", "mp_vehicle_ge", "Spectating vehicle: " .. tostring(vehicleId))
end

function M.stopSpectate()
  spectatingId = nil
  pcall(function()
    setCameraMode("chase")
    setCameraTarget(getPlayerVehicle(0))
  end)
end

function M.getSpectatingId()
  return spectatingId
end

return M
