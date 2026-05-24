local M = {}

function M.init(veh)
  log("I", "velocityVE", "Velocity extension initialized")
  veh.mp_lastVelocity = { x = 0, y = 0, z = 0 }
  veh.mp_lastAngularVelocity = { x = 0, y = 0, z = 0 }
end

function M.setTargetVelocity(veh, velocity, angularVelocity)
  if not veh then return end
  veh.mp_lastVelocity = velocity
  veh.mp_lastAngularVelocity = angularVelocity
end

function M.applyVelocity(veh)
  if not veh or not veh.mp_remote then return end

  pcall(function()
    veh:setVelocity(veh.mp_lastVelocity)
    veh:setAngularVelocity(veh.mp_lastAngularVelocity)
  end)
end

return M
