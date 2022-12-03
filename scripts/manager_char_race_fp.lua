--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local helperAddRaceTraitMainOriginal;

aGlobalRacePeasantTraits = {
	"size",
	"speed",
	"subrace",
};

function onInit()
	helperAddRaceTraitMainOriginal = CharRaceManager.helperAddRaceTraitMain;
	CharRaceManager.helperAddRaceTraitMain = helperAddRaceTraitMain;
end

function helperAddRaceTraitMain(rAdd)
	local bShouldAdd = true;
	if PeasantManager.isGeneratingPeasants() and PeasantManager.isPeasant(rAdd.nodeChar) then
		bShouldAdd = StringManager.contains(aGlobalRacePeasantTraits, rAdd.sSourceName:lower());
		if not bShouldAdd then
			bShouldAdd = isPeasantTrait(rAdd);
		end
	end

	if bShouldAdd then
		helperAddRaceTraitMainOriginal(rAdd);
	end
end

function isPeasantTrait(rAdd)
	local bResult = false;
	for _,nodeTrait in pairs(DB.getChildrenGlobal("race_peasant_traits")) do
		if rAdd.sSourceName:lower() == StringManager.trim(DB.getValue(nodeTrait, "name", "")):lower() then
			getTraitRaceInfo(rAdd);
			bResult = rAdd.sRace:lower() == StringManager.trim(DB.getValue(nodeTrait, "race", "")):lower()
				and rAdd.sSubrace:lower() == StringManager.trim(DB.getValue(nodeTrait, "subrace", "")):lower();
		end
		if bResult then
			break;
		end
	end
	return bResult;
end

function getTraitRaceInfo(rAdd)
	if rAdd.sSourceClass == "reference_racialtrait" then
		rAdd.sRace = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
		rAdd.sSubrace = "";
	elseif rAdd.sSourceClass == "reference_subracialtrait" then
		rAdd.sSubrace = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
		rAdd.sRace = CharRaceManager.getRaceFromSubrace(rAdd.sSubrace);
	end
end