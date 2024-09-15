local hudType = CreateClientConVar("910_hud", "0", true, false, "Change your HUD to one from another version of 910. 0 = Map Choice, 1 = Sourcemod, 2 = GM9, 3 = Fretta", 0, 3)

local function ShowWinner(duration, winners)
	local gm = GAMEMODE
	local tbl

	local hudMode = hudType:GetInt()

	if hudMode == 0 then
		tbl = gm:IsFretta() and FRETTA or (gm:IsSourcemod() and SOURCEMOD or GM9)
	else
		tbl = hudMode == 3 and FRETTA or (hudMode == 1 and SOURCEMOD or GM9)
	end

	tbl:CreateWinScreen(#winners, winners, duration)
end

net.Receive("910_Winner", function()
	local duration = net.ReadUInt(6)

	local winnercount = net.ReadUInt(3) + 1

	local winners = {}
	for i = 1, winnercount do
		local winner = net.ReadUInt(3) + 1
		table.insert(winners, winner)
	end

	ShowWinner(duration, winners)
end)

-- concommand.Add("910_winscreen", function(ply, cmd, args)
-- 	local winners = {}
-- 	for i = 1, #args do
-- 		table.insert(winners, tonumber(args[i]))
-- 	end

-- 	ShowWinner(7, winners)
-- end)

local function ReceiveTeams()
	if !GAMEMODE.CurrentTeamID then GAMEMODE.CurrentTeamID = 0 end
	GAMEMODE.CurrentTeamID = GAMEMODE.CurrentTeamID + 1

	local i = net.ReadUInt(3) + 1
	local tinfo = GAMEMODE.Teams[i]

	team.SetUp(GAMEMODE.CurrentTeamID, tinfo[1], tinfo[2])
end
net.Receive("910_SendTeams", ReceiveTeams)

function GM:ScoreOverride(tid, score)
	if !self.ItemCount then self.ItemCount = {} end
	self.ItemCount[tid] = score
end
net.Receive("910_SetScore", function() GAMEMODE:ScoreOverride(net.ReadUInt(3), net.ReadUInt(8)) end)

function GM:ResetHUD(old, new)
	local curHud = old:len() == 1 and tonumber(old) or hudType:GetInt()
	if curHud == 1 or curHud == 3 or self:IsFretta() or self:IsSourcemod() then
		self.ExtraPanel:Remove()
	end

	self.TeamPanel:Remove()
	self.ScorePanel:Remove()
	self.TimerPanel:Remove()

	self:GenerateFonts()
end
concommand.Add("910_resethud", function() GAMEMODE:ResetHUD("0", "0") end)
cvars.AddChangeCallback("910_hud", function(_, old, new) GAMEMODE:ResetHUD(old, new) end)
cvars.AddChangeCallback("gmod_language", function() GAMEMODE:ResetHUD("0", "0") end)
hook.Add("OnScreenSizeChanged", "910_ResolutionReset", function() GAMEMODE:ResetHUD("0", "0") end)

-- called every second
function GM:TargetID(x, y)
	local tr = LocalPlayer():GetEyeTrace()
	local ent = tr.Entity
	if !ent or !ent:IsPlayer() then return end

	local nick = ent:Nick()
	surface.SetFont("TargetID")
	local w = surface.GetTextSize(nick)

	local teamcol = team.GetColor(ent:Team())
	surface.SetTextColor(teamcol.r, teamcol.g, teamcol.b)

	surface.SetTextPos((x / 2) - (w / 2), (y / 2) + (y * 0.015))
	surface.DrawText(nick)
end

function GM:HUDPaint()
	if !self.GamemodeVersion then return end

	local hudMode = hudType:GetInt()
	local tbl

	local extraPanel = false

	if hudMode == 0 then
		tbl = self:IsFretta() and FRETTA or (self:IsSourcemod() and SOURCEMOD or GM9)

		if self:IsSourcemod() or self:IsFretta() then
			extraPanel = true
		end
	else
		tbl = hudMode == 3 and FRETTA or (hudMode == 1 and SOURCEMOD or GM9)

		if hudMode == 1 or hudMode == 3 then
			extraPanel = true
		end
	end

	local x, y = ScrW(), ScrH()

	if extraPanel and !IsValid(self.ExtraPanel) then
		self.ExtraPanel = tbl:CreateExtraPanel(x, y)
		self.ExtraPanel:ParentToHUD()
	end

	if !IsValid(self.TeamPanel) then
		self.TeamPanel = tbl:CreateTeamPanel(self.ExtraPanel, x, y)
	end

	if !IsValid(self.ScorePanel) then
		self.ScorePanel = tbl:CreateScorePanel(self.ExtraPanel, x, y)
	end

	if !IsValid(self.TimerPanel) then
		self.TimerPanel = tbl:CreateTimerPanel(self.ExtraPanel, x, y)
	end

	self:TargetID(x, y)

	hook.Call( "DrawDeathNotice", self, 0.85, 0.04 )
end

local circleMat = Material("SGM/playercircle")
local circleSize = 48
function GM:PostDrawOpaqueRenderables() -- gm12 fretta referenced for accurate circle behaviour
	for _, ply in player.Iterator() do
		if (ply == LocalPlayer() and !ply:ShouldDrawLocalPlayer()) or !ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end

		local pos = ply:GetPos()
		local tr = util.TraceLine({
			start = pos + Vector(0, 0, 50),
			endpos = pos + Vector(0, 0, -300),
			filter = ply
		})

		local hp = tr.HitPos
		local hn = tr.HitNormal
		if !tr.HitWorld then
			hp = pos
		end

		local tcol = team.GetColor(ply:Team())
		local colour = Color(tcol.r, tcol.g, tcol.b)
		render.SetMaterial(circleMat)
		render.DrawQuadEasy(hp + hn, hn, circleSize, circleSize, colour)
	end
end

local mTeam1 = Material("gmod/gm_910/team1")
local mTeam2 = Material("gmod/gm_910/team2")
local function ChooseTeam(num)
	num = (num != 6 and num > #team.GetAllTeams()) and team.BestAutoJoinTeam() or num

	local x = ScrW()
	local y = ScrH()

	local teamW = x * 0.35
	local teamH = y * 0.42

	local starttime = CurTime()

	if num <= 2 then
		hook.Add("HUDPaintBackground", "910_TeamScreen", function()
			local delta = CurTime() - starttime

			local bgd = math.Clamp(delta / 2, 0, 1)
			local bga = Lerp(bgd, 15, 0)

			local discardd = math.Clamp(delta, 0, 1)
			local discarda = Lerp(discardd, 255, 0)

			local selectd = math.Clamp(delta / 1.5, 0, 1)
			local selecta = Lerp(selectd, 255, 0)

			local selectSize = Lerp(math.ease.OutCirc(selectd), 1, 2)
			local selectW = teamW * selectSize
			local selectH = teamH * selectSize

			local isYellow = num == 2

			local blueMod = isYellow and 1 or selectSize
			local blueW = isYellow and teamW or selectW
			local blueH = isYellow and teamH or selectH

			local yellowMod = isYellow and selectSize or 1
			local yellowW = isYellow and selectW or teamW
			local yellowH = isYellow and selectH or teamH

			surface.SetDrawColor(255, 255, 255, bga)
			surface.DrawRect(0, 0, x, y)

			surface.SetDrawColor(255, 255, 255, !isYellow and selecta or discarda)
			surface.SetMaterial(mTeam1)
			surface.DrawTexturedRect((x * 0.15) / blueMod, (y * 0.25) / blueMod, blueW, blueH)

			surface.SetDrawColor(255, 255, 255, isYellow and selecta or discarda)
			surface.SetMaterial(mTeam2)
			surface.DrawTexturedRect((x * 0.5) / yellowMod, (y * 0.25) / yellowMod, yellowW, yellowH)

			surface.SetFont("LegacyDefault")
			surface.SetTextColor(0, 0, 0, discarda)
			local w = surface.GetTextSize("#NineTenths.AutoSelect")
			surface.SetTextPos((x * 0.5) - (w / 2), y * 0.8)
			surface.DrawText("#NineTenths.AutoSelect")
		end)
	end

	timer.Create("910_KillTeamScreen", 5, 1, function() hook.Remove("HUDPaintBackground", "910_TeamScreen") end)

	local ply = LocalPlayer()

	surface.PlaySound("hl1/fvox/activated.wav")

	local toSend = num - 1

	if num != 6 then
		if num <= GAMEMODE.CurrentTeamID then
			if ply:Team() == num then return true end
		else
			toSend = 6
		end
	end

	-- anything else is auto choose team
	net.Start("910_ChangeTeam")
		net.WriteUInt(toSend, 3)
	net.SendToServer()

	return true
end

-- These are called by the players in game using the F1 - F4 keys

local help
local function onShowHelp()
	if hook.Run("910_HelpScreen") then return end

	if IsValid(help) then
		help:Remove()
	end

	local help1 = "#NineTenths.Help1"
	local help2 = "#NineTenths.Help2"

	local w, h = ScrW(), ScrH()

	help = vgui.Create("DPanel")

	surface.SetFont("LegacyDefault")
	local x, y = surface.GetTextSize(help1)
	help:SetSize(x, y * 5)
	help:SetPos((w / 2) - (x / 2), h * 0.3)

	help.Paint = function(s, pw, ph)
		surface.SetFont("LegacyDefault")
		surface.SetTextColor(255, 255, 255, s:GetAlpha())

		local tx = surface.GetTextSize(help1)
		surface.SetTextPos((pw / 2) - (tx / 2), 0)
		surface.DrawText(help1)

		tx = surface.GetTextSize(help2)
		surface.SetTextPos((pw / 2) - (tx / 2), y * 2)
		surface.DrawText(help2)
	end

	help:SetAlpha(0)

	help:AlphaTo(255, 0.2, 0)
	help:AlphaTo(0, 2, 5, function(_, pnl) pnl:Remove() end)
end
concommand.Add("910_helpscreen", onShowHelp)
net.Receive("910_HelpScreen", onShowHelp)

-- temporary until i can make some appropriately coloured pantsless dudes
local sTeam3 = "Press 3 to join RED"
local sTeam4 = "Press 4 to join GREEN"

local delay = 1
local function DrawShowTeam(x, y, starttime)
	local delta1 = math.Clamp(CurTime() - starttime, 0, 1) * 2
	local alpha1 = Lerp(delta1, 0, 15)

	local delta2 = math.Clamp(CurTime() - starttime, 0, 1) * 2
	local alpha2 = Lerp(delta2, 0, 255)

	surface.SetDrawColor(255, 255, 255, alpha1)
	surface.DrawRect(0, 0, x, y)

	surface.SetDrawColor(255, 255, 255, alpha2)
	surface.SetMaterial(mTeam1)
	surface.DrawTexturedRect(x * 0.15, y * 0.25, x * 0.35, y * 0.42)

	surface.SetMaterial(mTeam2)
	surface.DrawTexturedRect(x * 0.5, y * 0.25, x * 0.35, y * 0.42)

	surface.SetFont("LegacyDefault")

	local numTeams = #team.GetAllTeams()
	if numTeams > 2 then
		surface.SetTextColor(255, 0, 0, 255)
		local w = surface.GetTextSize(sTeam3)
		surface.SetTextPos((x * 0.5) - (w / 2), y * 0.75)
		surface.DrawText(sTeam3)
	end

	if numTeams > 3 then
		surface.SetTextColor(0, 255, 0, 255)
		local w = surface.GetTextSize(sTeam4)
		surface.SetTextPos((x * 0.5) - (w / 2), y * 0.775)
		surface.DrawText(sTeam4)
	end

	if CurTime() > starttime + delay then
		local delta3 = math.Clamp(CurTime() - starttime - delay, 0, 1) * 2
		local alpha3 = Lerp(delta3, 0, 255)

		surface.SetTextColor(0, 0, 0, alpha3)
		local w, h = surface.GetTextSize("#NineTenths.AutoSelect")
		surface.SetTextPos((x * 0.5) - (w / 2), y * 0.8)
		surface.DrawText("#NineTenths.AutoSelect")

		w = surface.GetTextSize("#NineTenths.Spectate")
		surface.SetTextPos((x * 0.5) - (w / 2), (y * 0.8) + h)
		surface.DrawText("#NineTenths.Spectate")
	end
end

local disableTeamChange = CreateConVar("910_disableteamchange", "0", FCVAR_REPLICATED)
function GM:ShowTeam()
	if disableTeamChange:GetBool() then
		if LocalPlayer():Team() == TEAM_SPECTATOR then
			chat.AddText("Press F2 again to join a team.")
		else
			chat.AddText("Press F2 again to join spectator.")
		end

		return
	end

	if hook.Run("910_TeamScreen") then return end

	hook.Remove("HUDPaintBackground", "910_TeamScreen")
	if timer.Exists("910_KillTeamScreen") then timer.Remove("910_KillTeamScreen") end

	local x = ScrW()
	local y = ScrH()

	local starttime = CurTime()

	-- I know this 99999 stuff sucks.. but so do I.
	LocalPlayer():AddPlayerOption("ChooseTeam", 99999, ChooseTeam, function() DrawShowTeam(x, y, starttime) end)
end
concommand.Add("910_showteam", function() GAMEMODE:ShowTeam() end)
net.Receive("910_ShowTeam", function() GAMEMODE:ShowTeam() end)

local function RPSound()
	local good = net.ReadBool()
	local snd

	if GAMEMODE:IsFretta() then
		snd = good and Sound("hl1/fvox/blip.wav") or Sound("hl1/fvox/fuzz.wav")
	else
		snd = good and Sound("hl1/fvox/bell.wav") or Sound("hl1/fvox/buzz.wav")
	end

	surface.PlaySound(snd)
end
net.Receive("910_RPSound", RPSound)

local function ShowScoreboard()
	GAMEMODE:ScoreboardHide()
	GAMEMODE:ScoreboardShow()

	GAMEMODE.ScoreboardShow = nil
	GAMEMODE.ScoreboardHide = nil
end
net.Receive("910_ShowScoreboard", ShowScoreboard)

function GM:UpdateScore()
	local tid = net.ReadUInt(2) + 1
	local amount = net.ReadInt(5)

	if !self.ItemCount then self.ItemCount = {} end -- for maps that start with props touching base (e.g. smash)
	if !self.ItemCount[tid] then self.ItemCount[tid] = 0 end

	self.ItemCount[tid] = self.ItemCount[tid] + amount
end
net.Receive("910_UpdateScores", function() GAMEMODE:UpdateScore() end)