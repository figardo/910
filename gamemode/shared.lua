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