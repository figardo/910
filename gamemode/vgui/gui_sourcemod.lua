local Color = Color
local vgui_Create = vgui.Create
local LocalPlayer = LocalPlayer
local team_GetName = team.GetName
local language_GetPhrase = language.GetPhrase
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local CurTime = CurTime
local hook_Run = hook.Run
local timer_Exists = timer.Exists
local timer_Remove = timer.Remove
local timer_Create = timer.Create
local Sound = Sound
local math_ceil = math.ceil
local GetGlobalFloat = GetGlobalFloat
local string_FormattedTime = string.FormattedTime
local surface_PlaySound = surface.PlaySound
local Lerp = Lerp
local ScrW = ScrW
local ScrH = ScrH
local FrameTime = FrameTime
local team_GetAllTeams = team.GetAllTeams
local string_format = string.format
local team_GetColor = team.GetColor
local timer_Simple = timer.Simple

SOURCEMOD = {}

local RoundedBox = draw.RoundedBox

local boxCol = Color(0, 0, 0, 102)

function SOURCEMOD:CreateExtraPanel(x, y)
	local pnl = vgui_Create("DPanel")
	pnl:SetSize(x * 0.195, y * 0.222)
	pnl.Paint = nil

	return pnl
end

local teamColours = {
	["#NineTenths.BlueTeam"] = Color(255, 255, 255),
	["#NineTenths.YellowTeam"] = Color(255, 255, 98),
	["#NineTenths.RedTeam"] = Color(255, 182, 183),
	["#NineTenths.GreenTeam"] = Color(103, 255, 89),
	[TEAM_SPECTATOR] = Color(229, 229, 229),
	[TEAM_UNASSIGNED] = Color(229, 229, 229)
}

function SOURCEMOD:CreateTeamPanel(parent, x, y)
	local x1, y1 = x * 0.009, y * 0.02
	local x2, y2 = x * 0.118, y * 0.0243

	local ply = LocalPlayer()
	local plyTeam = ply:Team()
	local teamStr = team_GetName(plyTeam)
	local teamColour = teamColours[teamStr]

	local pnl = vgui_Create("DPanel", parent)
	pnl:SetPos(x1, y1)
	pnl:SetSize(x2, y2)

	pnl.Paint = function(s, w, h)
		RoundedBox(8, 0, 0, w, h, boxCol)
	end

	pnl.Think = function(s)
		if ply:Team() == plyTeam then return end

		s:Remove()
	end

	local displayStr = language_GetPhrase("NineTenths.Team") .. ": " .. language_GetPhrase(teamStr)
	surface_SetFont("LegacyDefault")
	local textX, textY = surface_GetTextSize(displayStr)

	local text = vgui_Create("DLabel", pnl)
	text:SetFont("LegacyDefault")
	text:SetPos((x2 / 2) - (textX / 2), (y2 / 2) - (textY / 2))
	text:SetText(displayStr)
	text:SetColor(teamColour)
	text:SizeToContents()

	return pnl
end

local scoreColours = {
	["#NineTenths.BlueTeam"] = Color(59, 103, 225),
	["#NineTenths.YellowTeam"] = Color(252, 252, 15),
	["#NineTenths.RedTeam"] = Color(222, 60, 62),
	["#NineTenths.GreenTeam"] = Color(56, 255, 38)
}

local function WPaint(pnl, startTime, originalCol)
	local delta = CurTime() - startTime

	if delta <= 0.1 then
		pnl:SetColor(originalCol:Lerp(color_white, delta * 10))
	elseif delta <= 0.7 then
		local lerpDelta = (delta - 0.1) * (5 / 3)

		pnl:SetColor(color_white:Lerp(originalCol, lerpDelta))
	else
		pnl:SetColor(originalCol)
	end
end

local yellow = Color(255, 255, 0)
local red = Color(255, 0, 0)
local orange = Color(255, 153, 0)

local function LPaint(pnl, startTime, originalCol)
	local delta = CurTime() - startTime

	if delta <= 0.1 then
		pnl:SetColor(yellow)
	elseif delta <= 0.2 then
		pnl:SetColor(red)
	elseif delta <= 0.25 then
		pnl:SetColor(orange)
	else
		pnl:SetColor(originalCol)
	end
end

