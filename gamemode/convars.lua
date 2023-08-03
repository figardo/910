local CreateConVar = CreateConVar
local cvars_AddChangeCallback = cvars.AddChangeCallback

local override_mapsettings = CreateConVar("910_override_mapsettings", "0", FCVAR_ARCHIVE, "Ignore map defined settings in favour of server settings.")

local roundtimer = CreateConVar("910_roundtime_seconds", "300", FCVAR_NOTIFY, "The length of each round.", 0)
local postRoundTime = CreateConVar("910_postround_time", "7", FCVAR_NOTIFY, "The duration that the win screen is shown after the round ends.", 0)

local suddenDeathTime = CreateConVar("910_suddendeath_time", "-1", FCVAR_NOTIFY, "If greater than -1, override sudden death timer (in seconds).", -1)

local respawnTime = CreateConVar("910_proprespawn_time", "2", FCVAR_NOTIFY, "If 910_proprespawn is enabled, set how long each prop spawn takes.", 0)

local wepRespawnTime = CreateConVar("910_weprespawn", "20", FCVAR_NOTIFY, "The time until a weapon respawns after being picked up.", 0)

local teamplay = CreateConVar("910_teamplay", "1", FCVAR_NOTIFY, "Used alongside mp_fraglimit. Disable to have FFA deathmatch.", 0, 1)

local largePropScore = CreateConVar("910_largeprop", "0", FCVAR_NOTIFY, "If enabled, give double points for collecting large props.", 0, 1)

local coolFX = CreateConVar("910_coolfx", "1", FCVAR_NOTIFY, "Enables cool particle effects when scoring points.", 0, 1)

function GM:ProcessConVarNum(setting, convar)
	if !override_mapsettings:GetBool() and self.MAP_SETTINGS and self.MAP_SETTINGS[setting] > -1 then
		return self.MAP_SETTINGS[setting]
	end

	if setting == "WinLength" and self:IsSourcemod() then
		return 0 -- ctf and gta
	end

	return convar
end

function GM:ProcessConVarBool(setting, convar)
	if !override_mapsettings:GetBool() and self.MAP_SETTINGS then
		return self.MAP_SETTINGS[setting] == 1
	end

	return convar:GetBool()
end

function GM:ResetValues()
	self.ROUND_LENGTH = self:ProcessConVarNum("RoundLength", roundtimer:GetInt()) -- in seconds
	self.POSTROUND_TIME = self:ProcessConVarNum("PostRoundTime", postRoundTime:GetInt())

	self.SUDDEN_DEATH_TIME = self:ProcessConVarNum("WinLength", suddenDeathTime:GetInt())

	self.PROP_RESPAWN_TIME = self:ProcessConVarNum("PropRespawnLength", respawnTime:GetInt())

	self.WEAPON_RESPAWN_TIME = self:ProcessConVarNum("WeaponRespawnLength", wepRespawnTime:GetFloat())

	self.TEAMPLAY = self:ProcessConVarBool("Teamplay", teamplay)

	self.LARGE_PROP_SCORE = self:ProcessConVarBool("LargePropScore", largePropScore)

	self.COOL_FX = self:ProcessConVarBool("CoolFX", coolFX)
end
cvars_AddChangeCallback("910_override_mapsettings", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_roundtime_seconds", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_suddendeath", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_suddendeath_time", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_proprespawn", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_proprespawn_time", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_weprespawn", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_postround_time", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_teamplay", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_largeprop", function() GAMEMODE:ResetValues() end)
cvars_AddChangeCallback("910_coolfx", function() GAMEMODE:ResetValues() end)