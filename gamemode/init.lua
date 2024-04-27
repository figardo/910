local include = include
local AddCSLuaFile = AddCSLuaFile
local util = util
local RunConsoleCommand = RunConsoleCommand
local timer = timer
local GetConVar = GetConVar
local CurTime = CurTime
local CreateConVar = CreateConVar
local GetGlobalFloat = GetGlobalFloat
local SetGlobalFloat = SetGlobalFloat
local ents = ents
local table = table
local game = game
local team = team
local player = player
local IsValid = IsValid
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local Vector = Vector
local SetGlobalInt = SetGlobalInt
local IsUselessModel = IsUselessModel
local math = math
local bit = bit
local print = print

----------------------------------------------------------------------------------

-- 9/10ths Lua script

-- By Garry Newman

----------------------------------------------------------------------------------

GM.TeamBased = true

include("gamerules.lua")
include("hookexamples.lua")
include("convars.lua")
include("tables.lua")

include("plymeta.lua")
include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("plymeta.lua")

AddCSLuaFile("vgui/cl_scoreboard.lua")
AddCSLuaFile("vgui/cl_voice.lua")
AddCSLuaFile("vgui/gui.lua")
AddCSLuaFile("vgui/gui_sourcemod.lua")
AddCSLuaFile("vgui/gui_gm9.lua")
AddCSLuaFile("vgui/gui_fretta.lua")
AddCSLuaFile("vgui/drawarc.lua")

util.AddNetworkString("910_ChangeTeam")
util.AddNetworkString("910_RPSound")
util.AddNetworkString("910_ShowScoreboard")
util.AddNetworkString("910_UpdateScores")
util.AddNetworkString("910_Winner")
util.AddNetworkString("910_SendTeams")
util.AddNetworkString("910_SetScore")
util.AddNetworkString("910_SendMode")
util.AddNetworkString("910_Ready")

--  Called right before the new map starts ------------------------------------
function GM:Initialize()
	-- Anything to imitialize?
	-- Settings
	self.bEndGame = false
	self.fIntermissionEnd = 0

	self.GamemodeVersion = 0
	self.CurrentTeamID = 0

	self.ItemCount = {}
	self.LargeItemCount = {}
	self.PropCache = {}

	self.RespawnableProps = {}
	self.WeaponsToRespawn = {}

	RunConsoleCommand("sv_alltalk", "1")

	timer.Simple( 3, function() self:StorePropList() end)
end

local TimeLimit = GetConVar("mp_timelimit"):GetFloat() * 60 -- Minutes to seconds!
local startTime = CurTime()
local FragLimit = GetConVar("mp_fraglimit"):GetFloat()

local cachedTime

local respawningIndexes = {}

local shouldSuddenDeath = CreateConVar("910_suddendeath", "0", FCVAR_NOTIFY, "If enabled, cut timer down to x seconds when one team has all props in a map.", 0, 1)

function GM:DoSuddenDeath()
	if #self.PropCache == 0 or #self.InfoProps > 0 then return end

	local roundEnd = GetGlobalFloat("fRoundEnd")
	local suddenDeathInt = self.SUDDEN_DEATH_TIME

	local timeLeft = roundEnd - CurTime()

	local tempcheck = false

	if (shouldSuddenDeath:GetBool() or self:IsSourcemod() or suddenDeathInt > -1) and timeLeft > 0 and !self:IsFretta() then
		for i = 1, #self.ItemCount do
			if #self.PropCache > self.ItemCount[i] then continue end -- does this team have every prop in the map?

			tempcheck = true

			if self:GetSuddenDeath() or timeLeft <= suddenDeathInt then continue end

			local sdTime = CurTime() + suddenDeathInt
			cachedTime = roundEnd
			SetGlobalFloat("fRoundEnd", sdTime)

			self:SetSuddenDeath(true)

			break
		end

		if self:GetSuddenDeath() and !tempcheck then
			SetGlobalFloat("fRoundEnd", cachedTime)

			self:SetSuddenDeath(false)
		end
	elseif timeLeft <= 0 then
		cachedTime = CurTime() + self.ROUND_LENGTH
	end
end

