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

function LerpColor(delta, from, to)
	local r = Lerp(delta, from.r, to.r)
	local g = Lerp(delta, from.g, to.g)
	local b = Lerp(delta, from.b, to.b)
	local a = Lerp(delta, from.a, to.a)

	return Color(r, g, b, a)
end

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

function GM:IsGM9()
	return self.GamemodeVersion == 1
end

function GM:IsSourcemod()
	return self.GamemodeVersion == 2
end

function GM:IsFretta()
	return self.GamemodeVersion == 3
end

function GM:IsGM10() -- probably never but never say never
	return self.GamemodeVersion == 4
end