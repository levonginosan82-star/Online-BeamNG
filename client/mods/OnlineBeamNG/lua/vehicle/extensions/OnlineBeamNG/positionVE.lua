local M = {}

function M.init(veh)
  log("I", "positionVE", "Position extension initialized")
  veh.mp_lastPosition = nil
  veh.mp_lastRotation = nil
  veh.mp_interpTimer = 0
end

function M.update(veh, dt)
  if not veh.mp_remote then return end

  -- Placeholder for interpolation logic
  veh.mp_interpTimer = veh.mp_interpTimer + dt
end

function M.setTargetTransform(veh, pos, rot)
  veh.mp_lastPosition = veh.mp_lastPosition or veh:getPosition()
  veh.mp_lastRotation = veh.mp_lastRotation or veh:getRotation()
end

return M
