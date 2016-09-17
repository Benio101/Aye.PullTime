local Aye = Aye;
if not Aye.addModule("Aye.PullTime") then return end;

Aye.modules.PullTime.OnEnable = function()
	-- start profiling (used to get ms precision)
	if debugprofilestop() == nil then
		debugprofilestart();
	end;
	
	RegisterAddonMessagePrefix("Aye");	-- Aye
	RegisterAddonMessagePrefix("D4");	-- DBM
	
	-- DBM 0 second Pull Time (profiled ms or nil if no pull countdown active)
	-- set back to nil Aye.db.global.PullTime.metersDelayTime seconds after planned pull or when all Pull Time meters are filled
	-- On DMB Pull, gets value equal to debugprofilestop() +seconds *1000 where seconds are seconds to pull
	Aye.modules.PullTime.PlannedPullTime = nil;
	
	-- Pull Time meters cointaining information Who Pulled and When Pulled by certain ways
	-- .count contains number of Pull Time meters are filled
	Aye.modules.PullTime.meters = {count = 0};
	
	-- number of Pull Time meters available
	Aye.modules.PullTime.METERS_COUNT = #{
		-- list of all Pull Time meters
		"aggro",		-- UNIT_THREAT_SITUATION_UPDATE
		"encounter",	-- ENCOUNTER_START
		"target",		-- UNIT_TARGET
		"hit",			-- COMBAT_LOG_EVENT_UNFILTERED
	};
	
	-- mark for ninja pulls
	Aye.modules.PullTime.NinjaPull = false;
	
	-- list of subjects that won't be checked
	-- considering others made it already
	-- aka anti chat spam system
	Aye.modules.PullTime.disableNotify = false;
end;

Aye.modules.PullTime.events.CHAT_MSG_ADDON = function(...)
	if not Aye.db.global.PullTime.enable then return end;
	local prefix, message, _, sender = ...;
	
	-- Aye Warnings broadcast handle
	if
			prefix == "Aye"
		and	message == "PullTime"
		and not UnitIsUnit(sender, "player")
		and not Aye.modules.PullTime.disableNotify
	then
		-- antispam: disable notifies for 10s
		Aye.modules.PullTime.disableNotify = true;
		Aye.modules.PullTime.CleardisableNotifyTimerFunction = Aye.libs.Timer:ScheduleTimer("PullTime_enableNotify", 10);
	end;
	
	-- DBM Pull Time broadcast handle
	if
			prefix == "D4"
		and	message ~= nil
		and	(
					UnitIsGroupLeader(sender)
				or	UnitIsGroupAssistant(sender)
			)
	then
		local seconds = message:match("^PT\t(%d+)");
		if seconds ~= nil then
			seconds = tonumber(seconds);
			if seconds ==0 then
				-- DBM Pull cancelled
				Aye.libs.Timer.PullTime_clear();
			elseif seconds >0 then
				-- DBM Pull
				Aye.modules.PullTime.NinjaPull = false;
				
				-- mark when planned pull have to occur (in ms, using debugprofilestop())
				Aye.modules.PullTime.PlannedPullTime = debugprofilestop() +seconds *1000; -- time when pull is planned (in ms)
				
				-- set Aye.modules.PullTime.PlannedPullTime back to nil
				-- watcher expires Aye.db.global.PullTime.metersDelayTime seconds after planned pull
				Aye.modules.PullTime.ClearTimerFunction = Aye.libs.Timer:ScheduleTimer("PullTime_report", seconds +Aye.db.global.PullTime.metersDelayTime);
			end;
		end;
	end;
end;

-- Kill DBM Pull countdown watcher
-- Triggered either Aye.db.global.PullTime.metersDelayTime seconds after planned pull or when all Pull Time meters are filled
--
-- @noparam
-- @noreturn
Aye.libs.Timer.PullTime_clear = function()
	Aye.libs.Timer:CancelTimer(Aye.modules.PullTime.ClearTimerFunction);
	Aye.modules.PullTime.PlannedPullTime = nil;
	Aye.modules.PullTime.meters = {count = 0};
	Aye.modules.PullTime.NinjaPull = false;
end;

