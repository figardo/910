local Color = Color
local ScrW = ScrW
local ScrH = ScrH
local vgui_Create = vgui.Create
local draw_RoundedBox = draw.RoundedBox
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local GetHostName = GetHostName

local scoreboardPnl

local cornerRadius = 8
local roughness = 2
local thickness = 1

local boxCol = Color(0, 0, 0, 100)
local lineR, lineG, lineB, lineA = 255, 255, 0, 100
local yellow = Color(255, 229, 55)
local orange = Color(255, 177, 0)

local selfCol = 125

local stats = {
	{title = "#NineTenths.Score", fn = function(ply) return ply:Frags() end},
	{title = "Objects", fn = function(ply) return ply:GetDeliveries() end},
	{title = "Steals", fn = function(ply) return ply:GetSteals() end},
	{title = "Deaths", fn = function(ply) return ply:Deaths() end},
	{title = "Latency", fn = function(ply) return ply:Ping() end}
}

local teamColours = {
	["#NineTenths.BlueTeam"] = Color(255, 255, 255),
	["#NineTenths.YellowTeam"] = Color(255, 255, 98),
	["#NineTenths.RedTeam"] = Color(255, 182, 183),
	["#NineTenths.GreenTeam"] = Color(103, 255, 89),
	[TEAM_SPECTATOR] = Color(229, 229, 229),
	[TEAM_UNASSIGNED] = Color(229, 229, 229)
}

local function CreatePlayerPanel(parent, ply, teamID)
	local isSelf = ply == LocalPlayer()

	local height = ScrH() * 0.027

	local plyPnl = parent:Add("DPanel")
	plyPnl:Dock(TOP)
	plyPnl:DockMargin(6, 1, 0, 0)
	plyPnl:SetTall(height)

	if isSelf then
		plyPnl.Paint = function(s, w, h)
			surface.SetDrawColor(selfCol, selfCol, selfCol, lineA)
			surface.DrawRect(0, 0, w - 6, h)
		end
	else
		plyPnl.Paint = nil
	end

	local font = isSelf and "LegacyDefault" or "LegacyDefaultThin"
	local colour = teamColours[team.GetName(teamID)]

	local textPnl = vgui.Create("DLabel", plyPnl)
	textPnl:SetText(ply:Nick())
	textPnl:SetFont(font)
	textPnl:SetColor(colour)

	textPnl:SizeToContentsX()
	textPnl:Dock(LEFT)
	textPnl:DockMargin(13, 0, 0, 0)

	local plyStats = vgui_Create("DPanel", plyPnl)
	plyStats:Dock(RIGHT)
	plyStats.Paint = nil

	plyStats.PerformLayout = function(s)
		local half = plyPnl:GetWide() / 2
		s:SetX(half)
		s:SetWide(half)
	end

	for i = 1, #stats do
		local curVal = stats[i].fn(ply)

		local statLabel = vgui_Create("DLabel", plyStats)
		statLabel:SetFont(font)
		statLabel:SetColor(colour)
		statLabel:SetText(curVal)

		statLabel:Dock(LEFT)
		statLabel:DockMargin(90, 0, 10, 0)
		statLabel:SizeToContentsX()

		statLabel.Think = function(s)
			local newVal = stats[i].fn(ply)

			if curVal == newVal then return end

			s:SetText(newVal)
			curVal = newVal
			s:SizeToContentsX()
		end
	end

	return height
end

local function CreatePlayerList(parent, id, plys)
	local plyList = parent:Add("DScrollPanel")
	plyList:Dock(TOP)
	plyList:DockMargin(0, 0, 0, 16)

	local vbar = plyList:GetVBar()
	vbar:SetWide(0)
	vbar:Hide()

	local height = 0

	for i = 1, #plys do
		local ply = plys[i]

		height = height + CreatePlayerPanel(plyList, ply, id)
	end

	plyList:SetTall(height)

	plyList:GetCanvas():SizeToChildren()
end

