local M = {}

function M.onInit()
  log("I", "mp_position_ge", "Position GE initialized")
end

function M.getPositionTable(veh)
  if not veh then return nil end

  local pos = veh:getPosition()
  local rot = veh:getRotation()

  return {
    pos = { x = pos.x, y = pos.y, z = pos.z },
    rot = { x = rot.x, y = rot.y, z = rot.z, w = rot.w },
    dir = veh:getDirection(),
    up = veh:getUpVector(),
  }
end

function M.getNodePositions(veh, indices)
  if not veh then return {} end

  local result = {}
  for _, idx in ipairs(indices or {}) do
    local nPos = veh:getNodePosition(idx)
    if nPos then
      table.insert(result, { index = idx, position = nPos })
    end
  end
  return result
end

function M.interpolatePosition(a, b, t)
  return {
    x = a.x + (b.x - a.x) * t,
    y = a.y + (b.y - a.y) * t,
    z = a.z + (b.z - a.z) * t,
  }
end

function M.interpolateRotation(a, b, t)
  local dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
  if dot < 0 then
    b = { x = -b.x, y = -b.y, z = -b.z, w = -b.w }
    dot = -dot
  end

  local k0, k1
  if dot > 0.9999 then
    k0 = 1 - t
    k1 = t
  else
    local angle = math.acos(dot)
    local sinAngle = math.sin(angle)
    k0 = math.sin((1 - t) * angle) / sinAngle
    k1 = math.sin(t * angle) / sinAngle
  end

  return {
    x = a.x * k0 + b.x * k1,
    y = a.y * k0 + b.y * k1,
    z = a.z * k0 + b.z * k1,
    w = a.w * k0 + b.w * k1,
  }
end

return M
