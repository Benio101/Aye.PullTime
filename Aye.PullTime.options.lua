local Aye = Aye;
if not Aye.load then return end;

Aye.options.args.PullTime = {
	name = "Pull Time Info",
	type = "group",
	args = {
		header1 = {
			order = 1,
			type = "header",
			name = "Pull Time Info",
		},
		description2 = {
			order = 2,
			type = "description",
			name = "Show who pulled the boss with difference beetween planned pull |cff9d9d9d(in ms)|r. "
				.. "If difference will be bigger than tolerated, additional " .. GetSpellLink(176781) .. " note will be applied, ex.:\n\n"
				.. "|c" .. RAID_CLASS_COLORS[select(2, UnitClass("player"))].colorStr .. UnitName("player") .. "|r:"
				.. " Pull on |cff66bbff|Hjournal:1:1372:16|h[Gorefiend]|h|r (−6ms), Target: Foo (−2ms), Aggro: Bar (+3ms)\n"
				.. "|c" .. RAID_CLASS_COLORS[select(2, UnitClass("player"))].colorStr .. UnitName("player") .. "|r: " .. GetSpellLink(176781)
				.. " Pull on |cff66bbff|Hjournal:1:1438:16|h[Archimonde]|h|r (+991s), Target: Foo (Bar's Pet) (+1m 17s)\n"
			,
		},
		enable = {
			order = 3,
			name = "Enable",
			desc = "Enable Pull Time Info",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.enable end,
			set = function(_, v) Aye.db.global.PullTime.enable = v end,
		},
		execute5 = {
			order = 5,
			type = "execute",
			name = "Disable & Reload",
			func = function() DisableAddOn("Aye.PullTime"); ReloadUI(); end,
			hidden = function() return Aye.db.global.PullTime.enable end,
		},
		description6 = {
			order = 6,
			type = "description",
			name = "This module is currently temporary |cff9d9d9ddisabled|r at will and should no longer work.\n"
				.. "|cff9d9d9dIf you wish to keep this module disabled, you should disable related addon completelly.\n"
				.. "You can always re–enable module by re–enabling related addon addon the same way.\n|r"
			,
			hidden = function() return Aye.db.global.PullTime.enable end,
		},
		execute7 = {
			order = 7,
			type = "execute",
			name = "Default module settings",
			desc = "Reset settings of this module to default.\n\n|cff9d9d9dIf you wish to reset settings of all Aye modules instead, "
				.. "use \"Defaults\" options from left bottom corner of \"Interface\" window, then select \"These Settings\".|r"
			,
			func = function()
				Aye.db.global.PullTime = CopyTable(Aye.default.global.PullTime);
				Aye.libs.ConfigRegistry:NotifyChange("Aye");
			end,
			hidden = function() return not Aye.db.global.PullTime.enable end,
		},
		header11 = {
			order = 11,
			type = "header",
			name = "Mispull options",
		},
		missPullTimeTolerance = {
			order = 13,
			name = "Misspull Time Tolerance |cff9d9d9d(in ms)|r",
			desc = "Time allowed beetween planned pull",
			type = "range",
			min = 0,
			max = 5000,
			softMin = 0,
			softMax = 1000,
			bigStep = 100,
			get = function() return Aye.db.global.PullTime.missPullTimeTolerance end,
			set = function(_, v) Aye.db.global.PullTime.missPullTimeTolerance = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		showOnlyMispulled = {
			order = 14,
			name = "Show only if mispulled",
			desc = "If pull was made in a toleranted time, don't output any information",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showOnlyMispulled end,
			set = function(_, v) Aye.db.global.PullTime.showOnlyMispulled = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		header21 = {
			order = 21,
			type = "header",
			name = "Meters options",
		},
		description22 = {
			order = 22,
			type = "description",
			name = "Configure Pull Time meters |cff9d9d9d(indicators)|r options. |cffe6cc80Recommendation|r|cff9d9d9d: Enable all meters to gain a full view on Pull Time|r. "
				.. "In case of multiple meters, |cffe6cc80Misspull Time Tolerance|r option refers to arithmetic average of enabled Pull Time meters.\n"
			,
		},
		showEncounterLink = {
			order = 24,
			name = "|cffe6cc80Show|r Encounter Link",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showEncounterLink end,
			set = function(_, v) Aye.db.global.PullTime.showEncounterLink = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		showEncounterStartTime = {
			order = 25,
			name = "|cffe6cc80Show|r Encounter Start Time",
			desc = "Show the difference beetween planned Pull Time and an Encounter Start Time |cff9d9d9d(in ms)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showEncounterStartTime end,
			set = function(_, v) Aye.db.global.PullTime.showEncounterStartTime = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showTargetName = {
			order = 27,
			name = "|cffe6cc80Show|r Target Name",
			desc = "|cffe6cc80Show|r the Name of Boss Target on first Boss Target Change since Pull Timer",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showTargetName end,
			set = function(_, v) Aye.db.global.PullTime.showTargetName = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showTargetPullTime = {
			order = 28,
			name = "|cffe6cc80Show|r Target Pull Time",
			desc = "|cffe6cc80Show|r the difference beetween planned Pull Time and the first Boss Target Change since Pull Timer |cff9d9d9d(in ms)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showTargetPullTime end,
			set = function(_, v) Aye.db.global.PullTime.showTargetPullTime = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showAggroName = {
			order = 30,
			name = "|cffe6cc80Show|r Aggro Name",
			desc = "|cffe6cc80Show|r the Name of Boss Aggroed unit on first Boss Aggro Change since Pull Timer",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showAggroName end,
			set = function(_, v) Aye.db.global.PullTime.showAggroName = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showAggroPullTime = {
			order = 31,
			name = "|cffe6cc80Show|r Aggro Pull Time",
			desc = "|cffe6cc80Show|r the difference beetween planned Pull Time and the first Boss Aggro Change since Pull Timer |cff9d9d9d(in ms)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showAggroPullTime end,
			set = function(_, v) Aye.db.global.PullTime.showAggroPullTime = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showHitName = {
			order = 33,
			name = "|cffe6cc80Show|r First Hit Name",
			desc = "|cffe6cc80Show|r the Name of unit who made first hit since Pull Timer",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showHitName end,
			set = function(_, v) Aye.db.global.PullTime.showHitName = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitSpell
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showHitSpell = {
			order = 34,
			name = "|cffe6cc80Show|r First Hit Spell",
			desc = "|cffe6cc80Show|r the Spell that caused first hit since Pull Timer",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showHitSpell end,
			set = function(_, v) Aye.db.global.PullTime.showHitSpell = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitPullTime
					)
			end,
		},
		showHitPullTime = {
			order = 35,
			name = "|cffe6cc80Show|r First Hit Pull Time",
			desc = "|cffe6cc80Show|r the difference beetween planned Pull Time and the first hit since Pull Timer |cff9d9d9d(in ms)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showHitPullTime end,
			set = function(_, v) Aye.db.global.PullTime.showHitPullTime = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	(
							not Aye.db.global.PullTime.showEncounterStartTime
						and	not Aye.db.global.PullTime.showTargetName
						and	not Aye.db.global.PullTime.showTargetPullTime
						and	not Aye.db.global.PullTime.showAggroName
						and	not Aye.db.global.PullTime.showAggroPullTime
						and	not Aye.db.global.PullTime.showHitName
						and	not Aye.db.global.PullTime.showHitSpell
					)
			end,
		},
		header36 = {
			order = 36,
			type = "header",
			name = "Delay options",
		},
		enableDelay = {
			order = 37,
			name = "|cffe6cc80Enable|r Delaying Info",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.enableDelay end,
			set = function(_, v) Aye.db.global.PullTime.enableDelay = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		metersDelayTime = {
			order = 38,
			name = "Maximum Delay |cff9d9d9d(in s)|r",
			type = "range",
			min = 0,
			max = 60,
			softMin = 0,
			softMax = 10,
			bigStep = 1,
			get = function() return Aye.db.global.PullTime.metersDelayTime end,
			set = function(_, v) Aye.db.global.PullTime.metersDelayTime = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	not Aye.db.global.PullTime.enableDelay
			end,
		},
		description39 = {
			order = 39,
			type = "description",
			name = "\nPull Time information is sent to chat once all chosen meters are filled. "
				.. "|cffe6cc80Maximum Delay|r determined maximum waiting time for all meters. "
				.. "If chosen time |cff9d9d9d(in s)|r will pass, Pull Time information will be sent on chat even if incomplete |cff9d9d9d(not all indicators are available)|r.\n\n"
				.. "|cff9d9d9dIf Showing Delay is disabled, Pull Time information can eventually never show, or show with very low chance of reporting correct units and times.|r "
				.. "|cffe6cc80Recommendation|r|cff9d9d9d: keep this option enabled at all time, eventually adjusting |cffe6cc80Maximum Delay|r time.|r\n"
			,
		},
		header41 = {
			order = 41,
			type = "header",
			name = "Ninja options",
		},
		showNinjaPull = {
			order = 43,
			name = "|cffe6cc80Show|r Ninja Pulls |cff9d9d9d(Pulls without Pull Timer that won't contain Pull Timers)",
			type = "toggle",
			width = "full",
			get = function() return Aye.db.global.PullTime.showNinjaPull end,
			set = function(_, v) Aye.db.global.PullTime.showNinjaPull = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		showNinjaWord = {
			order = 44,
			name = "|cffe6cc80Show|r |cff9d9d9d\"|r|cffe6cc80Ninja|r|cff9d9d9d\"|r Pull word",
			desc = "|cffe6cc80Show|r |cff9d9d9d\"|r|cffe6cc80Ninja Pull|r|cff9d9d9d\"|r instead of simple |cff9d9d9d\"|r|cffe6cc80Pull|r|cff9d9d9d\"|r on Ninja Pulls.",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showNinjaWord end,
			set = function(_, v) Aye.db.global.PullTime.showNinjaWord = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	not Aye.db.global.PullTime.showNinjaPull
			end,
		},
		showNinjaTimes = {
			order = 46,
			name = "|cffe6cc80Show|r Ninja Pull times",
			desc = "By default, timers are not shown on Ninja Pulls as there is not planned pull time.\n\n"
				.. "However, if enabled, times will be shown relative to encounter start time instead."
			,
			type = "toggle",
			get = function() return Aye.db.global.PullTime.showNinjaTimes end,
			set = function(_, v) Aye.db.global.PullTime.showNinjaTimes = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	not Aye.db.global.PullTime.showNinjaPull
			end,
		},
		header51 = {
			order = 51,
			type = "header",
			name = "Instance Filter",
		},
		GuildGroupDisable = {
			order = 53,
			name = "|cffe6cc80Disable|r in Ally Group",
			desc = "|cffe6cc80Disable|r in Ally Group |cff9d9d9d(at least half of other members are either friends or guildmates)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.GuildGroupDisable end,
			set = function(_, v) Aye.db.global.PullTime.GuildGroupDisable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.GuildGroupForceEnable
			end,
		},
		LFGDisable = {
			order = 54,
			name = "|cffe6cc80Disable|r in LFG group",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.LFGDisable end,
			set = function(_, v) Aye.db.global.PullTime.LFGDisable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.LFGForceEnable
			end,
		},
		PvPDisable = {
			order = 56,
			name = "|cffe6cc80Disable|r on PvP",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.PvPDisable end,
			set = function(_, v) Aye.db.global.PullTime.PvPDisable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.PvPForceEnable
			end,
		},
		OutsideInstanceDisable = {
			order = 57,
			name = "|cffe6cc80Disable|r outside Instance",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.OutsideInstanceDisable end,
			set = function(_, v) Aye.db.global.PullTime.OutsideInstanceDisable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.OutsideInstanceForceEnable
			end,
		},
		header61 = {
			order = 61,
			type = "header",
			name = "Force Enable",
		},
		description62 = {
			order = 62,
			type = "description",
			name = "|cffe6cc80Force Enable|r Pull Time independing of Instance Filter.\n",
		},
		GuildGroupForceEnable = {
			order = 63,
			name = "|cffe6cc80Force Enable|r in Ally Group",
			desc = "|cffe6cc80Force Enable|r in Ally Group |cff9d9d9d(at least half of other members are either friends or guildmates)|r",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.GuildGroupForceEnable end,
			set = function(_, v) Aye.db.global.PullTime.GuildGroupForceEnable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.GuildGroupDisable
			end,
		},
		LFGForceEnable = {
			order = 64,
			name = "|cffe6cc80Force Enable|r in LFG group",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.LFGForceEnable end,
			set = function(_, v) Aye.db.global.PullTime.LFGForceEnable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.LFGDisable
			end,
		},
		PvPForceEnable = {
			order = 66,
			name = "|cffe6cc80Force Enable|r on PvP",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.PvPForceEnable end,
			set = function(_, v) Aye.db.global.PullTime.PvPForceEnable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.PvPDisable
			end,
		},
		OutsideInstanceForceEnable = {
			order = 67,
			name = "|cffe6cc80Force Enable|r outside Instance",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.OutsideInstanceForceEnable end,
			set = function(_, v) Aye.db.global.PullTime.OutsideInstanceForceEnable = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.OutsideInstanceDisable
			end,
		},
		header91 = {
			order = 91,
			type = "header",
			name = "Force Disable",
		},
		description92 = {
			order = 92,
			type = "description",
			name = "|cffe6cc80Force Disable|r is most important and overwrites even |cffe6cc80Force Enable|r.\n",
		},
		ForceDisableIfMythicBenched = {
			order = 93,
			name = "|cffe6cc80Force Disable|r if Mythic Benched |cff9d9d9d(in Ally Group outside party #1–4)|r",
			desc = "|cffe6cc80Force Disable|r in Ally Group |cff9d9d9d(at least half of other members are either friends or guildmates)|r on Mythic difficulty if outside party #1–4.\n\n"
				.. "|cffe6cc80Force Disable|r|cff9d9d9d is most important and overwrites |cffe6cc80Force Enable|r|cff9d9d9d.|r"
			,
			type = "toggle",
			width = "full",
			get = function() return Aye.db.global.PullTime.ForceDisableIfMythicBenched end,
			set = function(_, v) Aye.db.global.PullTime.ForceDisableIfMythicBenched = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		header111 = {
			order = 111,
			type = "header",
			name = "Chat Channel",
		},
		description112 = {
			order = 112,
			type = "description",
			name = "\"|cffe6cc80Raid|r\" means \"|cfff3e6c0Instance|r\" in LFR, or \"|cfff3e6c0Party|r\" if player is not in raid."
				.. "\n\"|cffe6cc80Raid Warning|r\" channel behaves like \"|cffe6cc80Raid|r\" if player cannot Raid Warning."
				.. "\n\"|cffe6cc80Dynamic|r\" is min. channel, where everybody can hear you (\"|cfff3e6c0Say|r\", \"|cfff3e6c0Yell|r\", or \"|cffe6cc80Raid|r\").\n"
			,
		},
		channel = {
			order = 113,
			name = "Chat Channel",
			desc = "The chat channel where message will be sent",
			type = "select",
			values = {
				Print	= "|cff9d9d9dPrint|r",
				Say		= "|cffffffffSay|r",
				Yell	= "|cffffffffYell|r",
				Raid	= "|cffe6cc80Raid|r",
				RW		= "|cffe6cc80Raid Warning|r",
				Dynamic	= "|cffe6cc80Dynamic|r",
				Guild	= "|cffffffffGuild|r",
				Officer	= "|cffffffffOfficer|r",
			},
			get = function() return Aye.db.global.PullTime.channel end,
			set = function(_, v) Aye.db.global.PullTime.channel = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		forcePrintInGuildGroup = {
			order = 114,
			name = "|cffe6cc80Force Print|r in Ally Group",
			desc = "In Ally Group |cff9d9d9d(at least half of other members are either friends or guildmates)|r prints message instead of sending it on chat",
			type = "toggle",
			get = function() return Aye.db.global.PullTime.forcePrintInGuildGroup end,
			set = function(_, v) Aye.db.global.PullTime.forcePrintInGuildGroup = v end,
			disabled = function() return
					not Aye.db.global.PullTime.enable
				or	Aye.db.global.PullTime.channel == "Print"
			end,
		},
		reportWithAyePrefix = {
			order = 117,
			name = "Add inline |cff9d9d9d\"[|r|cffe6cc80Aye|r|cff9d9d9d] \"|r prefix before message",
			type = "toggle",
			width = "full",
			get = function() return Aye.db.global.PullTime.reportWithAyePrefix end,
			set = function(_, v) Aye.db.global.PullTime.reportWithAyePrefix = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		reportWithWarningPrefix = {
			order = 118,
			name = "Add inline |cff9d9d9d\"" ..GetSpellLink(176781) .." \"|r prefix before message",
			type = "toggle",
			width = "full",
			get = function() return Aye.db.global.PullTime.reportWithWarningPrefix end,
			set = function(_, v) Aye.db.global.PullTime.reportWithWarningPrefix = v end,
			disabled = function() return not Aye.db.global.PullTime.enable end,
		},
		header151 = {
			order = 151,
			type = "header",
			name = "Antispam",
		},
		description152 = {
			order = 152,
			type = "description",
			name = "Prevent sending pull time information multiple times within small amount of time.\n\n"
				.. "Once all pull times are fully determined, it is required to pass some time before reporting it, "
				.. "waiting for eventual addon messages from other members saying that they sent pull timer information already, so we will refrain from repeating same pull time information.\n\n"
				.. "|cffe6cc80Pull Time Info|r value should be slightly higher than the highest ping of any group member on any time during reports |cff9d9d9d(if unsure, |cffe6cc801000|rms is usually an optimal value)|r.\n"
			,
		},
		antispamCooldown = {
			order = 154,
			name = "Antispam Cooldown |cff9d9d9d(in s)|r",
			desc = "Minimum amount of time |cff9d9d9d(in seconds)|r that must pass before sending pull time information again.",
			type = "range",
			min = 0,
			max = 60,
			softMin = 5,
			softMax = 30,
			bigStep = 5,
			get = function() return Aye.db.global.Warnings.antispamCooldown end,
			set = function(_, v) Aye.db.global.Warnings.antispamCooldown = v end,
			disabled = function() return
					not Aye.db.global.Warnings.enable
				or	(
							not Aye.db.global.Warnings.enableReadyCheck
						and	not Aye.db.global.Warnings.enablePull
					)
			end,
		},
		antispamReportDelay = {
			order = 155,
			name = "Pull Time Info Delay |cff9d9d9d(in ms)|r",
			desc = "Pull Time Info Delay by specified amount of time |cff9d9d9d(in milliseconds)|r.\n\n",
			type = "range",
			min = 0,
			max = 5000,
			softMin = 0,
			softMax = 3000,
			bigStep = 200,
			get = function() return Aye.db.global.Warnings.antispamReportDelay end,
			set = function(_, v) Aye.db.global.Warnings.antispamReportDelay = v end,
			disabled = function() return
					not Aye.db.global.Warnings.enable
				or	(
							not Aye.db.global.Warnings.enableReadyCheck
						and	not Aye.db.global.Warnings.enablePull
					)
			end,
		},
	},
};