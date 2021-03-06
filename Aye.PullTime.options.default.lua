local Aye = Aye;
if not Aye.load then return end;

Aye.default.global.PullTime = {
	enable = true,						-- Enable Pull Time Info
	missPullTimeTolerance = 500,		-- Misspull Time Tolerance (ms)
	showOnlyMispulled = false,			-- Don't info if not mispulled
	showEncounterLink = true,			-- Show Encounter Link
	showEncounterStartTime = true,		-- Show Encounter Start Time
	showInstanceLink = false,			-- Show Instance Link
	showTargetName = true,				-- Show Target Name
	showTargetPullTime = true,			-- Show Target Pull Time
	showAggroName = true,				-- Show Aggro Name
	showAggroPullTime = true,			-- Show Aggro Pull Time
	showHitName = true,					-- Show Hit Name
	showHitSpell = true,				-- Show Hit Spell
	showHitPullTime = true,				-- Show Hit Pull Time
	enableDelay = true,					-- Enable Delay
	metersDelayTime = 5,				-- Maximum Delay (in s)
	showNinjaPull = true,				-- Show Ninja Pulls
	showNinjaWord = false,				-- Show "Ninja" Pull word
	showNinjaTimes = false,				-- Show Ninja Pull times
	GuildGroupDisable = false,			-- Disable in Guild group
	LFGDisable = false,					-- Disable in LFG group
	PvPDisable = true,					-- Disable on PvP (arena, battleground)
	OutsideInstanceDisable = false,		-- Disable outside Instance
	GuildGroupForceEnable = true,		-- Force Enable in Guild group
	LFGForceEnable = false,				-- Force Enable in LFG group
	PvPForceEnable = false,				-- Force Enable on PvP (arena, battleground)
	OutsideInstanceForceEnable = false,	-- Force Enable outside Instance
	ForceDisableIfBenched = true,		-- Force Disable if Benched
	channel = "Raid",					-- The chat channel where message will be sent
	forcePrintInGuildGroup = false,		-- In Guild group prints message instead of sending it on chat
	reportWithAyePrefix = false,		-- Add inline "[Aye] " prefix before message
	reportWithWarningPrefix = false,	-- Add inline "[WARNING!] " prefix before message
	antispamCooldown = 10,				-- Antispam Cooldown (in s)
	antispamReportDelay = 1000,			-- Ansitpam Report Delay (in ms)
};