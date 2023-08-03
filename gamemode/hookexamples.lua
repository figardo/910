-- There can be different combinations of these teams, but they will always be in this order
-- e.g. Blue and Green will result in 1 = Blue, 2 = Green
-- e.g. Red and Yellow will result in 1 = Yellow, 2 = Red

-- TEAM ID LIST:
-- 1 = Blue
-- 2 = Yellow (Red if Sourcemod map)
-- 3 = Red
-- 4 = Green

-- CLIENT

-- hook.Add("910_DrawScores", "identifier", function(scoreTbl)
-- Draws the team scores section of the HUD. Argument 1 is the table of scores, in order of team ID. (See above)
-- return true to prevent the original team scores section from drawing.
-- end)

-- hook.Add("910_DrawTimer", "identifier", function(seconds)
-- Draws the timer section of the HUD. Argument 1 is the time left in seconds.
-- return true to prevent the original timer section from drawing.
-- end)

-- hook.Add("910_HelpScreen", "identifier", function()
-- Called when F1 is pressed, shows the help screen.
-- return true to prevent the original help screen from showing.
-- end)

-- hook.Add("910_TeamScreen", "identifier", function()
-- Called either after the intro, or when F2 is pressed, shows the team select screen.
-- return true to prevent the original team select screen from showing.
-- end)


-- SERVER

-- hook.Add("910_EntityTouch", "identifier", function(team, ent, score)
-- Called when a prop or entity enters/exits a team base.
-- Argument 1 is the team ID. (See above)
-- Argument 2 is the entity that entered/exited the base.
-- Argument 3 is the intended score change. You can find out if the prop entered or exited by checking if this number is negative.
-- return a number to override the score change.
-- end)

local totalRounds = CreateConVar("910_rounds", "5", FCVAR_ARCHIVE, "The number of rounds played before a mapvote is called. Requires Fretta-like Mapvote.")

-- Called after a round end, just as a new round is about to begin.
hook.Add("910_RoundEnd", "910_Mapvote", function(roundCount) -- Argument 1 is the current round number.
	local maxrounds = totalRounds:GetInt()
	if maxrounds <= 0 then return end -- opt out for people who don't want to disable mapvote

	if MapVote and roundCount > maxrounds then
		timer.Simple(5, function()
			MapVote.Start(nil, nil, nil, {""}) -- look for maps with 910_ prefixes
		end)

		return true -- prevents round from restarting
	end

	return false -- allows round to restart
end)