local PLAYER = FindMetaTable("Player")

function PLAYER:SetDeliveries(num)
	self:SetNWInt("910_Deliveries", num)
end

function PLAYER:GetDeliveries()
	return self:GetNWInt("910_Deliveries", 0)
end

function PLAYER:AddDeliveries(num)
	self:SetDeliveries(self:GetDeliveries() + 1)
end

function PLAYER:SetSteals(num)
	self:SetNWInt("910_Steals", num)
end

function PLAYER:GetSteals()
	return self:GetNWInt("910_Steals", 0)
end

function PLAYER:AddSteals(num)
	self:SetSteals(self:GetSteals() + 1)
end