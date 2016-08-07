local Aye = Aye;
Aye.utils.Chat = Aye.utils.Chat or {};

-- Get proper group channel
--
-- @param {bool} [rw = false] if true, return "raid_warning" if possible to use instead
-- @return {string} "raid_warning" | "raid" | "party" | "instance_chat"
--
-- @example
--| SendChatMessage("Hey, group!",		Aye.utils.Chat.GetGroupChannel());		-- Say welcome to your group
--| SendChatMessage("Warning, group!",	Aye.utils.Chat.GetGroupChannel(true));	-- Warn your group, use Raid Warning if possible
Aye.utils.Chat.GetGroupChannel = Aye.utils.Chat.GetGroupChannel or function(rw)
	rw = rw ~= nil and rw or false;
	
	-- Raid Warning (only if rw is set)
	if (
			rw
		and	UnitInRaid("player") ~= nil
		and (
					UnitIsGroupLeader("player")
				or	UnitIsGroupAssistant("player")
			)
	) then
		return "raid_warning";
	end;
	
	-- Raid (or Instance if LFG)
	if UnitInRaid("player") ~= nil then
		return IsPartyLFG() and "instance_chat" or "raid";
	end;
	
	-- Party otherwise, or say if not in raid nor party
	return IsInGroup() and (IsPartyLFG() and "instance_chat" or "party") or "say";
end;

-- Send chat message on a sufficient significant, proper group channel
--
-- @param {string} msg message to send
-- @param {uint(2)} [significance = 0] minimum channel significance:
--
-- +--------------+-------+------------------------------------+
-- | significance | range | channel                            |
-- +--------------+-------+------------------------------------+
-- |            0 |  25yd | "say"                              |
-- |            1 | 300yd | "yell"                             |
-- |            2 |       | "raid" | "party" | "instance_chat" |
-- |            3 |       | "raid_warning"                     |
-- +--------------+-------+------------------------------------+
--
-- Message will be sent on the least sufficient significant channel, but not less significant than @significance
-- If @significance will be set to 3, but sender cannot Raid Warning, @significance = 2 will be used instead
--
-- @param {uint|-1} [sufficiency = -1] sufficient amount of message recipients (beside sender) or -1 if all group players should receive message
-- Channel if considered sufficient if at least @sufficiency players (beside sender) can receive a message, or all group players if @sufficiency is set to -1
--
-- @noreturn
-- @example
--| Aye.utils.Chat.SendChatMessage("Help me casting Ritual of Summoning!", 2);
--| -- If there are at least 2 players within 25yd, message will be sent on "say" channel
--| -- If there are at least 2 players within 300yd, message will be sent on "yell" channel
--| -- Otherwise, message will be sent on either "raid", "party" or "instance_chat" (depending on type of group)
--| 
--| Aye.utils.Chat.SendChatMessage("Wipe!", nil, 3);
--| -- message will be sent on "raid_warning" channel, or on "raid" channel if sender cannot Raid Warning
Aye.utils.Chat.SendChatMessage = Aye.utils.Chat.SendChatMessage or function(msg, significance, sufficiency)
	significance = significance ~= nil and significance or 0;
	sufficiency = sufficiency ~= nil and sufficiency or -1;
	
	local chat = IsPartyLFG() and "instance_chat" or "party"; -- chat to say on
	local bRaid = UnitInRaid("player") ~= nil; -- is it raid
	local members = GetNumGroupMembers();
	
	if
			significance == 3
		and	bRaid
		and	(
					UnitIsGroupLeader("player")
				or	UnitIsGroupAssistant("player")
			)
	then
		chat = "raid_warning";
	end;
	
	if bRaid then
		chat = IsPartyLFG() and "instance_chat" or "raid";
	end;
	
	local raidRecipients = 0;	-- number of valid raid recipients except player itself
	local yellRecipients = 0;	-- number of valid yell recipients except player itself
	local sayRecipients = 0;	-- number of valid say recipients except player itself
	
	-- in raid, every player have "raidX" id where id begins from 1 and ends with member number
	-- in party, there is always "player" and every NEXT members are "partyX" where X begins from 1
	-- especially, in full party, there are: "player", "party1", "party2", "party3", "party4" and NO "party5"
	if not bRaid then
		members = members -1;
	end;
	
	for i = 1, members do
		local unitID = bRaid and "raid" ..i or "party" ..i;
		local online = UnitIsConnected(unitID);
		local isDead = UnitIsDeadOrGhost(unitID);
		
		if
				online
			and	not isDead
			and not UnitIsUnit(unitID, "player")
		then
			raidRecipients = raidRecipients +1;
			if sufficiency > -1 and significance >= 2 and raidRecipients >= sufficiency then
				SendChatMessage(msg, chat);
				return;
			end;
			
			local distance = math.sqrt(UnitDistanceSquared(unitID));
			
			if distance <= 300 then
				yellRecipients = yellRecipients +1;
				
				if sufficiency > -1 and significance == 1 and yellRecipients >= sufficiency then
					SendChatMessage(msg, "yell");
					return;
				end;
				
				if distance <= 25 then
					sayRecipients = sayRecipients +1;
					
					if sufficiency > -1 and significance == 0 and sayRecipients >= sufficiency then
						SendChatMessage(msg, "say");
						return;
					end;
				end;
			end;
		end;
	end;
	
	if sufficiency > -1 and significance < 2 and yellRecipients >= sufficiency then
		SendChatMessage(msg, "yell");
		return;
	end;
	
	if sufficiency == -1 then
		if significance == 0 and sayRecipients == raidRecipients then
			SendChatMessage(msg, "say");
			return;
		elseif significance < 2 and yellRecipients == raidRecipients then
			SendChatMessage(msg, "yell");
			return;
		end;
	end;
	
	SendChatMessage(msg, chat);
end;