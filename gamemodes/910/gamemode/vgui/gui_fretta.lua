local player_GetAll = player.GetAll
local table_sort = table.sort
local vgui_Create = CLIENT and vgui.Create
local surface_SetMaterial = CLIENT and surface.SetMaterial
local surface_SetDrawColor = CLIENT and surface.SetDrawColor
local render_UpdateScreenEffectTexture = CLIENT and render.UpdateScreenEffectTexture
local surface_DrawTexturedRect = CLIENT and surface.DrawTexturedRect
local surface_DrawRect = CLIENT and surface.DrawRect
local team_GetAllTeams = team.GetAllTeams
local team_GetName = team.GetName
local string_format = string.format
local language_GetPhrase = CLIENT and language.GetPhrase
local timer_Simple = timer.Simple
local surface_PlaySound = CLIENT and surface.PlaySound
local Color = Color
local math_max = math.max
local draw_RoundedBox = draw.RoundedBox
local ScrW = ScrW
local hook_Run = hook.Run
local LocalPlayer = LocalPlayer
local math_ceil = math.ceil
local GetGlobalFloat = GetGlobalFloat
local CurTime = CurTime
local string_FormattedTime = string.FormattedTime
local Material = Material
local Sound = Sound
local ScrH = ScrH


FRETTA = {}

local boxCol = Color(0, 0, 0, 100)

local function PerformFrettaLayout(pnl, xPad, yPad, vertical)
	local w = vertical and yPad or xPad
	local tallest = 0

	local children = pnl:GetChildren()
	for i = 1, #children do
		local v = children[i]

		v:SetPos(vertical and xPad / 2 or w, vertical and w or yPad / 2)
		w = w + (vertical and v:GetTall() or v:GetWide()) + (vertical and yPad or xPad)
		tallest = math_max( tallest, vertical and v:GetWide() or v:GetTall() )
	end

	pnl:SetSize( vertical and tallest + xPad or w, vertical and w or tallest + yPad )
end

function FRETTA:CreateExtraPanel(x, y)
	local pnl = vgui_Create("DPanel")
	pnl.Paint = function(s)
		draw_RoundedBox( 4, 0, 0, s:GetWide(), s:GetTall(), boxCol )
	end

	pnl.Think = function(s)
		s:SetPos((ScrW() / 2) - (s:GetWide() / 2), y * 0.95)
	end

	local xPad, yPad = x * 0.01, y * 0.01
	pnl.PerformLayout = function(s) PerformFrettaLayout(s, xPad, yPad) end

	pnl:CenterHorizontal()

	return pnl
end

local teamColours = {
	["#NineTenths.BlueTeam"] = Color(68, 231, 254),
	["#NineTenths.YellowTeam"] = Color(255, 201, 46),
	["#NineTenths.RedTeam"] = Color(255, 0, 0),
	["#NineTenths.GreenTeam"] = Color(0, 255, 0),
	[TEAM_SPECTATOR] = Color(229, 229, 229),
	[TEAM_UNASSIGNED] = Color(229, 229, 229)
}