-- reenable notifies (antispam time expired)
--
-- @noparam
-- @noreturn
Aye.libs.Timer.PullTime_enableNotify = function()
	Aye.libs.Timer:CancelTimer(Aye.modules.PullTime.CleardisableNotifyTimerFunction);
	Aye.modules.PullTime.disableNotify = false;
end;

Aye.modules.PullTime.events.UNIT_THREAT_SITUATION_UPDATE = function(...)
	if
			not Aye.db.global.PullTime.enable
		or	(
					not Aye.db.global.PullTime.showAggroName
				and	not Aye.db.global.PullTime.showAggroPullTime
			)
	then return end;
	
	-- note only first threat situation update
	if Aye.modules.PullTime.meters.aggro ~= nil then return end;
	
	local Unit = ...;
	if Unit == nil then
		return;
	end;
	
	local name = UnitName(Unit);
	if name == nil then
		return;
	end;
	
	-- Raid Unit Aggro state changed
	if Aye.modules.PullTime.PlannedPullTime ~= nil then
		-- Pull countdown (or upto Aye.db.global.PullTime.metersDelayTime seconds after)
		
		local player = false;
		if (
				UnitInRaid(Unit) ~= nil
			or	UnitInParty(Unit)
			or	UnitIsUnit(Unit, "player")
		) then
			player = true;
		end;
		
		if not player then
			local members = max(1, GetNumGroupMembers());
			for i = 1, members do
				-- in raid, every player have "raidX" id where id begins from 1 and ends with member number
				-- in party, there is always "player" and every NEXT members are "partyX" where X begins from 1
				-- especially, in full party, there are: "player", "party1", "party2", "party3", "party4" and NO "party5"
				local petID = (UnitInRaid("player") and "raid" ..i or (i ==1 and "" or "party" ..i -1)) .. "pet";
				if UnitIsUnit(petID, Unit) then
					local ownerID = UnitInRaid("player") and "raid" ..i or (i ==1 and "player" or "party" ..i -1);
					local ownerName = UnitName(ownerID);
					if ownerName then
						name = name .." (" ..ownerName .."'s pet)";
					end;
				end;
			end;
		end;
		
		Aye.modules.PullTime.meters.aggro = {
			-- pulling unit name
			name = name,
			
			-- time beetween planned and real pull (in ms)
			ms = debugprofilestop() - Aye.modules.PullTime.PlannedPullTime,
		};
		
		Aye.modules.PullTime.meters.count = Aye.modules.PullTime.meters.count +1;
		Aye.modules.PullTime.checkReport();
	end;
end;

Aye.modules.PullTime.events.ENCOUNTER_START = function()
	if
			not Aye.db.global.PullTime.enable
		or	(
					not Aye.db.global.PullTime.showEncounterLink
				and	not Aye.db.global.PullTime.showEncounterStartTime
				
				-- ENCOUNTER_START catches Ninja Pulls, don't disable it
				and Aye.modules.PullTime.PlannedPullTime ~= nil
			)
	then return end;
	
	-- note only first encounter start occurence
	if Aye.modules.PullTime.meters.encounter ~= nil then return end;
	
	-- Ninja pull
	if Aye.modules.PullTime.PlannedPullTime == nil then
		Aye.modules.PullTime.NinjaPull = true;
		Aye.modules.PullTime.PlannedPullTime = debugprofilestop();
		
		-- set Aye.modules.PullTime.PlannedPullTime back to nil
		-- watcher expires Aye.db.global.PullTime.metersDelayTime seconds after ninja pull
		Aye.modules.PullTime.ClearTimerFunction = Aye.libs.Timer:ScheduleTimer("PullTime_report", Aye.db.global.PullTime.metersDelayTime);
	end;
	
	-- Pull countdown (or upto Aye.db.global.PullTime.metersDelayTime seconds after)
	
	-- link to current encounter
	local _, _, _, _, _, _, _, link = Aye.utils.EJ.GetCurrentEncounter();
	
	Aye.modules.PullTime.meters.encounter = {
		-- time beetween planned and real pull (in ms)
		ms = debugprofilestop() - Aye.modules.PullTime.PlannedPullTime,
		link = link or "",
	};
	
	Aye.modules.PullTime.meters.count = Aye.modules.PullTime.meters.count +1;
	Aye.modules.PullTime.checkReport();
