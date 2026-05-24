local M = {}
function M.onInit()
  log("I", "onlineBeamNG_boot", "Loading Online BeamNG extensions...")
  local exts = {"core_network", "mp_network", "mp_ui", "mp_config", "mp_position_ge", "mp_updates_ge", "mp_vehicle_ge"}
  for _, name in ipairs(exts) do
    local ok, err = pcall(extensions.load, name)
    if ok then
      log("I", "onlineBeamNG_boot", "Loaded: " .. name)
    else
      log("W", "onlineBeamNG_boot", "Failed to load " .. name .. ": " .. tostring(err))
    end
  end
end
return M