function FRETTA:CreateScorePanel(parent, x, y)
	if hook_Run("910_DrawScores", GAMEMODE.ItemCount) then return end

	local pnl = vgui_Create("DPanel")
	pnl:ParentToHUD()

	pnl:AlignTop()
	pnl:CenterHorizontal()

	pnl.Think = function(s)
		s:SetPos((ScrW() / 2) - (s:GetWide() / 2), y * 0.02)
	end

	pnl.Paint = function(s)
		draw_RoundedBox( 4, 0, 0, s:GetWide(), s:GetTall(), boxCol )
	end

	pnl.PerformLayout = function(s) PerformFrettaLayout(s, 0, 0, true) end

	local topHalf = vgui_Create("DPanel", pnl)
	topHalf.Paint = nil

	local xPad, yPad = x * 0.0075, y * 0.015
	topHalf.PerformLayout = function(s) PerformFrettaLayout(s, xPad, yPad) end

	local Score1 = vgui_Create("DLabel", topHalf)
	Score1:SetFont("FrettaHUDElement")

	local teamScores = GAMEMODE.ItemCount

	local firstScore = teamScores[1] or 0
	Score1:SetText(firstScore)

	Score1:SetColor(teamColours[team_GetName(1)])
	Score1:SizeToContents()

	Score1.Think = function(s)
		local newScore = teamScores[1] or 0

		if firstScore == newScore then return end

		s:SetText(newScore)
		firstScore = newScore
		s:SizeToContents()
	end

	local secondScore = teamScores[2] or 0

	local PropsText = vgui_Create("DLabel", topHalf)
	PropsText:SetFont("FrettaHUDElement")

	local scoreText =  language_GetPhrase("NineTenths.Score")

	PropsText:SizeToContents()

	local Score2 = vgui_Create("DLabel", topHalf)
	Score2:SetFont("FrettaHUDElement")

	Score2:SetText(secondScore)

	Score2:SetColor(teamColours[team_GetName(2)])
	Score2:SizeToContents()

	Score2.Think = function(s)
		local newScore = teamScores[2] or 0

		if secondScore == newScore then return end

		s:SetText(newScore)
		secondScore = newScore
		s:SizeToContents()
	end

	if GAMEMODE.CurrentTeamID > 2 then
		local bottomHalf = vgui_Create("DPanel", pnl)
		bottomHalf.Paint = nil
		bottomHalf.PerformLayout = function(s) PerformFrettaLayout(s, xPad, yPad) end

		local Score3 = vgui_Create("DLabel", bottomHalf)
		Score3:SetFont("FrettaHUDElement")

		local thirdScore = teamScores[3] or 0
		Score3:SetText(thirdScore)

		Score3:SetColor(teamColours[team_GetName(3)])
		Score3:SizeToContents()

		Score3.Think = function(s)
			local newScore = teamScores[3] or 0

			if thirdScore == newScore then return end

			s:SetText(newScore)
			thirdScore = newScore
			s:SizeToContents()
		end

		local fourthScore = teamScores[4] or 0

		local PropsText2 = vgui_Create("DLabel", bottomHalf)
		PropsText2:SetFont("FrettaHUDElement")

		PropsText2.Think = function(s)
			local max = 0
			local topteam = {}
			for t, score in ipairs(teamScores) do
				if score < max then continue end

				if score == max then
					topteam[t] = true

					continue
				end

				max = score

				topteam = {[t] = true}
			end

			local txt
			local txt2

			if table.Count(topteam) == GAMEMODE.CurrentTeamID then
				txt = "- " .. scoreText .. " -"
				txt2 = txt
			else
				local first = topteam[1] and "< " or "- "
				local second = topteam[2] and " >" or " -"
				txt = first .. scoreText .. second

				first = topteam[3] and "< " or "- "
				second = topteam[4] and " >" or " -"
				txt2 = first .. scoreText .. second
			end

			PropsText:SetText(txt)
			PropsText:SizeToContents()
			s:SetText(txt2)
			s:SizeToContents()
		end

		PropsText2:SizeToContents()

		local Score4 = vgui_Create("DLabel", bottomHalf)
		Score4:SetFont("FrettaHUDElement")

		Score4:SetText(fourthScore)

		Score4:SetColor(teamColours[team_GetName(4)])
		Score4:SizeToContents()

		Score4.Think = function(s)
			local newScore = teamScores[4] or 0

			if fourthScore == newScore then return end

			s:SetText(newScore)
			fourthScore = newScore
			s:SizeToContents()
		end
	else
		PropsText.Think = function(s)
			local txt
			if firstScore > secondScore then
				txt = "< " .. scoreText .. " -"
			elseif secondScore > firstScore then
				txt = "- " .. scoreText .. " >"
			else
				txt = "- " .. scoreText .. " -"
			end

			s:SetText(txt)
			s:SizeToContents()
		end
	end

	return pnl
end

function FRETTA:CreateTeamPanel(parent)
	local ply = LocalPlayer()
	local plyTeam = ply:Team()
	local teamName = team_GetName(plyTeam)

	local TeamIndicator = vgui_Create( "DLabel", parent )
	TeamIndicator:SetText(teamName)
	TeamIndicator:SetColor(teamColours[teamName])
	TeamIndicator:SetFont("HudSelectionText")
	TeamIndicator:SizeToContents()
	-- TeamIndicator:SetBackgroundColor(color_white)

	TeamIndicator.Think = function(s)
		s:CenterVertical()

		local newTeam = ply:Team()

		if newTeam == plyTeam then return end

		teamName = team_GetName(newTeam)

		s:SetText(teamName)
		s:SetColor(teamColours[teamName])

		plyTeam = newTeam

		s:SizeToContents()
	end

	return TeamIndicator
