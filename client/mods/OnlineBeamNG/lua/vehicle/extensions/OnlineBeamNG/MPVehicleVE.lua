local M = {}

function M.init(veh)
  log("I", "MPVehicleVE", "Vehicle extension initialized")
  veh.mp_synced = true
  veh.mp_ownerId = nil
  veh.mp_remote = false
end

function M.destroy(veh)
  log("I", "MPVehicleVE", "Vehicle extension destroyed")
  veh.mp_synced = nil
end

function M.setRemote(veh, isRemote, ownerId)
  veh.mp_remote = isRemote
  veh.mp_ownerId = ownerId
end

function M.isRemote(veh)
  return veh.mp_remote or false
end

function M.getOwnerId(veh)
  return veh.mp_ownerId
end

return M
