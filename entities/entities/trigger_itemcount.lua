ENT.Base = "base_brush"
ENT.Type = "brush"

-- literally only used in testmap because garry is fucked up

ENT.TeamID = 0

if SERVER then
	function ENT:Initialize()
		self:SetSolid(SOLID_BBOX)
	end

	function ENT:KeyValue(k, v)
		if k == "team" then
			self.TeamID = tonumber(v) + 1
		end
	end

	function ENT:StartTouch(entity)
		if !entity:GetClass():find("prop_physics") then return end
		GAMEMODE:EntityTouch(entity, self.TeamID, true)
	end

	function ENT:EndTouch(entity)
		if !entity:GetClass():find("prop_physics") then return end
		GAMEMODE:EntityTouch(entity, self.TeamID, false)
	end
end