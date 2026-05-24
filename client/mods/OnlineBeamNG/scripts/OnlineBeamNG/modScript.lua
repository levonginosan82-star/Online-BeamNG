local ver = split(beamng_versionb, ".")
local majorVer = tonumber(ver[2])
local compatibleVersion = 38
if majorVer ~= compatibleVersion then
  log("W", "versionCheck", "OnlineBeamNG is incompatible with BeamNG.drive version " .. beamng_versionb)
  log("M", "versionCheck", "Deactivating OnlineBeamNG mod.")
  core_modmanager.deactivateMod("onlinebeammp")
  if majorVer > compatibleVersion then
    guihooks.trigger("toastrMsg", {type="error", title="Error loading OnlineBeamNG", msg="OnlineBeamNG is currently not compatible with BeamNG.drive version " .. beamng_versionb .. ". Check for updates."})
  else
    guihooks.trigger("toastrMsg", {type="error", title="Error loading OnlineBeamNG", msg="OnlineBeamNG is not compatible with BeamNG.drive version " .. beamng_versionb .. ". Please update your game."})
  end
  return
else
  log("M", "versionCheck", "OnlineBeamNG is compatible with the current version.")
end

load("core_network")
setExtensionUnloadMode("core_network", "manual")

load("mp_config")
setExtensionUnloadMode("mp_config", "manual")

load("mp_network")
setExtensionUnloadMode("mp_network", "manual")

load("mp_vehicle_ge")
setExtensionUnloadMode("mp_vehicle_ge", "manual")

load("mp_position_ge")
setExtensionUnloadMode("mp_position_ge", "manual")

load("mp_updates_ge")
setExtensionUnloadMode("mp_updates_ge", "manual")

load("mp_ui")
setExtensionUnloadMode("mp_ui", "manual")

extensions.core_input_categories.onlinebeammp = {
  order = 999,
  icon = "settings",
  title = "OnlineBeamNG",
  desc = "Online BeamNG Controls"
}
