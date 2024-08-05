GM.Name = "Nine Tenths"
GM.Author = "Garry Newman"
GM.Email = ""
GM.Website = "garry.blog"

GM.Teams = { -- if you want more than 4 teams you are deranged
	{"#NineTenths.BlueTeam", Color(46, 151, 255)},
	{"#NineTenths.YellowTeam", Color(255, 201, 0)},
	{"#NineTenths.RedTeam", Color(222, 60, 62)},
	{"#NineTenths.GreenTeam", Color(0, 255, 0)}
}

function GM:ShouldCollide(ent1, ent2)
	if !ent1:IsPlayer() or !ent2:IsPlayer() then return true end

	if ent1:Team() == ent2:Team() then return false end

	return true
end


--
-- Reproduces the jump boost from HL2 singleplayer
-- ripped from sandbox (teehee)
--
function GM:SetupMove(ply, move)
	if (SERVER and !self:IsFretta() and !self.FAST_MODE) or (CLIENT and move:GetMaxSpeed() <= 330) then return end

	-- Only apply the jump boost in FinishMove if the player has jumped during this frame
	-- Using a global variable is safe here because nothing else happens between SetupMove and FinishMove
	if bit.band( move:GetButtons(), IN_JUMP ) != 0 and bit.band( move:GetOldButtons(), IN_JUMP ) == 0 and ply:OnGround() then
		ply.Jumping = true
	end
end

function GM:FinishMove(ply, move)
	if (SERVER and !self:IsFretta() and !self.FAST_MODE) or (CLIENT and move:GetMaxSpeed() <= 330) then return end

	local plytbl = ply:GetTable()

	-- If the player has jumped this frame
	if plytbl.Jumping then
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

	plytbl.Jumping = nil
end

---Print 
---@param ... string
function DevPrint(...)
	if !GetConVar("developer"):GetBool() then return end

	Msg("[910]")
	-- table.concat does not tostring, derp

	local params = {...}
	for i = 1,#params do
		Msg(" " .. tostring(params[i]))
	end

	Msg("\n")
end

---Get if sudden death is enabled
---@return boolean
function GM:GetSuddenDeath()
	return GetGlobal2Bool("910_SuddenDeath", false)
end

---Return true if map contains GMod 9 entities.
---@return boolean
function GM:IsGM9()
	return self.GamemodeVersion == 1
end

---Return true if map contains Sourcemod entities.
---@return boolean
function GM:IsSourcemod()
	return self.GamemodeVersion == 2
end

---Return true if map contains Fretta entities.
---@return boolean
function GM:IsFretta()
	return self.GamemodeVersion == 3
end

---Return true if map contains GMod 10 entities.
---@return boolean
function GM:IsGM10() -- probably never but never say never
	return self.GamemodeVersion == 4
end