end;

Aye.modules.PullTime.events.ENCOUNTER_END = function()
	-- disable notify for 10s after ENCOUNTER_END.
	-- it looks like ENCOUNTER_START fires sometimes right after ENCOUNTER_END (before boss respawn)
	-- 10s should be far enough to prevent it and few enough not to occur once pull (respawn time, pull time)
	
	-- antispam: disable notifies for 10s
	Aye.modules.PullTime.disableNotify = true;
	Aye.modules.PullTime.CleardisableNotifyTimerFunction = Aye.libs.Timer:ScheduleTimer("PullTime_enableNotify", 10);
end;

Aye.modules.PullTime.events.UNIT_TARGET = function()
	if
			not Aye.db.global.PullTime.enable
		or	(
					not Aye.db.global.PullTime.showTargetName
				and	not Aye.db.global.PullTime.showTargetPullTime
			)
	then return end;
	
	-- note only first target on boss unit targeting
	if Aye.modules.PullTime.meters.target ~= nil then return end;
	
	for i =1, 5 do
		local Unit = "boss" ..i .."target";
		if Unit ~= nil then
			local name = UnitName(Unit);
			if name ~= nil then
				-- One of bosses have a valid target
				if Aye.modules.PullTime.PlannedPullTime ~= nil then
					-- Pull countdown (or upto Aye.db.global.PullTime.metersDelayTime seconds after)
					
					local player = false;
					if (
							UnitInRaid(Unit) ~= nil
						or	UnitInParty(Unit)
						or	UnitIsUnit(Unit, "player")
					) then
						player = true;
					end;
					
					if not player then
						local members = max(1, GetNumGroupMembers());
						for i = 1, members do
							-- in raid, every player have "raidX" id where id begins from 1 and ends with member number
							-- in party, there is always "player" and every NEXT members are "partyX" where X begins from 1
							-- especially, in full party, there are: "player", "party1", "party2", "party3", "party4" and NO "party5"
							local petID = (UnitInRaid("player") and "raid" ..i or (i ==1 and "" or "party" ..i -1)) .. "pet";
							if UnitIsUnit(petID, Unit) then
								local ownerID = UnitInRaid("player") and "raid" ..i or (i ==1 and "player" or "party" ..i -1);
								local ownerName = UnitName(ownerID);
								if ownerName then
									name = name .." (" ..ownerName .."'s pet)";
								end;
							end;
						end;
					end;
					
					Aye.modules.PullTime.meters.target = {
						-- pulling unit name
						name = name,
						
						-- time beetween planned and real pull (in ms)
						ms = debugprofilestop() - Aye.modules.PullTime.PlannedPullTime,
					};
					
					Aye.modules.PullTime.meters.count = Aye.modules.PullTime.meters.count +1;
					Aye.modules.PullTime.checkReport();
				end;
			end;
		end;
	end;
end;

