ENT.Base = "base_brush"
ENT.Type = "brush"

-- used in fretta maps

if SERVER then
	function ENT:Initialize()
		self:SetSolid(SOLID_BBOX)
	end

	function ENT:StartTouch(entity)
		if !entity:GetClass():find("prop_physics") then return end
		GAMEMODE:EntityTouch(entity, 1, true)
	end

	function ENT:EndTouch(entity)
		if !entity:GetClass():find("prop_physics") then return end
		GAMEMODE:EntityTouch(entity, 1, false)
	end
end