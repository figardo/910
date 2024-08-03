local Color = Color
local Material = Material
local CurTime = CurTime
local hook_Run = hook.Run
local vgui_Create = vgui.Create
local math_Clamp = math.Clamp
local draw_RoundedBox = draw.RoundedBox
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local team_GetColor = team.GetColor
local language_GetPhrase = language.GetPhrase
local team_GetName = team.GetName
local timer_Exists = timer.Exists
local timer_Remove = timer.Remove
local timer_Create = timer.Create
local LocalPlayer = LocalPlayer
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local Sound = Sound
local math_ceil = math.ceil
local GetGlobalFloat = GetGlobalFloat
local string_FormattedTime = string.FormattedTime
local surface_PlaySound = surface.PlaySound
local ScrW = ScrW
local ScrH = ScrH
local team_GetAllTeams = team.GetAllTeams
local string_format = string.format

GM9 = {}

local boxCol = Color(0, 0, 0, 102)

local scoreMaterial = Material("gmod/gm_910/scores_new")

local function UpdatePaint(pnl, startTime, originalColour)
	local delta = CurTime() - startTime

	pnl:SetColor(color_white:Lerp(originalColour, delta))
end

function GM9:CreateScorePanel(parent, x, y)
	if hook_Run("910_DrawScores", GAMEMODE.ItemCount) then return end

	local pnl = vgui_Create("DPanel")
	pnl:ParentToHUD()
	pnl:SetPos(x * 0.02, y * 0.0194)
	pnl:SetSize(x * 0.195, y * 0.2)

	pnl.Paint = nil

	local currentTeamID = GAMEMODE.CurrentTeamID
	if !currentTeamID then return nil end

	local extra = math_Clamp(currentTeamID - 2, 0, 6)
	local bgW, bgH = x * 0.17265625, y * (0.11597 + (extra * 0.02))

	local background = vgui_Create("DPanel", pnl)
	background:SetPos(x * 0.015625, y * 0.02361)
	background:SetSize(bgW, bgH)
	background.Paint = function(s, w, h)
		draw_RoundedBox(16, 0, 0, w, h, boxCol)
	end

	local matPnl = vgui_Create("DPanel", pnl)
	matPnl:SetPos(0, 0)
	matPnl:SetSize(x * 0.2, y * 0.24)
	matPnl.Paint = function(s, w, h)
		surface_SetDrawColor(255, 255, 255)
		surface_SetMaterial(scoreMaterial)
		s:DrawTexturedRect()
	end

	if !self.ScorePanels then self.ScorePanels = {} end

	for i = 1, currentTeamID do
		local scoreParent = vgui_Create("DPanel", pnl)

		local h = y * (0.054861 + (0.03 * (i - 1)))
		scoreParent:SetPos(x * 0.03, h)
		scoreParent:SetSize(x * 0.171875, y * 0.02777)

		scoreParent.Paint = nil

		local teamLabel = vgui_Create("DLabel", scoreParent)
		teamLabel:SetFont("DefaultShadow")

		local col = team_GetColor(i)
		teamLabel:SetColor(col)

		local txt = language_GetPhrase(team_GetName(i)) .. ":"
		teamLabel:SetText(txt)

		teamLabel:SizeToContents()

		self.ScorePanels[i] = vgui_Create("DLabel", scoreParent)
		self.ScorePanels[i]:SetPos(x * 0.1296875, 0)
		self.ScorePanels[i]:SetFont("DefaultShadow")
		self.ScorePanels[i]:SetColor(col)

		local currentScore = GAMEMODE.ItemCount[i] or 0
		self.ScorePanels[i]:SetText(currentScore)

		self.ScorePanels[i]:SizeToContents()

		self.ScorePanels[i].Think = function(s)
			local newScore = GAMEMODE.ItemCount[i]

			if currentScore == newScore then return end

			local startTime = CurTime()

			if timer_Exists("910_UpdatePaint") then timer_Remove("910_UpdatePaint") end

			s.Paint = function() UpdatePaint(s, startTime, col) end

			timer_Create("910_UpdatePaint", 1, 1, function()
				s:SetColor(col)
				s.Paint = nil
			end)

			s:SetText(newScore)
			currentScore = newScore

			s:SizeToContents()
		end
	end

	return pnl
end

local gm9TeamCols = {
	["#NineTenths.BlueTeam"] = Color(217, 255, 255),
	["#NineTenths.YellowTeam"] = Color(255, 255, 98),
	["#NineTenths.RedTeam"] = Color(255, 153, 159),
	["#NineTenths.GreenTeam"] = Color(103, 255, 89),
	[TEAM_SPECTATOR] = Color(229, 229, 229),
	[TEAM_UNASSIGNED] = Color(229, 229, 229)
}

function GM9:CreateTeamPanel(parent, x, y)
	local ply = LocalPlayer()
	local plyTeam = ply:Team()
	local teamStr = team_GetName(plyTeam)
	local teamColour = gm9TeamCols[teamStr]

	local x1, y1 = x * 0.01875, y * 0.86458

	surface_SetFont("LegacyDefault")
	local textX = surface_GetTextSize(teamStr)

	local x2, y2 = textX + (x * 0.0195), y * 0.03263

	local pnl = vgui_Create("DPanel")
	pnl:ParentToHUD()
	pnl:SetPos(x1, y1)
	pnl:SetSize(x2, y2)
	pnl.Paint = function(s, w, h)
		draw_RoundedBox(8, 0, 0, w, h, boxCol)
	end

	local text = vgui_Create("DLabel", pnl)
	text:SetPos((x2 / 2) - (textX / 2), 0)
	text:SetSize(x2, y2)
	text:SetFont("LegacyDefault")
	text:SetColor(teamColour)
	text:SetText(teamStr)
	text:SizeToContentsX()

	text.Think = function(s)
		local newTeam = ply:Team()

		if newTeam == plyTeam then return end

		local newTeamStr = team_GetName(newTeam)
		local newTeamColour = gm9TeamCols[newTeamStr]

		s:SetText(newTeamStr)
		s:SetColor(newTeamColour)

		plyTeam = newTeam

		surface_SetFont("LegacyDefault")

		local pnlWidth = surface_GetTextSize(newTeamStr) + (x * 0.0195)

		pnl:SetSize(pnlWidth, y2)
		s:SizeToContentsX()
	end

	return pnl