Aye.modules.PullTime.events.COMBAT_LOG_EVENT_UNFILTERED = function(...)
	if
			not Aye.db.global.PullTime.enable
		or	(
					not Aye.db.global.PullTime.showHitName
				and	not Aye.db.global.PullTime.showHitPullTime
			)
	then return end;
	
	-- note only first threat situation update
	if Aye.modules.PullTime.meters.hit ~= nil then return end;
	
	local _, event, _, _, sourceName = ...;
	if not string.match(event, "_DAMAGE$") then return end;
	
	local Unit = sourceName;
	if Unit == nil then
		return;
	end;
	
	local name = sourceName;
	if name == nil then
		return;
	end;
	
	-- Raid Unit Hit state changed
	if Aye.modules.PullTime.PlannedPullTime ~= nil then
		-- Pull countdown (or upto Aye.db.global.PullTime.metersDelayTime seconds after)
		
		local player = false;
		if (
				UnitInRaid(Unit) ~= nil
			or	UnitInParty(Unit)
			or	UnitIsUnit(Unit, "player")
		) then
			player = true;
		end;
		
		if not player then
			local members = max(1, GetNumGroupMembers());
			for i = 1, members do
				-- in raid, every player have "raidX" id where id begins from 1 and ends with member number
				-- in party, there is always "player" and every NEXT members are "partyX" where X begins from 1
				-- especially, in full party, there are: "player", "party1", "party2", "party3", "party4" and NO "party5"
				local petID = (UnitInRaid("player") and "raid" ..i or (i ==1 and "" or "party" ..i -1)) .. "pet";
				if UnitIsUnit(petID, Unit) then
					local ownerID = UnitInRaid("player") and "raid" ..i or (i ==1 and "player" or "party" ..i -1);
					local ownerName = UnitName(ownerID);
					if ownerName then
						name = name .." (" ..ownerName .."'s pet)";
					end;
				end;
			end;
		end;
		
		local spell = "";
		if
				event == "RANGE_SPELL_DAMAGE"
			or	event == "SPELL_DAMAGE"
			or	event == "SPELL_PERIODIC_DAMAGE"
			or	event == "SPELL_BUILDING_DAMAGE"
		then
			local _, _, _, _, _, _, _, _, _, _, _, spellID = ...;
			spell = GetSpellLink(spellID) or "";
		end;
		
		Aye.modules.PullTime.meters.hit = {
			-- pulling unit name
			name = name,
			-- pulling spell
			spell = spell,
			
			-- time beetween planned and real pull (in ms)
			ms = debugprofilestop() - Aye.modules.PullTime.PlannedPullTime,
		};
		
		Aye.modules.PullTime.meters.count = Aye.modules.PullTime.meters.count +1;
		Aye.modules.PullTime.checkReport();
	end;
end;

-- Format given time (in ms) into human friendly format
--
-- @param	{uint}		ms	time difference beetween planned and actual pull (in ms)
-- @return	{string}	O	string containing human friendly format of pull time difference
Aye.modules.PullTime.formatTime = function(ms)
	local O = ""; -- output string
	
	-- add plus or minus mark
	if ms >0 then O = "+" end;
	if ms <0 then O = "−" end;
	
	-- round abs value
	ms = math.floor(.5+ math.abs(ms));
	
	-- seconds
	if ms >=1000 then
		O = O ..math.floor(ms /1000) .."s";
	end;
	
	-- ms
	if ms %1000 then
		-- space beetween seconds and ms
		if ms >=1000 then
			O = O .." ";
		end;
		
		O = O ..math.floor(ms %1000) .."ms";
	end;
	
	return O;
end;

-- Check if can Report Pull Time and if, do so
--
-- @noparam
-- @noreturn
Aye.modules.PullTime.checkReport = function()
	local activeMeters = Aye.modules.PullTime.METERS_COUNT;
	
	if
			not Aye.db.global.PullTime.showEncounterLink
		and	not Aye.db.global.PullTime.showEncounterStartTime
	then
		activeMeters = activeMeters -1;
	end;
	if
			not Aye.db.global.PullTime.showTargetName
		and	not Aye.db.global.PullTime.showTargetPullTime
	then
		activeMeters = activeMeters -1;
	end;
	if
			not Aye.db.global.PullTime.showAggroName
		and	not Aye.db.global.PullTime.showAggroPullTime
	then
		activeMeters = activeMeters -1;
	end;
	
	if Aye.modules.PullTime.meters.count >= activeMeters then
		Aye.libs.Timer.PullTime_report();
	end;
end;