end

local yellow = Color(255, 255, 0)
function FRETTA:CreateTimerPanel(parent, x, y)
	local iTimeLeft = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
	if iTimeLeft < 0 then iTimeLeft = 0 end

	if hook_Run("910_DrawTimer", iTimeLeft) then return end

	local TimerText = string_FormattedTime(iTimeLeft, "%02i:%02i")

	local pnl = vgui_Create("DPanel", parent)
	pnl.Paint = nil
	pnl.PerformLayout = function(s)
		local w = 0
		local tallest = 0

		local children = pnl:GetChildren()
		for i = 1, #children do
			local v = children[i]

			v:SetPos(w, 0)
			w = w + v:GetWide()

			if i == 1 then
				w = w + (x * 0.01)
			end

			tallest = math_max( tallest, v:GetTall() )
		end

		pnl:SetSize( w, tallest )
	end

	local RoundNumberParent = vgui_Create("DPanel", pnl)
	RoundNumberParent.Paint = nil
	RoundNumberParent.PerformLayout = function(s) PerformFrettaLayout(s, x * 0.00175, 0) end

	local RoundNumberLabel = vgui_Create("DLabel", RoundNumberParent)
	RoundNumberLabel:SetText( "#NineTenths.Round" )
	RoundNumberLabel:SetFont("HudSelectionText")
	RoundNumberLabel:SetColor(yellow)
	RoundNumberLabel:SizeToContents()
	RoundNumberLabel.Think = function(s) -- DUMB!
		s:SetPos(s:GetX(), y * 0.009)
	end

	local currentRound = GetGlobalFloat("iRoundNumber", 1)

	local RoundNumber = vgui_Create("DLabel", RoundNumberParent)
	RoundNumber:SetText(currentRound)
	RoundNumber:SetFont("FrettaHUDElement")
	RoundNumber:SetColor(color_white)
	RoundNumber:SizeToContents()
	RoundNumber.Think = function(s)
		local newRound = GetGlobalFloat("iRoundNumber", 1)
		if currentRound == newRound then return end

		currentRound = newRound

		s:SetText(currentRound)
		s:SizeToContents()
	end

	RoundNumberParent:SizeToChildren()

	local RoundTimerParent = vgui_Create("DPanel", pnl)
	RoundTimerParent.Paint = nil
	RoundTimerParent.PerformLayout = function(s) PerformFrettaLayout(s, x * 0.00175, 0) end

	local RoundTimerLabel = vgui_Create("DLabel", RoundTimerParent)
	RoundTimerLabel:SetText( "#NineTenths.Time" )
	RoundTimerLabel:SetFont("HudSelectionText")
	RoundTimerLabel:SetColor(yellow)
	RoundTimerLabel:SizeToContents()
	RoundTimerLabel.Think = function(s) -- DUMBER!
		s:SetPos(s:GetX(), y * 0.009)
	end

	local RoundTimer = vgui_Create("DLabel", RoundTimerParent)
	RoundTimer:SetText(TimerText)
	RoundTimer:SetFont("FrettaHUDElement")
	RoundTimer:SetColor(color_white)
	RoundTimer:SizeToContents()

	RoundTimer.Think = function(s)
		local newTime = math_ceil(GetGlobalFloat("fRoundEnd") - CurTime())
		if newTime < 0 then newTime = 0 end

		if iTimeLeft == newTime then return end

		TimerText = string_FormattedTime(newTime, "%02i:%02i")

		s:SetText(TimerText)
		iTimeLeft = newTime

		RoundTimer:SizeToContents()
	end

	RoundTimerParent:SizeToChildren()

	pnl:SizeToChildren()

	return pnl
end

