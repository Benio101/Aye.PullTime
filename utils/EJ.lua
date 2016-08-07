local Aye = Aye;
Aye.utils.EJ = Aye.utils.EJ or {};

-- Get Current Encounter Info
-- return information about EJ_GetMapEncounter encounter closest to player
-- 
-- @noparam
-- @return	{uint}		encounterX		x coord
-- @return	{uint}		encounterY		y coord
-- @return	{uint}		instanceID		instance ID
-- @return	{string}	name			encounter name
-- @return	{string}	description		encounter description
-- @return	{uint}		encounterID		encounter ID
-- @return	{uint}		rootSectionID	root section ID
-- @return	{string}	link			formatted link
Aye.utils.EJ.GetCurrentEncounter = Aye.utils.EJ.GetCurrentEncounter or function()
	local x, y = GetPlayerMapPosition("player"); -- player position
	local minDistance =nil;
	
	local closestEncounterX = nil;
	local closestEncounterY = nil;
	local closestEncounterInstanceID = nil;
	local closestEncounterName = nil;
	local closestEncounterDescription = nil;
	local closestEncounterEncounterID = nil;
	local closestEncounterRootSectionID = nil;
	local closestEncounterLink = nil;
	
	-- EJ_GetMapEncounter loop through map encounters
	local i =1;
	while(true) do
		local encounterX, encounterY, instanceID, name, description, encounterID, rootSectionID, link = EJ_GetMapEncounter(i);
		
		-- return encounter with shortest distance from player
		if encounterID ~= nil and encounterID >0 then
			local distance = math.sqrt(
					math.pow(x -encounterX,    2)
				+	math.pow(y +encounterY -1, 2)
			);
			
			if
					minDistance == nil
				or	distance < minDistance
			then
				minDistance = distance;
				
				closestEncounterX = encounterX;
				closestEncounterY = encounterY;
				closestEncounterInstanceID = instanceID;
				closestEncounterName = name;
				closestEncounterDescription = description;
				closestEncounterEncounterID = encounterID;
				closestEncounterRootSectionID = rootSectionID;
				closestEncounterLink = link;
			end;
			
			i = i +1;
		else
			break;
		end;
	end;
	
	return
		closestEncounterX,
		closestEncounterY,
		closestEncounterInstanceID,
		closestEncounterName,
		closestEncounterDescription,
		closestEncounterEncounterID,
		closestEncounterRootSectionID,
		closestEncounterLink
	;
end