-- Report Pull Time
--
-- @noparam
-- @noreturn
Aye.libs.Timer.PullTime_report = function()
	if
			Aye.db.global.PullTime.enable
			
			-- don't show simple "Pull" or "Ninja Pull" word
		and	Aye.modules.PullTime.meters.count >0
		
			-- Aye.db.global.PullTime.showNinjaPull settings
		and (
					not Aye.modules.PullTime.NinjaPull
				or	Aye.db.global.PullTime.showNinjaPull
			)
		and	not Aye.modules.PullTime.disableNotify
		
		and (
					-- Force enable
					(
							(
									Aye.db.global.PullTime.GuildGroupForceEnable
								and	InGuildParty()
							)
						or	(
									Aye.db.global.PullTime.LFGForceEnable
								and	IsPartyLFG()
							)
						or	(
									Aye.db.global.PullTime.PvPForceEnable
								and	Aye.utils.Player.IsOnPvP()
							)
						or	(
									Aye.db.global.PullTime.OutsideInstanceForceEnable
								and	not IsInInstance()
							)
					)
					-- Disable
				or	not (
							(
									Aye.db.global.PullTime.GuildGroupDisable
								and	InGuildParty()
							)
						or	(
									Aye.db.global.PullTime.LFGDisable
								and	IsPartyLFG()
							)
						or	(
									Aye.db.global.PullTime.PvPDisable
								and	Aye.utils.Player.IsOnPvP()
							)
						or	(
									Aye.db.global.PullTime.OutsideInstanceDisable
								and	not IsInInstance()
							)
					)
			)
	then
		-- Pull Time mismatch
		local pullTimeMismatch = 0;
		local pullTimeMismatch_count = 0;
		
		-- message to be sent
		local message = "";
		-- tmp message to check if it's not too short
		local tmpInvalidMessage = nil;
		
		if Aye.modules.PullTime.meters.encounter ~= nil then
			if
					Aye.db.global.PullTime.showEncounterLink
				and	Aye.modules.PullTime.meters.encounter.link ~= ""
			then
				message = message .." on " ..Aye.modules.PullTime.meters.encounter.link;
				tmpInvalidMessage = message;
			end;
			
			if
					Aye.db.global.PullTime.showEncounterStartTime
				and	not Aye.modules.PullTime.NinjaPull
				and Aye.modules.PullTime.meters.encounter.ms ~= nil
			then
				if
						Aye.db.global.PullTime.showEncounterLink
					and	Aye.modules.PullTime.meters.encounter.link ~= ""
				then
					message = message .." (" ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.encounter.ms) ..")";
				else
					message = message .." Encounter: " ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.encounter.ms);
				end;
			end;
			
			pullTimeMismatch = pullTimeMismatch +abs(Aye.modules.PullTime.meters.encounter.ms);
			pullTimeMismatch_count = pullTimeMismatch_count +1;
		end;
		if Aye.modules.PullTime.meters.target ~= nil then
			if
					Aye.db.global.PullTime.showTargetName
				and	Aye.modules.PullTime.meters.target.name ~= ""
			then
				if message ~= "" then message = message ..", " end;
				message = message .. " Target: " ..Aye.modules.PullTime.meters.target.name;
			end;
			
			if
					Aye.db.global.PullTime.showTargetPullTime
				and	not Aye.modules.PullTime.NinjaPull
				and Aye.modules.PullTime.meters.target.ms ~= nil
			then
				if
						Aye.db.global.PullTime.showTargetName
					and	Aye.modules.PullTime.meters.target.name ~= ""
				then
					message = message .. " (" ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.target.ms) ..")";
				else
					if message ~= "" then message = message ..", " end;
					message = message .. " Target: " ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.target.ms);
				end;
			end;
			
			pullTimeMismatch = pullTimeMismatch +abs(Aye.modules.PullTime.meters.target.ms);
			pullTimeMismatch_count = pullTimeMismatch_count +1;
		end;
		if Aye.modules.PullTime.meters.aggro ~= nil then
			if
					Aye.db.global.PullTime.showAggroName
				and	Aye.modules.PullTime.meters.aggro.name ~= ""
			then
				if message ~= "" then message = message ..", " end;
				message = message .. " Aggro: " ..Aye.modules.PullTime.meters.aggro.name;
			end;
			
			if
					Aye.db.global.PullTime.showAggroPullTime
				and	not Aye.modules.PullTime.NinjaPull
				and Aye.modules.PullTime.meters.aggro.ms ~= nil
			then
				if
						Aye.db.global.PullTime.showAggroName
					and	Aye.modules.PullTime.meters.aggro.name ~= ""
				then
					message = message .. " (" ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.aggro.ms) ..")";
				else
					if message ~= "" then message = message ..", " end;
					message = message .. " Aggro: " ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.aggro.ms);
				end;
			end;
			
			pullTimeMismatch = pullTimeMismatch +abs(Aye.modules.PullTime.meters.aggro.ms);
			pullTimeMismatch_count = pullTimeMismatch_count +1;
		end;
		if Aye.modules.PullTime.meters.hit ~= nil then
			if
					Aye.db.global.PullTime.showHitName
				and	Aye.modules.PullTime.meters.hit.name ~= ""
			then
				if message ~= "" then message = message ..", " end;
				message = message .. " Hit: " ..Aye.modules.PullTime.meters.hit.name;
			end;
			
			if
					Aye.db.global.PullTime.showHitSpell
				and	Aye.modules.PullTime.meters.hit.spell ~= ""
			then
				if
						Aye.db.global.PullTime.showHitName
					and	Aye.modules.PullTime.meters.hit.name ~= ""
				then
					message = message .. " by " ..Aye.modules.PullTime.meters.hit.spell;
				else
					if message ~= "" then message = message ..", " end;
					message = message .. " Hit: " ..Aye.modules.PullTime.meters.hit.spell;
				end;
			end;
			
			if
					Aye.db.global.PullTime.showHitPullTime
				and	not Aye.modules.PullTime.NinjaPull
				and Aye.modules.PullTime.meters.hit.ms ~= nil
			then
				if
						(
								Aye.db.global.PullTime.showHitName
							and	Aye.modules.PullTime.meters.hit.name ~= ""
						)
					or	(
								Aye.db.global.PullTime.showHitSpell
							and	Aye.modules.PullTime.meters.hit.spell ~= ""
						)
				then
					message = message .. " (" ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.hit.ms) ..")";
				else
					if message ~= "" then message = message ..", " end;
					message = message .. " Hit: " ..Aye.modules.PullTime.formatTime(Aye.modules.PullTime.meters.hit.ms);
				end;
			end;
			
			pullTimeMismatch = pullTimeMismatch +abs(Aye.modules.PullTime.meters.hit.ms);
			pullTimeMismatch_count = pullTimeMismatch_count +1;
		end;
		
		if
				-- at least one Pull Time meter must be filled
				pullTimeMismatch_count >0
			and	not (
						tmpInvalidMessage ~= nil
					and	message == tmpInvalidMessage
				)
		then
			-- average of Pull Time meters
			pullTimeMismatch = pullTimeMismatch /pullTimeMismatch_count;
			
			-- add "Ninja" word
			if
					Aye.modules.PullTime.NinjaPull
				and	showNinjaWord
			then
				message = "Ninja " ..message;
			end;
			
			-- add message header
			message = "Pull" ..message;
			
			if pullTimeMismatch >Aye.db.global.PullTime.missPullTimeTolerance then
				-- misstime tolerance time exceeded, display warning
				message = GetSpellLink(176781) .." " ..message;
			elseif Aye.db.global.PullTime.showOnlyMispulled then
				-- pull time in misstime tolerance time, no warn
				return;
			end;
			
			-- add message header
			message = "[Aye] " ..message;
			
			-- display message on chosen channel
			if
					Aye.db.global.PullTime.channel == "Print"
				or	(
							(
									Aye.db.global.PullTime.channel == "RW"
								or	Aye.db.global.PullTime.channel == "Raid"
							)
						and	not IsInGroup()
					)
				or	(
							(
									Aye.db.global.PullTime.channel == "Guild"
								or	Aye.db.global.PullTime.channel == "Officer"
							)
						and	not IsInGuild()
					)
				or	(
							Aye.db.global.PullTime.forcePrintInGuildGroup
						and	InGuildParty()
					)
			then
				print(message);
			elseif Aye.db.global.PullTime.channel == "Dynamic" then
				Aye.utils.Chat.SendChatMessage(message);
			elseif Aye.db.global.PullTime.channel == "RW" then
				SendChatMessage(message, Aye.utils.Chat.GetGroupChannel(true));
			elseif Aye.db.global.PullTime.channel == "Raid" then
				SendChatMessage(message, Aye.utils.Chat.GetGroupChannel(false));
			else
				SendChatMessage(message, Aye.db.global.PullTime.channel);
			end;
			
			if IsInGroup() then
				-- tell other Aye users that we handled event already
				-- antispam: disable other's notifies for 10s
				SendAddonMessage("Aye", "PullTime",	Aye.utils.Chat.GetGroupChannel());
			end;
		end;
	end;
	
	-- Kill DBM Pull countdown watcher
	Aye.libs.Timer.PullTime_clear();
end;