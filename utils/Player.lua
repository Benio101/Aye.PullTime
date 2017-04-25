local Aye = Aye;
if not LibStub:NewLibrary("Aye.utils.Player", 3) then return end;
Aye.utils.Player = Aye.utils.Player or {};

-- @noparam
-- @return {bool} IsOnPvP if player is on PvP (arena or battleground)
Aye.utils.Player.IsOnPvP = function()
	local _, instanceType = IsInInstance();
	if
			instanceType == "arena"
		or	instanceType == "pvp"
	then
		return true;
	end;
	
	return false;
end;

-- @noparam
-- @return {int} allies		members number of allies in player group (ally is either guildmate or friend)
-- @return {int} guildmates	number of guildmates in player group
-- @return {int} friends	number of friends in player group
-- @note allies may be less than guildmates plus friends since guildmate can be also a friend
Aye.utils.Player.GetGroupAllies = function()
	local members = max(1, GetNumGroupMembers());
	local groupType = IsInRaid() and "raid" or "party";
	if groupType == "party" then members =members -1 end;
	
	local allies = 0;
	local guildmates = 0;
	local friends = 0;
	
	for i = 1, members do
		if not UnitIsUnit("player", groupType ..i) then
			local ally = false;
			
			if UnitIsInMyGuild(groupType ..i) then
				ally = true;
				guildmates =guildmates +1;
			end;
			
			for i = 1, GetNumFriends() do
				local name = GetFriendInfo(i);
				if name == UnitName(groupType ..i) then
					ally = true;
					friends =friends +1;
				end;
			end;
			
			if ally then allies =allies +1 end;
		end;
	end;
	
	return allies, guildmates, friends;
end;

-- @noparam
-- @return {bool} InAllyGroup if player is in ally group
-- @note Ally group means that at least half of players are either friends or guildmates
Aye.utils.Player.InAllyGroup = function()
	return (Aye.utils.Player.GetGroupAllies() >= max(1, GetNumGroupMembers()) /2);
end;

-- @noparam
-- @return {bool} IsMythicBenched if player is in Mythic Raid Group in outside Party 1–4
Aye.utils.Player.IsMythicBenched = function()
	if not (
			IsInRaid()
		and	not IsPartyLFG()
		and	GetRaidDifficultyID() == DIFFICULTY_PRIMARYRAID_MYTHIC
	) then return false end;
	
	local members = max(1, GetNumGroupMembers());
	if Aye.utils.Player.InAllyGroup() then return false end;
	
	for rid = 1, members do
		if UnitIsUnit("player", "raid" ..rid) then
			local _, _, pid = GetRaidRosterInfo(rid);
			
			return (pid >4);
		end;
	end;
	
	return false;
end;