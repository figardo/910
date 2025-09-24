local TYPE_INT = 1
local TYPE_FLOAT = 2
local TYPE_BOOL = 3

if !NTEN_ConVars then
	NTEN_ConVars = {
		{name = "910_roundtime_seconds", default = "300", flags = FCVAR_NOTIFY, desc = "The length of each round.", type = TYPE_FLOAT, gmval = "ROUND_LENGTH", mapsettings = "RoundLength", min = 0},
		{name = "910_postround_time", default = "7", flags = FCVAR_NOTIFY, desc = "The duration that the win screen is shown after the round ends.", type = TYPE_FLOAT, gmval = "POSTROUND_TIME", mapsettings = "PostRoundTime", min = 0},
		{name = "910_suddendeath_time", default = "-1", flags = FCVAR_NOTIFY, desc = "If greater than -1, override sudden death timer (in seconds).", type = TYPE_FLOAT, gmval = "SUDDEN_DEATH_TIME", mapsettings = "WinLength", min = -1},
		{name = "910_proprespawn_time", default = "2", flags = FCVAR_NOTIFY, desc = "If 910_proprespawn is enabled, set how long each prop spawn takes.", type = TYPE_FLOAT, gmval = "PROP_RESPAWN_TIME", mapsettings = "PropRespawnLength", min = 0},
		{name = "910_weprespawn", default = "20", flags = FCVAR_NOTIFY, desc = "The time until a weapon respawns after being picked up.", type = TYPE_INT, gmval = "WEAPON_RESPAWN_TIME", mapsettings = "WeaponRespawnLength", min = 0},
		{name = "910_teamplay", default = "1", flags = FCVAR_NOTIFY, desc = "Used alongside mp_fraglimit. Disable to have FFA deathmatch.", type = TYPE_BOOL, gmval = "TEAMPLAY", mapsettings = "Teamplay"},
		{name = "910_largeprop", default = "0", flags = FCVAR_NOTIFY, desc = "If enabled, give double points for collecting large props.", type = TYPE_BOOL, gmval = "LARGE_PROP_SCORE", mapsettings = "LargePropScore"},
		{name = "910_coolfx", default = "1", flags = FCVAR_NOTIFY, desc = "Enables cool particle effects when scoring points.", type = TYPE_BOOL, gmval = "COOL_FX", mapsettings = "CoolFX"},
		{name = "910_fastmovement", default = "0", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Increase movement speed to 400u/s and disable sprinting.", type = TYPE_BOOL, gmval = "FAST_MODE", mapsettings = "FrettaMovement"},
		{name = "910_enablecrowbar", default = "1", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Give the crowbar to players when they spawn (excludes 910_scramble).", type = TYPE_BOOL, gmval = "CROWBAR_ENABLED", mapsettings = "EnableCrowbar"},
		{name = "910_enablepistol", default = "0", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Give the pistol to players when they spawn.", type = TYPE_BOOL, gmval = "PISTOL_ENABLED", mapsettings = "EnablePistol"},
		{name = "910_buffdamage", default = "1", flags = FCVAR_NOTIFY + FCVAR_ARCHIVE, desc = "Use HL2DM damage values with hitscan guns.", type = TYPE_BOOL, gmval = "BUFF_DAMAGE", mapsettings = "BuffDamage"}
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

		if data.type == TYPE_BOOL then
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

	if cvtype == TYPE_INT then
		self[data.gmval] = self:ProcessConVarNum(mapSettings, data.mapsettings, convar:GetInt())
	elseif cvtype == TYPE_FLOAT then
		self[data.gmval] = self:ProcessConVarNum(mapSettings, data.mapsettings, convar:GetFloat())
	elseif cvtype == TYPE_BOOL then
		self[data.gmval] = self:ProcessConVarBool(mapSettings, data.mapsettings, convar:GetBool())
	end
end