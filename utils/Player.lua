local Aye = Aye;
if not LibStub:NewLibrary("Aye.utils.Player", 5) then return end;
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

-- @param {string} unit
-- @return {bool} isFriend if given unit is player's friend (from friends list)
Aye.utils.Player.IsFriend = function(unit)
	local unitName = UnitName(unit);
	for i = 1, GetNumFriends() do
		local name = GetFriendInfo(i);
		if name == unitName then
			return true;
		end;
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
-- @return {bool} IsBenched if player is either:
-- 		in Mythic Raid Group in outside Party 1–4
-- 	OR	in Normal/Heroic Raid Group in outside Party 1–6
Aye.utils.Player.IsBenched = function()
	if
			not IsInRaid()
		or	IsPartyLFG()
		or	not Aye.utils.Player.InAllyGroup()
	then return false end;
	
	-- groups per raid difficulty
	local groups = false;
	local difficulty = GetRaidDifficultyID();
	if difficulty == DIFFICULTY_PRIMARYRAID_MYTHIC then groups = 4 end;
	if
			difficulty == DIFFICULTY_PRIMARYRAID_HEROIC
		or	difficulty == DIFFICULTY_PRIMARYRAID_NORMAL
	then groups = 6 end;
	if groups == false then return false end;
	
	local members = max(1, GetNumGroupMembers());
	
	for rid = 1, members do
		if UnitIsUnit("player", "raid" ..rid) then
			local _, _, pid = GetRaidRosterInfo(rid);
			
			return (pid >groups);
		end;
	end;
	
	return false;
end;