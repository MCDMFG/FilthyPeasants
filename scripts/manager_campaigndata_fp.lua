--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local handleDropOriginal;

function onInit()
	handleDropOriginal = CampaignDataManager2.handleDrop;
	CampaignDataManager2.handleDrop = handleDrop;
end

function handleDrop(sTarget, draginfo)
	local result = handleDropOriginal(sTarget, draginfo);
	if not result then
		if sTarget == "race_peasant_traits" then
			result = handlePeasantTraitDrop(draginfo);
		end
	end
	return result;
end

function handlePeasantTraitDrop(draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	local nodeSource = DB.findNode(sRecord);
	local rAdd = {
		nodeSource = nodeSource,
		sSourceClass = sClass,
	};
	CharRaceManagerFP.getTraitRaceInfo(rAdd);

	local sRootMapping = LibraryData.getRootMapping("race_peasant_traits");
	local nodeTarget = DB.createChild(sRootMapping);
	local sTrait = DB.getValue(nodeSource, "name");
	DB.setValue(nodeTarget, "name", "string", sTrait);
	DB.setValue(nodeTarget, "race", "string", rAdd.sRace);
	DB.setValue(nodeTarget, "subrace", "string", rAdd.sSubrace);
	return true;
end