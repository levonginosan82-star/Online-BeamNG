local M = {}
local updateQueue = {}
local queueTimer = nil

local currentWeather = nil
local currentTime = nil

function M.onInit()
  log("I", "mp_updates_ge", "Updates GE initialized")

  mp_network.onTimeSync = function(data)
    M.onTimeSync(data)
  end

  mp_network.onWeatherSync = function(data)
    M.onWeatherSync(data)
  end

  queueTimer = timedelay(M.processQueue, 16)
end

function M.onDestroy()
  if queueTimer then
    timedefer(queueTimer)
  end
end

function M.onTimeSync(data)
  if not data then return end
  log("D", "mp_updates_ge", "Time sync: " .. tostring(data.time) .. "h (scale: " .. tostring(data.timeScale) .. "x)")
  currentTime = data
  pcall(function()
    if core_gamestate and core_gamestate.setTimeOfDay then
      core_gamestate.setTimeOfDay(data.time)
    end
  end)
  pcall(function()
    if core_gamestate and core_gamestate.setTimeScale then
      core_gamestate.setTimeScale(data.timeScale or 1)
    end
  end)
end

function M.onWeatherSync(data)
  if not data then return end
  log("D", "mp_updates_ge", "Weather sync: " .. tostring(data.weather))
  currentWeather = data
  pcall(function()
    executeCommand("setWeather", data.weather)
  end)
end

function M.queueUpdate(vehicleId, data)
  if not updateQueue[vehicleId] then
    updateQueue[vehicleId] = {}
  end
  table.insert(updateQueue[vehicleId], data)

  if #updateQueue[vehicleId] > 10 then
    table.remove(updateQueue[vehicleId], 1)
  end
end

function M.processQueue()
  for vehicleId, queue in pairs(updateQueue) do
    if #queue > 0 then
      local latest = queue[#queue]
      local remoteVehicles = mp_vehicle_ge.getRemoteVehicles()
      local entry = remoteVehicles[vehicleId]
      if entry and entry.obj then
        pcall(function()
          entry.obj:setPosition(latest.position)
          entry.obj:setRotation(latest.rotation)
        end)
      end
      updateQueue[vehicleId] = {}
    end
  end
  queueTimer = timedelay(M.processQueue, 16)
end

function M.getLatency()
  return math.random(10, 50)
end

return M
