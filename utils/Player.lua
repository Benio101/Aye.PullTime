local Aye = Aye;
Aye.utils.Player = Aye.utils.Player or {};

-- @noparam
-- @return {bool} IsOnPvP if player is on PvP (arena or battleground)
Aye.utils.Player.IsOnPvP = Aye.utils.Player.IsOnPvP or function()
	local _, instanceType = IsInInstance();
	if
			instanceType == "arena"
		or	instanceType == "pvp"
	then
		return true;
	end;
	
	return false;
end;