function SOURCEMOD:CreateScorePanel(parent, x, y)
	if hook_Run("910_DrawScores", GAMEMODE.ItemCount) then return end

	local x1, y1 = x * 0.0152, y * 0.0472
	local x2, y2 = x * 0.1953, y * 0.1944

	local pnl = vgui_Create("DPanel", parent)
	pnl:SetPos(x1, y1)
	pnl:SetSize(x2, y2)

	pnl.Paint = nil

	surface_SetFont("SourcemodScore")

	if !self.ScorePanels then self.ScorePanels = {} end

	local currentTeamID = GAMEMODE.CurrentTeamID
	if !currentTeamID then return nil end

	for i = 1, currentTeamID do
		self.ScorePanels[i] = vgui_Create("DLabel", pnl)
		self.ScorePanels[i]:SetFont("SourcemodScore")

		local currentScore = GAMEMODE.ItemCount[i] or 0
		self.ScorePanels[i]:SetText(currentScore)

		local curTeam = team_GetName(i)
		local col = scoreColours[curTeam]

		self.ScorePanels[i]:SetColor(col)
		self.ScorePanels[i]:SetPos((i - 1) * (x * 0.0492), 0)
		self.ScorePanels[i]:SizeToContents()

		self.ScorePanels[i].Think = function(s)
			local newScore = GAMEMODE.ItemCount[i]

			if currentScore == newScore then return end

			local startTime = CurTime()

			if timer_Exists("910_UpdatePaint") then timer_Remove("910_UpdatePaint") end

			-- this is dumb but much nicer than hooking into hudpaint
			if currentScore < newScore then
				s.Paint = function() WPaint(s, startTime, col) end

				timer_Create("910_UpdatePaint", 0.8, 1, function()
					s:SetColor(col)
					s.Paint = nil
				end)
			else
				s.Paint = function() LPaint(s, startTime, col) end

				timer_Create("910_UpdatePaint", 0.3, 1, function()
					s:SetColor(col)
					s.Paint = nil
				end)
			end

			s:SetText(newScore)
			currentScore = newScore

			s:SizeToContents()
		end
	end

	return pnl
end

local white = color_white
local function WarningPaint(pnl, startTime)
	local delta = CurTime() - startTime

	local colour = white

	if delta <= 0.05 then
		colour = red
	elseif delta <= 0.1 then
		colour = white
	elseif delta <= 0.15 then
		colour = red
	elseif delta <= 0.3 then
		colour = white
	elseif delta <= 0.8 then
		colour = red:Lerp(white, (delta - 0.3) * 2)
	end

	pnl:SetColor(colour)
end

local green = Color(21, 166, 15)
local function SuddenDeathPaint(pnl, startTime)
	local delta = CurTime() - startTime

	local colour = green

	if delta <= 0.5 then
		colour = white:Lerp(green, delta * 2)
	end

	pnl:SetColor(colour)
end

local tenSecondWarning = Sound("ambient/alarms/klaxon1.wav")
function SOURCEMOD:CreateTimerPanel(parent, x, y)
	local iTimeLeft = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
	if iTimeLeft < 0 then iTimeLeft = 0 end

	if hook_Run("910_DrawTimer", iTimeLeft) then return end

	local width, height = x * 0.1171, y * 0.0833

	local pnl = vgui_Create("DPanel")
	pnl:SetPos(x * 0.00937, y * 0.1333)
	pnl:SetSize(width, height)
	pnl:ParentToHUD()

	pnl.Paint = function(s, w, h)
		RoundedBox(8, 0, 0, w, h, boxCol)
	end

	local text = vgui_Create("DLabel", pnl)
	text:SetSize(width, height)
	text:SetFont("SourcemodTime")

	local TimerText = string_FormattedTime(iTimeLeft, "%01i:%02i")

	text:SetText(TimerText)

	surface_SetFont("SourcemodTime")
	local textX = surface_GetTextSize(TimerText)

	text:SetPos((width / 2) - (textX / 2), -(y * 0.0034))

	text.Think = function(s)
		local newTime = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
		if newTime < 0 then newTime = 0 end

		if iTimeLeft == newTime then return end

		TimerText = string_FormattedTime(newTime, "%01i:%02i")

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

		surface_SetFont("SourcemodTime")
		textX = surface_GetTextSize(TimerText)
		s:SetPos((width / 2) - (textX / 2), -(y * 0.0034))

		s:SetText(TimerText)
		iTimeLeft = newTime
	end

	return pnl
end

