ENT.Type = "point"

ENT.DisableLargeProp = false
ENT.DisableExplosiveProp = false
ENT.DisableHealthDrop = false

function ENT:KeyValue(key, value)
	if key != "spawnflags" then return end

	local sf = tonumber( value )

	for i = 15, 0, -1 do
		local bit = math.pow( 2, i )

		if ( sf - bit ) >= 0 then
			if ( bit == 4 ) then self.DisableHealthDrop = true
			elseif ( bit == 2 ) then self.DisableExplosiveProp = true
			elseif ( bit == 1 ) then self.DisableLargeProp = true
			end

			sf = sf - bit
		else
			if ( bit == 4 ) then self.DisableHealthDrop = false
			elseif ( bit == 2 ) then self.DisableExplosiveProp = false
			elseif ( bit == 1 ) then self.DisableLargeProp = false
			end
		end
	end
end