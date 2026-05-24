local M = {}
function M.onInit()
  log("I", "onlineBeamNG_boot", "Starting Online BeamNG mod...")

  local ok1, err1 = pcall(load, "core_network")
  if not ok1 or err1 then
    log("W", "onlineBeamNG_boot", "core_network: " .. tostring(err1))
  else
    log("I", "onlineBeamNG_boot", "core_network loaded")
  end

  local ok2, err2 = pcall(load, "mp_network")
  if ok2 then log("I", "onlineBeamNG_boot", "mp_network loaded") end

  local ok3, err3 = pcall(load, "mp_ui")
  if ok3 then log("I", "onlineBeamNG_boot", "mp_ui loaded") end

  local ok4, err4 = pcall(load, "mp_config")
  if ok4 then log("I", "onlineBeamNG_boot", "mp_config loaded") end

  local ok5, err5 = pcall(load, "mp_position_ge")
  if ok5 then log("I", "onlineBeamNG_boot", "mp_position_ge loaded") end

  local ok6, err6 = pcall(load, "mp_updates_ge")
  if ok6 then log("I", "onlineBeamNG_boot", "mp_updates_ge loaded") end

  local ok7, err7 = pcall(load, "mp_vehicle_ge")
  if ok7 then log("I", "onlineBeamNG_boot", "mp_vehicle_ge loaded") end
end
return M
