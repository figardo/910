local tonumber = tonumber
local DevPrint = DevPrint

ENT.Type = "point"
ENT.Base = "base_point"

ENT.HUD = -1

ENT.RoundLength = -1
ENT.PostRoundTime = -1

ENT.WinLength = -1

ENT.PropRespawnLength = -1
ENT.WeaponRespawnLength = -1

ENT.FrettaMovement = -1
ENT.LargePropScore = -1
ENT.CoolFX = -1

ENT.EnableCrowbar = -1
ENT.EnablePistol = -1
ENT.BuffDamage = -1

ENT.Teamplay = -1

local hammerShit = {
	["origin"] = true,
	["classname"] = true,
	["hammerid"] = true
}

function ENT:KeyValue(k, v)
	self[k] = tonumber(v)

	if hammerShit[k] then return end

	DevPrint("Map settings set " .. k .. " to " .. v)
end