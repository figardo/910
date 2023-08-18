function GM:DoRoundTimer()
	local iTimeLeft = GetGlobalFloat("fRoundEnd") - CurTime()

	if iTimeLeft > 0 or timer.Exists("910_RestartTimer") or self.bEndGame then return end

	local allplys = player.GetAll()
	for i = 1, #allplys do
		allplys[i]:Freeze(true)
	end

	local winners = {}
	local reference = table.Copy(self.ItemCount)
	table.sort(reference)
	reference = table.Reverse(reference)

	local highest = reference[1]

	for i = 1, #team.GetAllTeams() do
		if self.ItemCount[i] != highest then continue end

		table.insert(winners, i)
		team.AddScore(i, 1)
	end

	net.Start("910_Winner")
		net.WriteUInt(self.POSTROUND_TIME, 6)
		net.WriteUInt(#winners - 1, 3)
		for i = 1, #winners do
			local winner = winners[i]
			net.WriteUInt(winner - 1, 3)

			local plys = team.GetPlayers(i)
			for j = 1, #plys do
				plys[j]:AddWins(1)
			end
		end
	net.Broadcast()

	-- Schedule a round restart
	timer.Create("910_RestartTimer", self.POSTROUND_TIME, 1, function()
		local roundCount = GetGlobalInt("iRoundNumber", 1) + 1
		SetGlobalInt("iRoundNumber", roundCount)

		if hook.Call("910_RoundEnd", self, roundCount) then
			self.bEndGame = true
			self.fIntermissionEnd = CurTime() + 300

			return
		end

		self:RoundRestart()
	end)
end

function GM:SetSuddenDeath(enable)
	self.SuddenDeathMode = enable

	net.Start("910_SuddenDeath")
		net.WriteBool(enable)
	net.Broadcast()
end

--  The current map has ended, show the scoreboard ----------------------------
function GM:StartIntermission()
	self.bEndGame = true

	self.fIntermissionEnd = CurTime() + GetConVar("mp_chattime"):GetFloat()

	-- Loop through all players
	local plys = player.GetAll()
	for i = 1, #plys do
		local ply = plys[i]

		net.Start("910_ShowScoreboard")
		net.Send(ply)

		ply:Freeze(true)
	end
end

-- might as well grab these from gm12
-- Finds a prop spawn point
local blockers = {"player", "info_base_blue", "info_base_yellow", "gmod_player_start"}
function GM:LocateSpawn()
	-- Find a spawn that isn't blocked
	local spawn = table.Random( self.InfoProps )
	for _, v in ipairs(ents.FindInSphere( spawn:GetPos(), 64 )) do
		if table.HasValue( blockers, v:GetClass() ) then
			spawn = self:LocateSpawn()
		end
	end

	return spawn
end

-- Randomly spawn props
function GM:SpawnProps()
	-- No spawnpoints
	if #self.InfoProps <= 0 then
		--GAMEMODE:CreateSpawns()
		return
	end

	-- Find me a spawnpoint
	local spawn = self:LocateSpawn()

	-- Randomly spawn a prop, barrel, and big prop
	local chance = math.random(1, 10)
	local object = "prop_physics"
	--if chance == 4 then
	--	object = "item_item_crate"
	--end

	-- Spiffy effects
	local boosh = EffectData()
	boosh:SetOrigin(spawn:GetPos())
	boosh:SetScale(1)
	util.Effect("prop_spawn", boosh)

	-- Create it
	local prop = ents.Create(object)
	prop:SetPos(spawn:GetPos())

	if !spawn.DisableLargeProp and (chance == 1 or chance == 2) then
		prop:SetModel(self.LargeModels[math.random(#self.LargeModels)])
	elseif !spawn.DisableExplosiveProp and chance == 3 then
		prop:SetModel(self.ExplosiveModels[math.random(#self.ExplosiveModels)])
	--elseif chance == 4 then
	--	prop:SetKeyValue( "ItemClass", "item_healthvial" )
	--	prop:SetKeyValue("ItemCount", math.random( 1, 5 ))
	else
		prop:SetModel(GAMEMODE.PropModels[math.random(#GAMEMODE.PropModels)])
		-- prop:SetModel(GAMEMODE.SmallProps[math.random(#GAMEMODE.SmallProps)])
	end

	prop:Spawn()
end

-- yes all of this is still necessary
-- why?
-- because game.cleanupmap cuts the win sound early.
function GM:StorePropList()
	local props = ents.FindByClass("prop_physics*")

	for i = 1, #props do
		local prop = props[i]

		self:AddRespawnableProp(i, prop)
	end
end

function GM:AddRespawnableProp(idx, prop)
	self.RespawnableProps[idx] = {}

	self.RespawnableProps[idx].model = prop:GetModel()
	self.RespawnableProps[idx].pos = prop:GetPos()
	self.RespawnableProps[idx].ang = prop:GetAngles()

	local physobj = prop:GetPhysicsObject()
	self.RespawnableProps[idx].frozen = IsValid(physobj) and physobj:IsMotionEnabled() or false
end

function GM:PropRespawn(prop)
	local iEnt = ents.Create("prop_physics")
		iEnt:SetModel(prop.model) -- the model will already be precached
		iEnt:SetPos(prop.pos)
		iEnt:SetAngles(prop.ang)
	iEnt:Spawn()

	iEnt:GetPhysicsObject():EnableMotion(prop.frozen)

	table.insert(self.PropCache, iEnt:EntIndex())
end

function GM:RespawnStoredProps()
	local respawnProps = self.RespawnableProps

	-- Print a list of respawn props
	--PrintTable( respawnProps )

	if #respawnProps == 0 then return end

	-- Remove all current props
	local props = ents.FindByClass("prop_physics*")
	for i = 1, #props do
		local ent = props[i]
		ent:Remove()
	end

	-- Spawn all the new props
	for i = 1, #respawnProps do
		local ent = respawnProps[i]
		self:PropRespawn(ent)
	end
end

function GM:GetBestTeam()
	local teams = self.ItemCount
	local highest = 0
	local lowest = {}

	for i = 1, #teams do
		local plys = #team.GetPlayers(i)

		if plys > highest then
			highest = plys
		end
	end

	for i = 1, #teams do
		local plys = #team.GetPlayers(i)

		if plys < highest then
			table.insert(lowest, i)
		end
	end

	return #lowest > 0 and lowest[1] or 1
end

function GM:TeamsAreUnbalanced()
	local teams = self.ItemCount
	local highest = 0

	for i = 1, #teams do
		local plys = #team.GetPlayers(i)

		if plys > highest then
			highest = plys
		end
	end

	for i = 1, #teams do
		local plys = #team.GetPlayers(i)

		if plys < highest - 1 then
			return true
		end
	end

	return false
end

function GM:ShuffleTeams(plys, showmsg)
	table.Shuffle(plys)

	for i = 1, #plys do
		plys[i]:SetTeam(TEAM_SPECTATOR)
	end

	for i = 1, #plys do
		local ply = plys[i]

		self:ChangeTeam(ply, 7)

		if showmsg then
			ply:ChatPrint("Team unbalance detected. Shuffling teams...")
		end
	end
end
concommand.Add("910_shuffleteams", function() GAMEMODE:ShuffleTeams(player.GetAll(), false) end, nil, "Force every player into a new random team.")

function GM:RoundRestart(firstRestart)
	SetGlobalFloat("fRoundEnd", CurTime() + self.ROUND_LENGTH)

	local plys = player.GetAll()
	for i = 1, #plys do
		local ply = plys[i]

		-- Unfreeze everyone and respawn all players
		ply:KillSilent()
		ply:Spawn()

		ply:Freeze(false)

		-- Reset indivdual scores to 0
		ply:SetDeliveries(0)
		ply:SetSteals(0)
	end

	if !self.ActiveTeams then return end

	if !firstRestart then
		self.PropCache = {}

		if self:IsGM9() then
			for i = 1, #self.ItemCount do
				self:UpdateScore(i, -self.LargeItemCount[i])
				self.LargeItemCount[i] = 0
			end
		end

		if self:TeamsAreUnbalanced() then
			self:ShuffleTeams(plys, true)
		end
	end

	self:RespawnStoredProps()

	if timer.Exists("RoundTimer") then timer.Stop("RoundTimer") end

	timer.Create("RoundTimer", 1, 0, function() self:DoRoundTimer() end)

	self:SetSuddenDeath(false)
end
concommand.Add("910_restartround", function() GAMEMODE:RoundRestart() end)

function GM:SendInitial(ply)
	local i = 1
	for id, _ in SortedPairs(self.ActiveTeams) do
		net.Start("910_SendTeams")
			net.WriteUInt(id - 1, 3)
		net.Send(ply)

		timer.Simple(0, function()
			self.ItemCount[i] = self.ItemCount[i] or 0

			net.Start("910_SetScore")
				net.WriteUInt(i, 3)
				net.WriteUInt(self.ItemCount[i], 8)
			net.Send(ply)

			i = i + 1
		end)
	end

	local version = self.GamemodeVersion

	if self.MAP_SETTINGS and self.MAP_SETTINGS.HUD > -1 then
		version = self.MAP_SETTINGS.HUD -- lie to the client because it only uses this for huds
	end

	net.Start("910_SendMode")
		net.WriteUInt(version, 3)
	net.Send(ply)
end
net.Receive("910_Ready", function(_, ply) GAMEMODE:SendInitial(ply) end)

function GM:UpdateScore(tid, amount)
	if !self.ItemCount[tid] then self.ItemCount[tid] = 0 end
	self.ItemCount[tid] = self.ItemCount[tid] + amount

	net.Start("910_UpdateScores")
		net.WriteUInt(tid - 1, 2)
		net.WriteInt(amount, 5)
	net.Broadcast()
end

-- The syntax for these functions should nearly always be the same
--
-- Activator 	- The entity that initially caused this chain of output events.

-- Caller		- The entity that fired this particular output.

-- The third parameter depends on which output the gmod_runfunction entity called

local fxTbl = {
	["#NineTenths.BlueTeam"] = "blue_point",
	["#NineTenths.YellowTeam"] = "yellow_point",
	["#NineTenths.RedTeam"] = "red_point",
	["#NineTenths.GreenTeam"] = "green_point"
}

function GM:EntityTouch(prop, teamID, addScore)
	local numTeams = #self.ItemCount
	if self.GamemodeVersion == 0 and teamID > numTeams then
		local diff = teamID - numTeams
		teamID = teamID - diff
	end

	local amount = 1

	-- on gm9 maps that use trigger_multiple, if a prop is broken in a base then it becomes invalid by the time it reaches here
	-- therefore, we only check validity when it's needed
	-- please don't modify the gamemode to add a breakable large prop lol

	if IsValid(prop) and (self.LARGE_PROP_SCORE or self:IsFretta()) and table.HasValue(self.LargeModels, prop:GetModel()) then
		amount = 2

		if self:IsGM9() then
			self.LargeItemCount[teamID] = self.LargeItemCount[teamID] + 1
		end
	end

	if !addScore then amount = -amount end

	local hookAmount = hook.Run("910_EntityTouch", teamID, prop, amount)
	if hookAmount then amount = hookAmount end

	self:UpdateScore(teamID, amount)

	-- Get the player that shot the entity..

	if !IsValid(prop) then return end

	if self.COOL_FX then
		local boosh = EffectData()
		boosh:SetOrigin(prop:GetPos())
		boosh:SetScale(1)

		local fxname = fxTbl[team.GetName(teamID)]

		util.Effect(fxname, boosh)
	end

	local iPlayer = prop:GetPhysicsAttacker()
	if !iPlayer:IsPlayer() then return end

	local ownTeamAffected = iPlayer:Team() == teamID

	if !addScore and !ownTeamAffected then
		iPlayer:AddSteals(1)

		return
	end

	local goodDelivery = addScore and ownTeamAffected

	if goodDelivery then
		iPlayer:AddDeliveries(1)
	end

	local frags = goodDelivery and 1 or -1

	net.Start("910_RPSound")
		net.WriteBool(frags > 0)
	net.Send(iPlayer)
end

function onEntityTouch(teamID)
	local a = ACTIVATOR
	if !IsValid(a) then return end

	GAMEMODE:EntityTouch(a, teamID, true)
end

function onEntityUntouch(teamID)
	local a = ACTIVATOR

	GAMEMODE:EntityTouch(a, teamID, false)
end

function GM:ChangeTeam(ply, teamid)
	if teamid == 7 then
		teamid = GAMEMODE:GetBestTeam()
	end

	ply:KillSilent()
	ply:SetTeam(teamid)

	local col = team.GetColor(teamid)

	ply:SetPlayerColor(col:ToVector())

	timer.Simple(2, function() ply:Spawn() end)
end
net.Receive("910_ChangeTeam", function(_, ply)
	local tid = net.ReadUInt(3) + 1

	GAMEMODE:ChangeTeam(ply, tid)
end)