--  Called every frame from: CHL2MPRules::Think( void ) -----------------------
function GM:Think()
	self:DoSuddenDeath()

	local weps = self.WeaponsToRespawn
	for i = 1, #weps do
		local wep = weps[i]

		if respawningIndexes[i] then
			if respawningIndexes[i] <= CurTime() then
				local ent = ents.Create(wep.class)
				ent:SetPos(wep.pos)
				ent:SetAngles(wep.ang)
				ent:Spawn()

				ent:EmitSound("weapons/stunstick/alyx_stunner2.wav")

				wep.idx = ent:EntIndex()
				respawningIndexes[i] = nil

				DevPrint("Respawned " .. wep.class)
			end

			continue
		end

		local wepcheck = Entity(wep.idx)
		if IsValid(wepcheck) and wepcheck:IsWeapon() and !IsValid(wepcheck:GetOwner()) then continue end

		local respawnTime = self.WEAPON_RESPAWN_TIME
		DevPrint("Set " .. wep.class .. " to respawn in " .. respawnTime .. " seconds")
		respawningIndexes[i] = CurTime() + respawnTime
	end

	-- gameover is true when the game has ended and everyone

	-- is looking at the scoreboard blaming lag for their score
	if self.bEndGame then
		if self.fIntermissionEnd < CurTime() then
			game.LoadNextMap()
		end

		return
	end

	if FragLimit > 0 then -- We have a fraglimit!
		if GetConVar("mp_teamplay"):GetBool() then
			local NumTeams = #team.GetAllTeams()

			for i = 1, NumTeams do
				if team.GetScore(i) < FragLimit then continue end

				self:StartIntermission()
				break
			end
		else
			for _, ply in player.Iterator() do
				if !IsValid(ply) or ply:Frags() < FragLimit then continue end

				self:StartIntermission()
				break
			end
		end
	end

	if TimeLimit > 0 and startTime + TimeLimit < CurTime() then
		self:StartIntermission()
	end
end --gamerulesThink

local storedWepClasses = {
	["weapon_357"] = true,
	["weapon_alyxgun"] = true,
	["weapon_ar2"] = true,
	["weapon_bugbait"] = true,
	["weapon_crossbow"] = true,
	["weapon_frag"] = true,
	["weapon_pistol"] = true,
	["weapon_rpg"] = true,
	["weapon_shotgun"] = true,
	["weapon_slam"] = true,
	["weapon_smg1"] = true,
	["weapon_stunstick"] = true,
	["item_healthkit"] = true
}

function GM:PropBreak(ply, prop)
	table.RemoveByValue(self.PropCache, prop:EntIndex())
end

-- Give the players the default weapons --
function GM:PlayerLoadout(ply)
	if ply:Team() == TEAM_SPECTATOR then return end

	if !self:IsFretta() and self.CROWBAR_ENABLED then
		ply:Give("weapon_crowbar")
	end

	-- ply:Give("weapon_pistol")
	ply:Give("weapon_physcannon")

	ply:SelectWeapon("weapon_physcannon")
end

function GM:EntityKeyValue(ent, k, v)
	local class = ent:GetClass()

	if class == "nten_teambase" then -- modern
		if !self.ActiveTeams then self.ActiveTeams = {} end

		local id = ent.TeamID
		if id == 0 then return end

		if id and !self.ActiveTeams[id] then
			self.ActiveTeams[id] = true
		end
	elseif class == "gmod_runfunction" then
		self.GamemodeVersion = 1 -- gm9
		return
	elseif class:find("trigger_itemcount") then
		self.GamemodeVersion = 2 -- sourcemod
		return
	elseif class:find("func_base") then
		self.GamemodeVersion = 3 -- fretta
		return
	end

	if k == "OnStartTouch" or k == "OnEndTouch" then -- gm9
		if !self.ActiveTeams then self.ActiveTeams = {} end
		local id

		if class == "trigger_multiple" then
			local sub = v:match(",(.*)")
			id = tonumber(sub:sub(18, 18))
		end

		if id and !self.ActiveTeams[id] then
			self.ActiveTeams[id] = true
		end
	end
end

local respawningProps = CreateConVar("910_proprespawn", "0", FCVAR_NOTIFY, "Replaces all props with respawning prop spawnpoints.", 0, 1)
local removeAllWeapons = CreateConVar("910_removeweapons", "0", FCVAR_ARCHIVE, "Removes all HL2DM weapons from maps that would normally spawn them.")