local winSound = Sound("ambient/alarms/apc_alarm_pass1.wav")
local drawColour = Color(213, 114, 202, 200)

local winDelta = 0

local function ScoreAnimation(pnl, x, y, duration, teamcount) -- kill me now
	local x1, y1, x2, y2 = x * 0.3225, y * 0.1875, x * 0.41, y * 0.0833

	local ymult = 1
	if teamcount > 2 then
		ymult = 2
	end

	y2 = y2 * ymult

	if winDelta <= 0.25 then
		local thisDelta = winDelta * 4

		y1 = 0
		x2 = 6
		y2 = Lerp(thisDelta, 6, y * 0.19166)
	elseif winDelta < 0.3 then
		y1 = 0
		x2 = 6
		y2 = y * 0.19166
	elseif winDelta <= 0.5 then
		local thisDelta = (winDelta - 0.3) / 0.2

		y1 = Lerp(thisDelta, 0, y * 0.1875)
		x2 = 6
		y2 = y * 0.19166 - y1
	elseif winDelta < 0.6 then
		x2 = 6
		y2 = 6
	elseif winDelta <= 0.9 then
		local thisDelta = (winDelta - 0.6) / 0.3

		x2 = Lerp(thisDelta, 6, x * 0.41)
		y2 = 6
	elseif winDelta <= 1.2 then
		local thisDelta = (winDelta - 0.9) / 0.3

		y2 = Lerp(thisDelta, 6, y * 0.0833 * ymult)
	elseif duration - winDelta <= 8 / 60 then
		x1 = 0
		y1 = 0
		x2 = 0
		y2 = 0
	elseif duration - winDelta <= 20.5 / 60 then
		local thisDelta = (duration - winDelta - (8 / 60)) / (12.5 / 60)

		x1 = x * 0.73
		x2 = 6
		y1 = Lerp(thisDelta, y, y * 0.266666)
		y2 = y
	elseif duration - winDelta <= 29 / 60 then
		local thisDelta = (duration - winDelta - (20.5 / 60)) / (8.5 / 60)

		x1 = x * 0.73
		x2 = 6
		y1 = ((y * 0.1875) + (y * (0.0833 * ymult))) - 6
		y2 = Lerp(thisDelta, y, y * 0.271 - y1)
	elseif duration - winDelta <= 32 / 60 then
		x1 = x * 0.73
		x2 = 6
		y1 = ((y * 0.1875) + (y * (0.0833 * ymult))) - 6
		y2 = y * 0.271 - y1
	elseif duration - winDelta <= 44 / 60 then
		local thisDelta = (duration - winDelta - (32 / 60)) / (12 / 60)

		x1 = Lerp(thisDelta, x * 0.73, x * 0.3225)
		x2 = x * 0.7325 - x1
		y1 = ((y * 0.1875) + (y * (0.0833 * ymult))) - 6
		y2 = y * 0.271 - y1
	elseif duration - winDelta <= 1 then
		local thisDelta = (duration - winDelta - (44 / 60)) / (16 / 60)

		local y1start = y * 0.1875
		local y1end = y1start + (y * (0.0833 * ymult))

		y1 = Lerp(thisDelta, y1end - 6, y1start)
		y2 = y1end - y1
	end

	pnl:SetPos(x1, y1)
	pnl:SetSize(x2, y2)

	RoundedBox(8, 0, 0, x2, y2, color_white)
end