function FRETTA:FindTop()
	self.Rows = 0

	local plys = player_GetAll()

	local deliveries = table.Copy(plys)
	local steals = table.Copy(plys)
	local kills = table.Copy(plys)
	local deaths = table.Copy(plys)

	--table.sort( self.Top5Alive, function(a, b) return a:Frags() > b:Frags() end )

	table_sort(deliveries, function(a, b) return a:GetNWInt("910_Deliveries", 0) > b:GetNWInt("910_Deliveries", 0) end)
	table_sort(steals, function(a, b) return a:GetNWInt("910_Steals", 0) > b:GetNWInt("910_Steals", 0) end)
	table_sort(kills, function(a, b) return a:Frags() > b:Frags() end)
	table_sort(deaths, function(a, b) return a:Deaths() < b:Deaths() end)

	return {deliver = deliveries[1], steal = steals[1], kill = kills[1], death = deaths[1]}
end

local matBlurScreen = Material( "pp/blurscreen" )

local winSound = Sound("ambient/alarms/klaxon1.wav")

local drawCol = Color( 255, 255, 100, 255 )

function FRETTA:CreateWinScreen(winnercount, winners, duration)
	local x, y = ScrW(), ScrH()

	local pnl = vgui_Create("DPanel")
	pnl:SetSize(x, y)
	pnl.Paint = function(s, w, h)
		surface_SetMaterial( matBlurScreen )
		surface_SetDrawColor( 255, 255, 255, 255 )

		matBlurScreen:SetFloat( "$blur", 5 )
		matBlurScreen:Recompute()
		render_UpdateScreenEffectTexture()
		surface_DrawTexturedRect( 0, 0, w, h )

		surface_SetDrawColor( 40, 40, 40, 128)
		surface_DrawRect(0, 0, w, h)
	end

	-- self:SetText( "" )
	-- self:SetSkin( GAMEMODE.HudSkin )
	-- self:ParentToHUD()

	-- self.DoClick = function()
	-- 	if self.ClickTime > CurTime() then return end
	-- 	LocalPlayer():EmitSound( Sound( "buttons/button9.wav" ), 100, 100 )
	-- 	self:Remove()
	-- end

	local lblEndGame = vgui_Create( "DLabel", pnl )
	lblEndGame:SetText( "#NineTenths.GameOver" )
	lblEndGame:SetFont( "SplashHuge" )
	lblEndGame:SetColor( color_white )

	local teamWin = winnercount < #team_GetAllTeams()

	local lblSubs = {}

	if teamWin then
		local lblSubY = 0
		for i = 1, #winners do
			local winner = winners[i]
			local winnerName = team_GetName(winner)

			local txt = string_format(language_GetPhrase("NineTenths.TeamWin"), language_GetPhrase(winnerName))

			lblSubs[i] = vgui_Create( "DLabel", pnl )
			lblSubs[i]:SetText( txt )
			lblSubs[i]:SetFont( "SplashMed" )
			lblSubs[i]:SetColor( teamColours[winnerName] )

			lblSubs[i]:SizeToContents()
			lblSubY = lblSubY + lblSubs[i]:GetTall()
			lblSubs[i]:SetPos( x / 2 - lblSubs[i]:GetWide() / 2, (y / 2) - 200 - lblSubY )
		end
	else
		lblSubs[1] = vgui_Create( "DLabel", pnl )
		lblSubs[1]:SetText( "#NineTenths.ItsADraw" )
		lblSubs[1]:SetFont( "SplashMed" )
		lblSubs[1]:SetColor( drawCol )

		lblSubs[1]:SizeToContents()
		lblSubs[1]:SetPos( x / 2 - lblSubs[1]:GetWide() / 2, (y / 2) - 200 - lblSubs[1]:GetTall() )
	end

	lblEndGame:SizeToContents()
	lblEndGame:SetPos( x / 2 - lblEndGame:GetWide() / 2, (y / 2) - 200 - lblEndGame:GetTall() - lblSubs[1]:GetTall() )

	local topTbl = self:FindTop()

	local lblDeliver = vgui_Create( "DLabel", pnl )
	lblDeliver:SetText( "#NineTenths.PropsStolen" )
	lblDeliver:SetFont( "SplashMed" )

	lblDeliver:SizeToContents()
	lblDeliver:SetPos( x / 1.5 - lblDeliver:GetWide() / 2, y / 2.5 - lblDeliver:GetTall())
	lblDeliver:SetColor( Color( 255, 255, 255, 255 ) )
	lblDeliver:SetVisible( false )

	local parcelBoy = topTbl.deliver
	local txt = parcelBoy:GetDeliveries() .. " - " .. parcelBoy:Nick()

	local mostDeliveries = vgui_Create("DLabel", pnl)
	mostDeliveries:SetText(txt)
	mostDeliveries:SetFont( "SplashMed" )

	mostDeliveries:SizeToContents()
	mostDeliveries:SetPos( x / 1.5 - mostDeliveries:GetWide() / 2, y / 2.5 - mostDeliveries:GetTall() + lblDeliver:GetTall())
	mostDeliveries:SetColor( Color( 255, 255, 255, 255 ) )
	mostDeliveries:SetVisible( false )

	local lblSteals = vgui_Create( "DLabel", pnl )
	lblSteals:SetText( "#NineTenths.PropsDelivered" )
	lblSteals:SetFont( "SplashMed" )

	lblSteals:SizeToContents()
	lblSteals:SetPos( x / 3 - lblSteals:GetWide() / 2, y / 2.5 - lblSteals:GetTall())
	lblSteals:SetColor( Color( 255, 255, 255, 255 ) )
	lblSteals:SetVisible( false )

	local heister = topTbl.steal
	txt = heister:GetSteals() .. " - " .. heister:Nick()

	local mostSteals = vgui_Create("DLabel", pnl)
	mostSteals:SetText(txt)
	mostSteals:SetFont( "SplashMed" )

	mostSteals:SizeToContents()
	mostSteals:SetPos( x / 3 - mostSteals:GetWide() / 2, y / 2.5 - mostSteals:GetTall() + lblSteals:GetTall())
	mostSteals:SetColor( Color( 255, 255, 255, 255 ) )
	mostSteals:SetVisible( false )

	local lblKills = vgui_Create( "DLabel", pnl )
	lblKills:SetText( "#NineTenths.PlayersKilled" )
	lblKills:SetFont( "SplashMed" )

	lblKills:SizeToContents()
	lblKills:SetPos( x / 1.5 - lblKills:GetWide() / 2, y / 1.55 - lblKills:GetTall())
	lblKills:SetColor( Color( 255, 255, 255, 255 ) )
	lblKills:SetVisible( false )

	local monster = topTbl.kill
	txt = monster:Frags() .. " - " .. monster:Nick()

	local mostKills = vgui_Create("DLabel", pnl)
	mostKills:SetText(txt)
	mostKills:SetFont( "SplashMed" )

	mostKills:SizeToContents()
	mostKills:SetPos( x / 1.5 - mostKills:GetWide() / 2, y / 1.55 - mostKills:GetTall() + lblKills:GetTall())
	mostKills:SetColor( Color( 255, 255, 255, 255 ) )
	mostKills:SetVisible( false )

	local lblSurvive = vgui_Create( "DLabel", pnl )
	lblSurvive:SetText( "#NineTenths.LowestDeaths" )
	lblSurvive:SetFont( "SplashMed" )

	lblSurvive:SizeToContents()
	lblSurvive:SetPos( x / 3 - lblSurvive:GetWide() / 2, y / 1.55 - lblSurvive:GetTall())
	lblSurvive:SetColor( Color( 255, 255, 255, 255 ) )
	lblSurvive:SetVisible( false )

	local gloriaGaynor = topTbl.death
	txt = gloriaGaynor:Deaths() .. " - " .. gloriaGaynor:Nick()

	local leastDeaths = vgui_Create("DLabel", pnl)
	leastDeaths:SetText(txt)
	leastDeaths:SetFont( "SplashMed" )

	leastDeaths:SizeToContents()
	leastDeaths:SetPos( x / 3 - leastDeaths:GetWide() / 2, y / 1.55 - leastDeaths:GetTall() + lblSurvive:GetTall())
	leastDeaths:SetColor( Color( 255, 255, 255, 255 ) )
	leastDeaths:SetVisible( false )

	timer_Simple(2, function()
		lblDeliver:SetVisible(true)
		lblSteals:SetVisible(true)
		lblKills:SetVisible(true)
		lblSurvive:SetVisible(true)

		mostDeliveries:SetVisible(true)
		mostSteals:SetVisible(true)
		mostKills:SetVisible(true)
		leastDeaths:SetVisible(true)

		LocalPlayer():EmitSound( Sound( "buttons/blip1.wav" ), 100, 100 )
	end)

	surface_PlaySound(winSound)

	timer_Simple(7, function() pnl:Remove() end)
end