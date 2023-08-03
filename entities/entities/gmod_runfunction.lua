-- used in gm9 maps

ENT.Type = "point"

AccessorFunc( ENT, "m_bCheckFunc", "CheckFunc" )

function ENT:Initialize()
end

function ENT:KeyValue( key, value )
	if ( key == "FunctionName" ) then
		self:SetCheckFunc(value)
	end
end

function ENT:SetupGlobals( activator, caller )
	ACTIVATOR = activator
	CALLER = caller

	if ( IsValid( activator ) && activator:IsPlayer() ) then
		TRIGGER_PLAYER = activator
	end
end

function ENT:KillGlobals()
	ACTIVATOR = nil
	CALLER = nil
	TRIGGER_PLAYER = nil
end

function ENT:RunCode(activator, caller, code, int)
	self:SetupGlobals( activator, caller )

	RunString( code .. "(" .. int .. ")", "gmod_runfunction#" .. self:EntIndex())

	self:KillGlobals()
end

function ENT:AcceptInput( name, activator, caller, data )
	if ( name == "RunScriptInteger" ) then self:RunCode(activator, caller, self:GetCheckFunc(), data) return true end

	return false
end