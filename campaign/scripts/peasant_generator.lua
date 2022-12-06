--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onGenerateButtonPressed()
	local _, sEquipment = equipment.getValue();
	local _, sOccupations = occupations.getValue();
	local _, sTrinkets = trinkets.getValue();
	local _, sAncestries = ancestries.getValue();
	local _, sScroll = scroll.getValue();
	local aRecords = { sEquipment, sOccupations, sTrinkets, sAncestries, sScroll };
	if not ModuleManager.handleRecordModulesLoad(aRecords, generatePeasants) then
		generatePeasants();
	end
end

function generatePeasants()
	local rInfo = {
		nCount = count.getValue(),
		nodeEquipment = equipment.getTargetDatabaseNode(),
		nodeOccupations = occupations.getTargetDatabaseNode(),
		nodeTrinkets = trinkets.getTargetDatabaseNode(),
		nodeAncestries = ancestries.getTargetDatabaseNode(),
		nodeScroll = scroll.getTargetDatabaseNode(),
	};
	PeasantManager.beginGeneratingPeasants(rInfo);
	close();
end