end

local white = color_white
local green = Color(21, 166, 15)
local function SuddenDeathPaint(pnl, startTime)
	local delta = CurTime() - startTime

	local colour = green

	if delta <= 0.5 then
		colour = white:Lerp(green, delta * 2)
	end

	pnl:SetColor(colour)
end

local red = Color(255, 0, 0)
local function WarningPaint(pnl, startTime)
	local delta = CurTime() - startTime

	local colour = white

	if delta <= 1 then
		colour = red:Lerp(white, delta)
	end

	pnl:SetColor(colour)
end

local mTime = Material("gmod/gm_910/time")
local tenSecondWarning = Sound("ambient/alarms/klaxon1.wav")
function GM9:CreateTimerPanel(parent, x, y)
	local iTimeLeft = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
	if iTimeLeft < 0 then iTimeLeft = 0 end

	if hook_Run("910_DrawTimer", iTimeLeft) then return end

	local currentTeamID = GAMEMODE.CurrentTeamID
	if !currentTeamID then return nil end

	local extra = math_Clamp(currentTeamID - 2, 0, 6)

	local width, height = x * 0.2, y * 0.12

	local pnl = vgui_Create("DPanel")
	pnl:SetPos(x * 0.02, y * (0.16 + (extra * 0.02)))
	pnl:SetSize(width, height)
	pnl:ParentToHUD()

	pnl.Paint = function(s)
		surface_SetDrawColor(255, 255, 255)
		surface_SetMaterial(mTime)
		s:DrawTexturedRect()
	end

	local text = vgui_Create("DLabel", pnl)
	text:SetSize(x * 0.03125, y * 0.0275)
	text:SetPos(x * 0.13, y * 0.0291)
	text:SetFont("DefaultShadow")

	local TimerText = string_FormattedTime(iTimeLeft - 1, "%01i:%02i")

	text:SetText(TimerText)

	text.Think = function(s)
		local newTime = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
		if newTime < 0 then newTime = 0 end

		if iTimeLeft == newTime then return end

		TimerText = newTime == 0 and newTime or newTime - 1
		TimerText = string_FormattedTime(TimerText, "%01i:%02i")

		local suddenDeath = GAMEMODE:GetSuddenDeath()
		if (suddenDeath or newTime <= 10) and newTime != 0 then
			surface_PlaySound(tenSecondWarning)

			if timer_Exists("910_WarningPaint") then timer_Remove("910_WarningPaint") end

			local startTime = CurTime()

			if suddenDeath then
				s.Paint = function() SuddenDeathPaint(s, startTime) end

				timer_Create("910_WarningPaint", 1.1, 1, function()
					s.Paint = nil
					s:SetColor(white)
				end)
			else
				s.Paint = function() WarningPaint(s, startTime) end

				timer_Create("910_WarningPaint", 0.9, 1, function()
					s.Paint = nil
					s:SetColor(white)
				end)
			end
		else
			s.Paint = nil
		end

		s:SetText(TimerText)
		iTimeLeft = newTime
	end

	return pnl
end

-- show winner..
-- todo: use textures for these to make it cooler
local drawCol = Color(200, 200, 200)
local bgCol = Color(0, 0, 0, 150)

local winSound = Sound("ambient/voices/playground_memory.wav")

function GM9:CreateWinScreen(winnercount, winners, duration)
	local x = ScrW()
	local y = ScrH()

	local background = vgui_Create("DPanel")
	background:SetSize(x, y)
	background:SetBackgroundColor(bgCol)
	background:SetAlpha(0)

	surface_SetFont("ImpactMassive")

	if winnercount < #team_GetAllTeams() then
		for i = 1, winnercount do
			local winner = winners[i]
			local text = string_format(language_GetPhrase("NineTenths.TeamWin"), language_GetPhrase(team_GetName(winner)))

			local w, h = surface_GetTextSize(text)
			local pnlx = (x / 2) - (w / 2)
			local pnly = (y / 2) - (h / 2) + ((i - 1) * h)

			local lbl = vgui_Create("DLabel", background)
			lbl:SetColor(team_GetColor(winner))
			lbl:SetPos(pnlx, pnly)
			lbl:SetSize(w, h)
			lbl:SetFont("ImpactMassive")
			lbl:SetText(text)
		end
	else
		local text = "#NineTenths.Draw"
		local w, h = surface_GetTextSize(text)

		local lbl = vgui_Create("DLabel", background)
		lbl:SetColor(drawCol)
		lbl:SetPos((x / 2) - (w / 2), (y / 2) - (h / 2))
		lbl:SetSize(w, h)
		lbl:SetFont("ImpactMassive")
		lbl:SetText(text)
	end

	background:AlphaTo(255, 0.1)

	surface_PlaySound(winSound)

	background:AlphaTo(0, 1, duration, function(_, pnl) pnl:Remove() end)
end