function GM:InitPostEntity()
	local mapSettings = ents.FindByClass("nten_mapsettings")
	if #mapSettings > 0 then
		self.MAP_SETTINGS = mapSettings[1]
	end

	self:ResetValues()

	SetGlobalFloat("fRoundEnd", CurTime() + self.ROUND_LENGTH)

	if !self.ActiveTeams then self.ActiveTeams = {} end

	if self:IsSourcemod() then -- sourcemod compatibility
		local blue = self.Teams[1]
		local red = self.Teams[3]

		team.SetUp(1, blue[1], blue[2])
		team.SetUp(2, red[1], red[2])

		self.ActiveTeams = {[1] = true, [3] = true} -- blue and red

		self.ItemCount[1] = 0
		self.ItemCount[2] = 0
	elseif self:IsFretta() then -- gm12 compatibility
		local blue = self.Teams[1]
		local yellow = self.Teams[2]

		team.SetUp(1, blue[1], blue[2])
		team.SetUp(2, yellow[1], yellow[2])

		self.ActiveTeams = {[1] = true, [2] = true} -- blue and yellow

		self.ItemCount[1] = 0
		self.ItemCount[2] = 0
	else
		local i = 1
		for id, _ in pairs(self.ActiveTeams) do
			local tinfo = self.Teams[id]
			team.SetUp(i, tinfo[1], tinfo[2])

			self.ItemCount[i] = 0

			i = i + 1
		end
	end

	for i = 1, #self.ItemCount do
		self.LargeItemCount[i] = 0
	end

	for _, prop in ipairs(ents.FindByClass("prop_physics*")) do
		if respawningProps:GetBool() and !self:IsFretta() then
			local info = ents.Create("info_prop")
			info:SetPos(prop:GetPos() + Vector(0, 0, 45))
			info:Spawn()

			prop:Remove()
		end

		table.insert(self.PropCache, prop:EntIndex())
	end

	local weps = ents.FindByClass("weapon*")
	if removeAllWeapons:GetBool() then
		for i = 1, #weps do
			local wep = weps[i]
			if !storedWepClasses[wep:GetClass()] then continue end

			wep:Remove()
		end
	else
		for i = 1, #weps do
			local wep = weps[i]

			local class = wep:GetClass()
			if !storedWepClasses[class] then continue end

			table.insert(self.WeaponsToRespawn, {class = class, idx = wep:EntIndex(), pos = wep:GetPos(), ang = wep:GetAngles()})
		end
	end

	self.InfoProps = ents.FindByClass("info_prop")

	if #self.InfoProps > 0 then
		timer.Create("SpawnProps", self.PROP_RESPAWN_TIME, 0, function() GAMEMODE:SpawnProps() end)
	end

	SetGlobalInt("iRoundNumber", 1)

	self:RoundRestart(true)
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
	if !ply:IsPlayer() then return end

	if IsValid(dmginfo:GetAttacker()) and ply:Team() == dmginfo:GetAttacker():Team() then
		dmginfo:ScaleDamage(0)
		return
	end

	if dmginfo:GetDamageType() == DMG_CLUB then
		dmginfo:ScaleDamage(2.5)
	end
end

function GM:EntityTakeDamage(ent, dmginfo)
	if dmginfo:GetDamageType() != DMG_CLUB or !ent:GetClass():find("^prop_physics") then return false end

	dmginfo:ScaleDamage(4)

	return false
end

