local M = {}
local updateQueue = {}
local queueTimer = nil

function M.onInit()
  log("I", "mp_updates_ge", "Updates GE initialized")
  queueTimer = timedelay(M.processQueue, 16)
end

function M.onDestroy()
  if queueTimer then
    timedefer(queueTimer)
  end
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