local trWhite = Color(255, 255, 255, 200)
local black = Color(0, 0, 0)
function SOURCEMOD:CreateWinScreen(winnercount, winners, duration)
	local gm = GAMEMODE
	winDelta = 0

	local x, y = ScrW(), ScrH()

	local offscreen = -y * 0.1

	local top = gm.ExtraPanel
	local topX, topY = top:GetPos()
	top:MoveTo(topX, offscreen, 0.5, 1)
	top:AlphaTo(0, 1, 1)
	top.Think = function(s)
		if winDelta >= duration then
			s:MoveTo(topX, topY, 1)
			s:AlphaTo(255, 1)
			s.Think = nil
		end
	end

	local time = gm.TimerPanel
	local timeX, timeY = time:GetPos()
	time:MoveTo(offscreen, timeY, 1, 1.5)
	time:AlphaTo(0, 1, 1.5)
	time.Think = function(s)
		winDelta = winDelta + FrameTime() -- this is the last panel to move so we'll do it here

		if winDelta >= duration + 0.5 then
			s:MoveTo(timeX, timeY, 1)
			s:AlphaTo(255, 1)
			s.Think = nil
		end
	end

	local bgWidth = x * 0.75

	local background = vgui_Create("DPanel")
	background:ParentToHUD()
	background:SetSize(bgWidth, y)
	background:SetBackgroundColor(Color(255, 255, 255, 15))
	background:SetAlpha(0)
	background:AlphaTo(255, 0.25)
	background.Think = function(s)
		if winDelta >= duration - 0.1 then
			s:AlphaTo(0, 0.1, 0, function(_, pnl) pnl:Remove() end)
			s.Think = nil
		end
	end

	local text
	local col

	if winnercount < #team_GetAllTeams() then
		local winner = winners[1] -- TEMPORARY!!!!!

		local wintext = string_format(language_GetPhrase("NineTenths.TeamWin"), language_GetPhrase(team_GetName(winner)))

		text = utf8upper(wintext)
		col = team_GetColor(winner)
		col.a = 200
	else
		text = utf8upper(language_GetPhrase("NineTenths.Draw"))
		col = drawColour
	end

	surface_SetFont("SourcemodWin")
	local wintextX = surface_GetTextSize(text)

	local winW = x * 0.4574
	if wintextX > x * 0.4 then
		winW = wintextX + (x * 0.05)
	end

	local wbgY = y * 0.0625
	local wbgH = y * 0.102

	local winnerBackground = vgui_Create("DPanel", background)
	winnerBackground:SetPos(bgWidth, wbgY)
	winnerBackground:SetSize(x, wbgH)
	winnerBackground:MoveTo(bgWidth - winW, wbgY, 1, 0.05, 1)

	winnerBackground.Think = function(s)
		if winDelta >= duration - (47 / 60) then
			s:MoveTo(bgWidth, wbgY, 40 / 60)
			s:AlphaTo(0, 40 / 60)
			s.Think = nil
		end
	end

	winnerBackground.Paint = function(s, w, h)
		RoundedBox(8, 0, 0, w, h, col)
	end

	local winnerText = vgui_Create("DLabel", winnerBackground)
	winnerText:SetColor(trWhite)
	winnerText:SetPos(x * 0.0109, -1)
	winnerText:SetFont("SourcemodWin")
	winnerText:SetSize(x, wbgH)

	winnerText:SetText(text)

	local teamcount = #team_GetAllTeams()

	local scoreBackground = vgui_Create("DPanel", background)
	scoreBackground:SetPos(x * 0.3225, 0)
	scoreBackground:SetSize(6, 6)
	scoreBackground.Paint = function(s) ScoreAnimation(s, x, y, duration, teamcount) end
	scoreBackground.Think = function(s)
		if winDelta < 31 / 60 then return end

		surface_SetFont("SourcemodWinScores")

		local midpoint = x * 0.205
		local padding = x * 0.05575
		local txts = {}

		for i = 1, teamcount do
			local txt = language_GetPhrase(team_GetName(i)) .. ": " .. GAMEMODE.ItemCount[i]
			local txtX = surface_GetTextSize(txt)
			txts[i] = {t = txt, x = txtX}

			if txtX + padding >= midpoint then
				local diff = txtX + padding - midpoint
				padding = padding - diff
			end
		end

		for i = 1, teamcount do
			local scoreX = i % 2 == 0 and x * 0.41 - padding - txts[i].x or padding
			local scoreY = i > 2 and y * 0.075 or y * 0.001

			local scoreText = vgui_Create("DLabel", s)
			scoreText:SetPos(scoreX, scoreY)
			scoreText:SetSize(x * 0.41, y * 0.0833)
			scoreText:SetText(txts[i].t)
			scoreText:SetColor(black)
			scoreText:SetFont("SourcemodWinScores")

			scoreText:SetAlpha(0)
			scoreText:AlphaTo(255, 0.1)
			scoreText.Think = function(sctxt)
				if winDelta >= duration - (54 / 60) then
					sctxt:AlphaTo(0, 0.1, 0, function(_, pnl) pnl:Remove() end)
					sctxt.Think = nil
				end
			end
		end

		s.Think = nil
	end

	timer_Simple(duration, function()
		winnerBackground:Remove()
		scoreBackground:Remove()
	end)

	surface_PlaySound(winSound)
end