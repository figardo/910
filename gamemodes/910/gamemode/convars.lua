-- types:
-- 1: int
-- 2: float
-- 3: bool

if !NTEN_ConVars then
	NTEN_ConVars = {
		{name = "910_roundtime_seconds", default = "300", flags = FCVAR_NOTIFY, desc = "The length of each round.", type = 2, gmval = "ROUND_LENGTH", mapsettings = "RoundLength", min = 0},
		{name = "910_postround_time", default = "7", flags = FCVAR_NOTIFY, desc = "The duration that the win screen is shown after the round ends.", type = 2, gmval = "POSTROUND_TIME", mapsettings = "PostRoundTime", min = 0},
		{name = "910_suddendeath_time", default = "-1", flags = FCVAR_NOTIFY, desc = "If greater than -1, override sudden death timer (in seconds).", type = 2, gmval = "SUDDEN_DEATH_TIME", mapsettings = "WinLength", min = -1},
		{name = "910_proprespawn_time", default = "2", flags = FCVAR_NOTIFY, desc = "If 910_proprespawn is enabled, set how long each prop spawn takes.", type = 2, gmval = "PROP_RESPAWN_TIME", mapsettings = "PropRespawnLength", min = 0},
		{name = "910_weprespawn", default = "20", flags = FCVAR_NOTIFY, desc = "The time until a weapon respawns after being picked up.", type = 1, gmval = "WEAPON_RESPAWN_TIME", mapsettings = "WeaponRespawnLength", min = 0},
		{name = "910_teamplay", default = "1", flags = FCVAR_NOTIFY, desc = "Used alongside mp_fraglimit. Disable to have FFA deathmatch.", type = 3, gmval = "TEAMPLAY", mapsettings = "Teamplay"},
		{name = "910_largeprop", default = "0", flags = FCVAR_NOTIFY, desc = "If enabled, give double points for collecting large props.", type = 3, gmval = "LARGE_PROP_SCORE", mapsettings = "LargePropScore"},
		{name = "910_coolfx", default = "1", flags = FCVAR_NOTIFY, desc = "Enables cool particle effects when scoring points.", type = 3, gmval = "COOL_FX", mapsettings = "CoolFX"},
		{name = "910_fastmovement", default = "0", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Increase movement speed to 400u/s and disable sprinting.", type = 3, gmval = "FAST_MODE", mapsettings = "FrettaMovement"},
		{name = "910_enablecrowbar", default = "1", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Give the crowbar to players when they spawn (excludes 910_scramble).", type = 3, gmval = "CROWBAR_ENABLED", mapsettings = "EnableCrowbar"},
		{name = "910_enablepistol", default = "0", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Give the pistol to players when they spawn.", type = 3, gmval = "PISTOL_ENABLED", mapsettings = "EnablePistol"},
		{name = "910_buffdamage", default = "1", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Use HL2DM damage values with hitscan guns.", type = 3, gmval = "BUFF_DAMAGE", mapsettings = "BuffDamage"}
	}
end

local CreateConVar = CreateConVar
local cvars_AddChangeCallback = cvars.AddChangeCallback

local override_mapsettings = CreateConVar("910_override_mapsettings", "0", FCVAR_ARCHIVE, "Ignore map defined settings in favour of server settings.")

function GM:ProcessConVarNum(mapSettings, setting, convar)
	if !override_mapsettings:GetBool() and mapSettings and mapSettings[setting] > -1 then
		return mapSettings[setting]
	end

	if setting == "WinLength" and self:IsSourcemod() then
		return 0 -- ctf and gta
	end

	return convar
end

function GM:ProcessConVarBool(mapSettings, setting, convar)
	if !override_mapsettings:GetBool() and mapSettings and mapSettings[setting] > -1 then
		return mapSettings[setting] == 1
	end

	return convar
end

function GM:GetMapSettings()
	if !self.MAP_SETTINGS then
		self.MAP_SETTINGS = ents.FindByClass("nten_mapsettings")[1]
	end

	return self.MAP_SETTINGS
end

function GM:CreateConVars()
	local mapSettings = self:GetMapSettings()

	local convars = NTEN_ConVars

	for i = 1, #convars do
		local data = convars[i]

		local min = data.min
		local max = data.max

		if data.type == 3 then
			min = 0
			max = 1
		end

		local convar = CreateConVar(data.name, data.default, data.flags, data.desc, min, max)
		convars[i].convar = convar

		self:ResetConVar(mapSettings, data, convar)

		cvars_AddChangeCallback(data.name, function() self:ResetConVar(mapSettings, data, convar) end)
	end
end

function GM:ResetConVar(mapSettings, data, convar)
	local cvtype = data.type

	convar = convar or data.convar

	if cvtype == 1 then
		self[data.gmval] = self:ProcessConVarNum(mapSettings, data.mapsettings, convar:GetInt())
	elseif cvtype == 2 then
		self[data.gmval] = self:ProcessConVarNum(mapSettings, data.mapsettings, convar:GetFloat())
	elseif cvtype == 3 then
		self[data.gmval] = self:ProcessConVarBool(mapSettings, data.mapsettings, convar:GetBool())
	end
end