-- This is very important, it will crash if a player doesn't have a model! --
-- ^ not in gm13 lol
function GM:PlayerSpawnChooseModel(ply)
	local preferred = ply:GetInfo("910_model", "")

	-- The player doesn't have a preferred model, set it randomly
	if preferred == "" or IsUselessModel(preferred) then
		local allowedModels = self.PlayerModels
		ply:SetModel(allowedModels[math.random(#allowedModels)])

		-- The player has a preferred model, use that!
	else
		ply:SetModel(preferred)
	end
end

local forceAutoSelect = CreateConVar("910_force_autoselect", "0", FCVAR_ARCHIVE, "When enabled, force players to select the team with the lowest playercount.", 0, 1)

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_SPECTATOR)
	ply:SetCustomCollisionCheck(true)

	local spawnlist = ents.FindByClass("info_player_start")
	local specSpawn = spawnlist[math.random(#spawnlist)]

	local pos = IsValid(specSpawn) and specSpawn:GetPos() or Vector(0, 0, 0)
	local ang = IsValid(specSpawn) and specSpawn:GetAngles() or Angle(0, 0, 0)

	timer.Simple(0, function()
		ply:SetPos(pos)
		ply:SetAngles(ang)
	end)

	self:PlayerSpawnChooseModel(ply)

	local walk, sprint = 190, 330
	if self:IsFretta() or self.FAST_MODE then
		walk, sprint = 400, 400
	end

	self:SetPlayerSpeed(ply, walk, sprint)

	timer.Simple(0, function()
		ply:Spectate(OBS_MODE_ROAMING)

		-- If they're a spectator show them the team choice menu
		if ply:Team() != TEAM_SPECTATOR then return end

		timer.Simple(4.5, function()
			if forceAutoSelect:GetBool() or self:IsSourcemod() or ply:IsBot() then
				local tid = self:GetBestTeam()
				ply:KillSilent()
				ply:SetTeam(tid)
				ply:SetPlayerColor(team.GetColor(tid):ToVector())
				ply:Spawn()
			else
				self:ShowTeam(ply)
			end
		end)
	end)
end

function GM:PlayerSpawn(ply)
	self.BaseClass.PlayerSpawn(self, ply)

	if ply:Team() == TEAM_SPECTATOR or !self:IsFretta() then return end

	-- Spawn sounds
	local snd = table.Random( GAMEMODE.SpawnSounds )
	ply:EmitSound( snd, 100, math.random( 80, 120 ) )
end

function GM:DoPlayerDeath(ply, attacker, dmg)
	self.BaseClass.DoPlayerDeath(self, ply, attacker, dmg)

	if ply:Team() == TEAM_SPECTATOR or !self:IsFretta() then return end

	-- When a player dies, fvox makes a witty comment
	local snd = table.Random( GAMEMODE.DeathSounds )
	ply:EmitSound( snd, 100, math.random( 80, 120 ) )
end

--
-- Reproduces the jump boost from HL2 singleplayer
-- ripped from sandbox (teehee)
--

function GM:SetupMove(ply, move)
	if !self:IsFretta() then return end

	-- Only apply the jump boost in FinishMove if the player has jumped during this frame
	-- Using a global variable is safe here because nothing else happens between SetupMove and FinishMove
	if bit.band( move:GetButtons(), IN_JUMP ) != 0 and bit.band( move:GetOldButtons(), IN_JUMP ) == 0 and ply:OnGround() then
		ply.Jumping = true
	end
end

function GM:FinishMove(ply, move)
	if !self:IsFretta() then return end

	-- If the player has jumped this frame
	if ply.Jumping then
		-- Get their orientation
		local forward = move:GetAngles()
		forward.p = 0
		forward = forward:Forward()

		-- Compute the speed boost

		-- HL2 normally provides a much weaker jump boost when sprinting
		-- For some reason this never applied to GMod, so we won't perform
		-- this check here to preserve the "authentic" feeling
		local speedBoostPerc = !ply:Crouching() and 0.5 or 0.1

		local speedAddition = math.abs( move:GetForwardSpeed() * speedBoostPerc )
		local maxSpeed = move:GetMaxSpeed() * ( 1 + speedBoostPerc )
		local newSpeed = speedAddition + move:GetVelocity():Length2D()

		-- Clamp it to make sure they can't bunnyhop to ludicrous speed
		if newSpeed > maxSpeed then
			speedAddition = speedAddition - (newSpeed - maxSpeed)
		end

		-- Reverse it if the player is running backwards
		if move:GetVelocity():Dot(forward) < 0 then
			speedAddition = -speedAddition
		end

		-- Apply the speed boost
		move:SetVelocity(forward * speedAddition + move:GetVelocity())
	end

	ply.Jumping = nil
end

local activeToFlag = {
	[1] = 1, -- blue
	[2] = 2, -- yellow
	[3] = 8, -- red
	[4] = 4 -- green
}

local lastSpawn = {}

function GM:PlayerSelectTeamSpawn(tid, ply)
	local spawnlist = {}

	if tid == TEAM_SPECTATOR then return end

	if self:IsSourcemod() then
		local ent = tid == 1 and "info_player_blueteam" or "info_player_redteam"
		spawnlist = ents.FindByClass(ent)
	elseif self:IsFretta() then
		local ent = tid == 1 and "info_player_blue" or "info_player_yellow"
		spawnlist = ents.FindByClass(ent)
	else
		local activeTeam = tid

		if self.ActiveTeams and #self.ActiveTeams > 0 then
			while !self.ActiveTeams[activeTeam] do
				activeTeam = activeTeam + 1
			end
		end

		local potentialspawns = ents.FindByClass("gmod_player_start")
		for i = 1, #potentialspawns do
			local spawn = potentialspawns[i]
			if spawn:GetKeyValues()["spawnflags"] != activeToFlag[activeTeam] then
				continue
			end

			table.insert(spawnlist, spawn)
		end
	end

	if !lastSpawn[tid] or lastSpawn[tid] >= #spawnlist then
		lastSpawn[tid] = 1
	else
		lastSpawn[tid] = lastSpawn[tid] + 1
	end

	return spawnlist[lastSpawn[tid]]
end

function GM:ShowTeam(ply)
	ply:ConCommand("910_showteam")
end

function GM:ShowHelp(ply)
	ply:ConCommand("910_helpscreen")
end

function GM:GravGunOnPickedUp(ply, ent)
	ent:SetPhysicsAttacker(ply)
end

function GM:PlayerSwitchFlashlight(ply)
	return ply:Team() != TEAM_SPECTATOR
end

print("--------------------------------------------------------")
print("-- gm_910 -------------------------  Nine Tenths  ------")
print("--------------------------------------------------------")