function GM:CreateTeamPanel(parent, id)
	local colour = team.GetColor(id)
	local plys = team.GetPlayers(id)

	local teamPnl = parent:Add("DPanel")
	teamPnl:SetWide(ScrW() / 2)
	teamPnl:Dock(TOP)
	teamPnl.Paint = function(s, w, h)
		local r, g, b = colour:Unpack()

		surface_SetDrawColor(r, g, b)
		surface_DrawLine(7, h - 1, w - 7, h - 1)
	end

	local txt = language.GetPhrase(team.GetName(id)) .. "   -   " .. #plys .. " players"

	local textPnl = vgui.Create("DLabel", teamPnl)
	textPnl:SetText(txt)
	textPnl:SetColor(colour)
	textPnl:SetFont("LegacyDefaultThin")
	textPnl:SizeToContents()

	textPnl:Dock(LEFT)
	textPnl:DockMargin(8, 0, 0, 0)

	local teamStats = vgui_Create("DPanel", teamPnl)
	teamStats:Dock(RIGHT)
	teamStats.Paint = nil

	teamStats.PerformLayout = function(s)
		local half = teamPnl:GetWide() / 2
		s:SetX(half)
		s:SetWide(half)
	end

	local teamScore = team.GetScore(id)

	local scoreLabel = vgui_Create("DLabel", teamStats)
	scoreLabel:SetFont("LegacyDefaultThin")
	scoreLabel:SetColor(colour)
	scoreLabel:SetText(teamScore)

	scoreLabel:Dock(LEFT)
	scoreLabel:DockMargin(95, 0, 15, 0)
	scoreLabel:SizeToContentsX()

	scoreLabel.Think = function(s)
		local newVal = team.GetScore(id)

		if teamScore == newVal then return end

		s:SetText(newVal)
		teamScore = newVal
		s:SizeToContentsX()
	end

	local teamObjects = self.ItemCount[id]

	local objectsLabel = vgui_Create("DLabel", teamStats)
	objectsLabel:SetFont("LegacyDefaultThin")
	objectsLabel:SetColor(colour)
	objectsLabel:SetText(teamObjects)

	objectsLabel:Dock(LEFT)
	objectsLabel:DockMargin(95, 0, 15, 0)
	objectsLabel:SizeToContentsX()

	objectsLabel.Think = function(s)
		local newVal = self.ItemCount[id]

		if teamObjects == newVal then return end

		s:SetText(newVal)
		teamObjects = newVal
		s:SizeToContentsX()
	end

	CreatePlayerList(parent, id, plys)
end

function GM:ScoreboardShow()
	local x = ScrW()
	local y = ScrH()

	scoreboardPnl = vgui_Create("DPanel")
	scoreboardPnl:ParentToHUD()
	scoreboardPnl:SetSize(x / 2, y)
	scoreboardPnl:Center()
	scoreboardPnl.Paint = nil

	local background = vgui_Create("DPanel", scoreboardPnl)
	background:SetSize(scoreboardPnl:GetWide(), y / 1.5)

	background.Paint = function(s, w, h)
		local cr = cornerRadius

		draw_RoundedBox(cr, 0, 0, w, h, boxCol)

		local right = w - thickness
		local bottom = h - thickness

		local rightcr = w - cr
		local bottomcr = h - cr

		surface_SetDrawColor(lineR, lineG, lineB, lineA)

		for i = 1, 4 do
			local x1 = i > 2 and cr or (i == 2 and right or 0)
			local y1 = i > 2 and (i == 4 and bottom or 0) or cr

			local x2 = i > 2 and rightcr or (i == 2 and right or 0)
			local y2 = i > 2 and (i == 4 and bottom or 0) or bottomcr

			surface_DrawLine(x1, y1, x2, y2)
		end

		local startAng = 0
		local endAng = 90

		for i = 1, 4 do
			local cx = (i == 1 or i == 4) and rightcr or cr
			local cy = i > 2 and bottomcr or cr

			draw.Arc(cx, cy, cr, thickness, startAng, endAng, roughness)

			startAng = startAng + 90
			endAng = endAng + 90
		end
	end

	background:Center()

	local topRow = vgui_Create( "DPanel", background )
	topRow:Dock(TOP)
	topRow:SetTall(y / 40)
	topRow.Paint = function(s, w, h)
		surface_SetDrawColor(0, 0, 0)
		surface_DrawLine(7, h - 1, w - 7, h - 1)
	end

	local topLabel = vgui_Create("DLabel", topRow)
	topLabel:Dock(LEFT)
	topLabel:SetFont("LegacyDefault")
	topLabel:SetColor(yellow)
	topLabel:SetText(GetHostName())
	topLabel:DockMargin(12, 0, 0, 0)

	topLabel.PerformLayout = function(s)
		local half = topRow:GetWide() / 2
		s:SetX(0)
		s:SetWide(half)
	end

	local topStats = vgui_Create("DPanel", topRow)
	topStats:Dock(RIGHT)
	topStats.Paint = nil

	topStats.PerformLayout = function(s)
		local half = topRow:GetWide() / 2
		s:SetX(half)
		s:SetWide(half)
	end

	for i = 1, #stats do
		local name = stats[i].title

		local statLabel = vgui_Create("DLabel", topStats)
		statLabel:Dock(LEFT)
		statLabel:SetFont("LegacyDefaultThin")
		statLabel:SetColor(orange)
		statLabel:SetText(name)
		statLabel:DockMargin(50, 0, 0, 0)
		statLabel:SizeToContentsX()
	end

	local main = vgui.Create("DScrollPanel", background)
	main:GetVBar().Enabled = false
	main:Dock(FILL)
	main:DockMargin(0, 16, 0, 0)

	for i = 1, #self.ItemCount do
		self:CreateTeamPanel(main, i)
	end
end

function GM:ScoreboardHide()
	scoreboardPnl:Remove()
end