--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

aEquipmentResolutionFunctions = {};

local nPendingPeasants = 0;
local nodeOccupationTable;
local nodeTrinketTable;
local nodeAncestryTable;
local nodeScrollTemplate;
local nPendingRolls = 0;
local rPendingPeasant = {};
local tItems = {};

-- Initialization
function onInit()
	ActionsManager.registerResultHandler("peasantability", onAbilityRoll);
	ActionsManager.registerResultHandler("peasantoccupation", onOccupationRoll);
	ActionsManager.registerResultHandler("peasanttrinket", onTrinketRoll);
	ActionsManager.registerResultHandler("peasantancestry", onAncestryRoll);
	ActionsManager.registerResultHandler("peasanthp", onHpRoll);

	initResolutionFunctions();
end

function initResolutionFunctions()
	aEquipmentResolutionFunctions = {
		resolveNamedEquipment,
		resolveOptionalEquipment,
		resolveRenamedEquipment,
		resolveSpellScroll,
	};
end

function isGeneratingPeasants()
	return nPendingPeasants > 0;
end

function isPeasant(nodeChar)
	return DB.getValue(nodeChar, "peasant", 0) == 1 and DB.getValue(nodeChar, "level", 0) == 0;
end

function beginGeneratingPeasants(rGenerationInfo)
	nPendingPeasants = rGenerationInfo.nCount;
	nodeOccupationTable = rGenerationInfo.nodeOccupations;
	nodeTrinketTable = rGenerationInfo.nodeTrinkets;
	nodeAncestryTable = rGenerationInfo.nodeAncestries;
	nodeScrollTemplate = rGenerationInfo.nodeScroll;
	loadItems();
	beginGeneratingPeasant();
end

function loadItems()
	tItems = {};
	local aMappings = LibraryData.getMappings("item");
	for _,vMapping in ipairs(aMappings) do
		for _,nodeItem in pairs(DB.getChildrenGlobal(vMapping)) do
			local sName = StringManager.trim(DB.getValue(nodeItem, "name", "")):lower();
			tItems[sName] = nodeItem;

			loadCommaItem(sName, nodeItem);
			loadParenthesesItem(sName, nodeItem);
		end
	end
end

function loadCommaItem(sName, nodeItem)
	-- Account for names such as "Crossbow, Heavy"
	-- Don't get fooled by "Ball Bearings (1,000)"
	local sItem, sType = sName:match("^([^,%(]+),%s*(.+)");
	if sItem and sType then
		local sNewName = sType .. " " .. sItem;
		if not tItems[sNewName] then
			tItems[sNewName] = nodeItem;
		end
	end
end

function loadParenthesesItem(sName, nodeItem)
	-- Account for names such as "Acid (Vial)" and "Arrows (20)"
	local sItem, sType = sName:match("^([^,%(]+),%s*(.+)");
	if sItem and not tItems[sItem] then
		tItems[sItem] = nodeItem;
	end
	-- Include type if not a number, for example "Bag (Small)"
	if sType and not sType:match("^[%d,]+$") then
		local sNewName = sType .. " " .. sItem;
		if not tItems[sNewName] then
			tItems[sNewName] = nodeItem;
		end
	end
end

function beginGeneratingPeasant()
	nPendingRolls = beginGeneratingAbilityScores() + 4; -- HP, Occupation, Trinket, Ancestry
	beginGeneratingHp();
	beginGeneratingTable(nodeAncestryTable, "peasantancestry");
	beginGeneratingTable(nodeOccupationTable, "peasantoccupation");
	beginGeneratingTable(nodeTrinketTable, "peasanttrinket");
end

function beginGeneratingAbilityScores()
	local nCount = 0;
	for _,sAbility in pairs(DataCommon.abilities) do
		local rRoll = {
			sType = "peasantability",
			aDice = {expr = "4d6d1"},
			sDesc = sAbility,
			nMod = 0
		};
		ActionsManager.performAction(nil, nil, rRoll);
		nCount = nCount + 1;
	end
	return nCount;
end

function beginGeneratingHp()
	local rRoll = {
		sType = "peasanthp",
		aDice = {expr = "1d4"},
		sDesc = "",
		nMod = 0,
	}
	ActionsManager.performAction(nil,nil,rRoll);
end

function beginGeneratingTable(nodeTable, sType)
	local rRoll = {
		sType = sType,
		aDice = TableManager.getTableDice(nodeTable),
		sNodeTable = nodeTable.getPath(),
		sDesc = "",
		nMod = 0,
	}
	ActionsManager.performAction(nil,nil,rRoll);
end

function onAbilityRoll(_, _, rRoll)
	rPendingPeasant.tAbilities = rPendingPeasant.tAbilities or {};
	rPendingPeasant.tAbilities[rRoll.sDesc] = ActionsManager.total(rRoll);
	tryCommitPeasant();
end

function onHpRoll(_, _, rRoll)
	rPendingPeasant.hp = ActionsManager.total(rRoll);
	tryCommitPeasant();
end

function tryGetTableResults(rRoll)
	local nodeTable = DB.findNode(rRoll.sNodeTable);
	local nTotal = ActionsManager.total(rRoll);
	return TableManager.getResults(nodeTable, nTotal);
end

function onAncestryRoll(_, _, rRoll)
	rPendingPeasant.nAncestryRoll = ActionsManager.total(rRoll);
	local aResults = tryGetTableResults(rRoll);
	for _,rResult in ipairs(aResults) do
		if rResult.sLabel == "Ancestry" then
			rPendingPeasant.sAncestry = aResults[1].sText;
		elseif rResult.sLabel == "Traits" then
			rPendingPeasant.aTraits = StringManager.split(aResults[2].sText, ",", true);
			-- Include universal traits.
			table.insert(rPendingPeasant.aTraits, "Size");
			table.insert(rPendingPeasant.aTraits, "Speed");
		end
	end
	tryCommitPeasant();
end

function onOccupationRoll(_, _, rRoll)
	rPendingPeasant.nOccupationRoll = ActionsManager.total(rRoll);
	local aResults = tryGetTableResults(rRoll);
	for _,rResult in ipairs(aResults) do
		if rResult.sLabel == "Occupation" then
			rPendingPeasant.sOccupation = aResults[1].sText;
		elseif rResult.sLabel == "Equipment" then
			rPendingPeasant.aEquipment = StringManager.split(aResults[2].sText, ",", true);
		end
	end
	tryCommitPeasant();
end

function onTrinketRoll(_, _, rRoll)
	rPendingPeasant.nTrinketRoll = ActionsManager.total(rRoll);
	local aResults = tryGetTableResults(rRoll);
	for _,rResult in ipairs(aResults) do
		if rResult.sLabel == "Equipment" then
			rPendingPeasant.sTrinket = aResults[1].sText;
			rPendingPeasant.sNodeTrinket = aResults[1].sRecord;
			break;
		end
	end
	tryCommitPeasant();
end

function tryCommitPeasant()
	nPendingRolls = nPendingRolls - 1;
	if nPendingRolls > 0 then
		return;
	end

	if not calculateHp() then
		ChatManager.Message(string.format(Interface.getString("peasnt_no_hp"), rPendingPeasant.hp), true);
		beginGeneratingPeasant();
		return;
	end

	if Session.IsHost then
		commitPeasant();
	else
		User.requestIdentity(nil, nil, nil, nil, requestResponse);
	end
end

function calculateHp()
	local nConBonus = math.floor((rPendingPeasant.tAbilities.constitution - 10) / 2);
	rPendingPeasant.hp = rPendingPeasant.hp + nConBonus;
	return rPendingPeasant.hp > 0;
end

function requestResponse(bResult, sIdentity)
	if bResult then
		commitPeasant(sIdentity);
	else
		ChatManager.SystemMessage(Interface.getString("create_peasant_failure"))
	end
end

function commitPeasant(sIdentity)
	-- Open the character sheet
	local nodePeasant;
	if Session.IsHost then
		nodePeasant = DB.createChild("charsheet");
	else
		nodePeasant = DB.findNode("charsheet." .. sIdentity);
	end
	Interface.openWindow("charsheet", nodePeasant);

	DB.setValue(nodePeasant, "peasant", "number", 1);
	commitPeasantName(nodePeasant);
	commitPeasantAbilities(nodePeasant);
	commitPeasantHp(nodePeasant);
	commitPeasantAncestry(nodePeasant);
	commitPeasantOccupation(nodePeasant);
	commitPeasantTrinket(nodePeasant);

	rPendingPeasant = {};
	nPendingPeasants = nPendingPeasants - 1;
	if nPendingPeasants > 0 then
		beginGeneratingPeasant();
	end
end

function commitPeasantName(nodePeasant)
	local sBaseName;
	if Session.IsHost then
		sBaseName = "Filthy Peasant"
	else
		sBaseName = Session.UserName .. "'s Peasant";
	end

	local nNameHigh = 0;
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		local sEntryName = DB.getValue(nodeChar, "name", "");
		local sStrippedName, sNumber = CombatManager.stripCreatureNumber(sEntryName);
		if sStrippedName == sBaseName then
			local nNumber = tonumber(sNumber) or 0;
			nNameHigh = math.max(nNameHigh, nNumber);
		end
	end

	local sName = sBaseName .. " " .. nNameHigh + 1;
	DB.setValue(nodePeasant, "name", "string", sName);
end

function commitPeasantAbilities(nodePeasant)
	for sAbility,nScore in pairs(rPendingPeasant.tAbilities) do
		DB.setValue(nodePeasant, "abilities." .. sAbility .. ".score", "number", nScore);
	end
end

function commitPeasantHp(nodePeasant)
	DB.setValue(nodePeasant, "hp.total", "number", rPendingPeasant.hp);
	DB.setValue(nodePeasant, "hp.peasant", "number", rPendingPeasant.hp); -- For Constitutional Amendments to calculate.
end

function commitPeasantAncestry(nodePeasant)
	local nodeAncestry, nodeHeritage = resolveAncestryAndHeritage();
	if not nodeAncestry then
		addFailedResolutionNote(nodePeasant, "Ancestry", rPendingPeasant.sAncestry, rPendingPeasant.nAncestryRoll, nodeAncestryTable);
		return;
	end

	local rAdd = CharManager.helperBuildAddStructure(nodePeasant, "reference_race", nodeAncestry.getPath());
	CharRaceManager.helperAddRaceMain(rAdd);

	if nodeHeritage then
		rAdd.sSubraceChoice = StringManager.trim(DB.getValue(nodeHeritage, "name", ""));
		CharRaceManager.helperAddRaceSubrace(rAdd);
	end
end

function resolveAncestryAndHeritage()
	local nodeAncestry = RecordManager.findRecordByStringI("race", "name", rPendingPeasant.sAncestry);
	local nodeHeritage, sAncestry, sHeritage;
	if nodeAncestry then
		sAncestry = rPendingPeasant.sAncestry;
		sHeritage, nodeHeritage = selectHeritage();
	else
		sAncestry, nodeAncestry = CharRaceManager.getRaceFromSubrace(rPendingPeasant.sAncestry);
		nodeHeritage = resolveHeritage(sAncestry);
	end

	return nodeAncestry, nodeHeritage;
end

function selectHeritage()
	local sHeritage, nodeHeritage;
	local tHeritages = CharRaceManager.getRaceSubraceOptions(rPendingPeasant.sAncestry);
	if #tHeritages > 0 then
		local index = 1;
		local nHeritage = math.random(#tHeritages);
		for _,rHeritage in pairs(tHeritages) do
			if index == nHeritage then
				sHeritage = rHeritage.text;
				nodeHeritage = DB.findNode(rHeritage.linkrecord);
				break;
			end
			index = index + 1;
		end
	end
	return sHeritage, nodeHeritage;
end

function resolveHeritage(sAncestry)
	local tHeritages = CharRaceManageer.getRaceSubraceOptions(sAncestry);
	local rHeritage = tHeritages[rPendingPeasant.sAncestry];
	if rHeritage then
		return DB.findNode(rHeritage.linkrecord);
	end
end

function commitPeasantOccupation(nodePeasant)
	if (rPendingPeasant.sOccupation or "") == "" then
		addMissingResultNote(nodePeasant, "Occupation", rPendingPeasant.nOccupationRoll, nodeOccupationTable);
	else
		addNode(nodePeasant, "Peasant Occuptaion - " .. rPendingPeasant.sOccupation);
	end

	for _,sEquipment in ipairs(rPendingPeasant.aEquipment) do
		commitPeasantEquipment(nodePeasant, sEquipment);
	end
end

function commitPeasantEquipment(nodePeasant, sEquipment)
	local nCount;
	local sDice, sEquipmentName = sEquipment:match("%[([^%]]+)%]%s*(.*)");
	if sDice then
		nCount = DiceManager.evalDiceString(sDice);
	else
		sEquipmentName = sEquipment;
	end

	local rResult = resolveEquipment(sEquipmentName);
	if rResult and rResult.nodeItem then
		local nodeItem = ItemManager.handleItem(nodePeasant, "inventorylist", "item", rResult.nodeItem.getPath());
		if (rResult.sName or "") ~= "" then
			DB.setValue(nodeItem, "name", "string", rResult.sName);
		end
		if (nCount or 0) ~= 0 then
			DB.setValue(nodeItem, "count", "number", rResult.nCount);
		end
		if rResult.nodeCantrip then
			local sFormat = "<linklist><link class=\"reference_spell\" recordname=\"%s\"><b>Spell: </b>%s</link></linklist>%s";
			local sDescription = string.format(sFormat,
				rResult.nodeCantrip.getPath(),
				DB.getValue(rResult.nodeCantrip, "name", ""),
				DB.getValue(nodeItem, "description", ""));
			DB.setValue(nodeItem, "description", "formattedtext", sDescription);

			if ItemManagerKNK then
				PowerManager.addPower("reference_spell", rResult.nodeCantrip, nodeItem);
			end
		end
	else
		addFailedResolutionNote(nodePeasant, "Equipment", sEquipment, rPendingPeasant.nOccupationRoll, nodeOccupationTable);
	end
end

function resolveEquipment(sEquipment)
	local aResults;
	for _,fResolve in ipairs(aEquipmentResolutionFunctions) do
		aResults = fResolve(sEquipment);
		if aResults then
			break;
		end
	end
	return aResults;
end

function resolveNamedEquipment(sEquipment)
	local nodeItem = tItems[sEquipment:lower()];
	if nodeItem then
		return { nodeItem = nodeItem };
	end
end

function resolveRenamedEquipment(sEquipment)
	local sItem = sEquipment:match("[^(]+ %(as ([^)]+)");
	if sItem then
		local nodeItem = tItems[sItem:lower()];
		if nodeItem then
			return {
				nodeItem = nodeItem,
				sName = sEquipment
			};
		end
	end
end

function resolveOptionalEquipment(sEquipment)
	local aOptions = {};
	local sRemainder = sEquipment;
	local sCurrent, sPrevious;
	repeat
		sPrevious = sRemainder;
		sCurrent, sRemainder = sPrevious:match("^(.+)%sor%s(.+)")
		if sCurrent then
			table.insert(aOptions, sCurrent);
		end
	until not sRemainder;

	table.insert(aOptions, sPrevious);

	if #aOptions > 1 then
		local nOption = math.random(#aOptions);
		return resolveEquipment(StringManager.trim(aOptions[nOption]));
	end
end

function resolveSpellScroll(sEquipment)
	local sLevels, sList = sEquipment:match("spell scroll with a (.+) from the (.+) spell list");
	local nMinLevel = 0;
	local nMaxLevel = 0;
	if sLevels then
		local sMin, sMax = sLevels:match("(.+) through (.+)");
		if sMin then
			nMinLevel = parseSpellLevel(sMin);
			nMaxLevel = math.max(nMinLevel, parseSpellLevel(sMax));
		else
			nMinLevel = parseSpellLevel(sLevels);
			nMaxLevel = nMinLevel;
		end
	end

	if sList then
		local rSpellList = ClassSpellListManager.getClassSpellListRecord(sList);

		local aCantrips = {};
		for _,nodeSpell in ipairs(rSpellList.tSpells) do
			local nLevel =  DB.getValue(nodeSpell, "level", -1);
			if nMinLevel <= nLevel and nLevel <= nMaxLevel then
				table.insert(aCantrips, nodeSpell);
			end
		end

		if #aCantrips > 0 then
			local nCantrip = math.random(#aCantrips);
			local nodeCantrip = aCantrips[nCantrip];
			return {
				nodeItem = nodeScrollTemplate,
				sName = "Scroll of ".. DB.getValue(nodeCantrip, "name", ""),
				nodeCantrip = nodeCantrip,
			};
		end
	end
end

function parseSpellLevel(sLevel)
	return tonumber(sLevel:match("[1-9]")) or 0;
end

function commitPeasantTrinket(nodePeasant)
	local nodeTrinket = DB.findNode(rPendingPeasant.sNodeTrinket);
	if not nodeTrinket then
		addFailedResolutionNote(nodePeasant, "Trinket", rPendingPeasant.sTrinket, rPendingPeasant.nTrinketRoll, nodeTrinketTable);
		return;
	end

end

function addFailedResolutionNote(nodePeasant, sType, sResult, nResult, nodeTable)
	local sTable = DB.getValue(nodeTable, "name", Interface.getString("unnamed_table"));
	local sNote = string.format(Interface.getString("failed_table_resolution"), sType, sResult, nResult, sTable);
	addNode(nodePeasant, sNote);
end

function addMissingResultNote(nodePeasant, sType, nResult, nodeTable)
	local sTable = DB.getValue(nodeTable, "name", Interface.getString("unnamed_table"));
	local sNote = string.format(Interface.getString("missing_table_result"), nResult, sTable, sType);
	addNode(nodePeasant, sNote);
end

function addNode(nodePeasant, sNewNote)
	local sNote = DB.getValue(nodePeasant, "notes", "");
	if sNote ~= "" then
		sNote = sNote .. "\n";
	end
	sNote = sNote .. sNewNote;
	DB.setValue(nodePeasant, "notes", "string", sNote);
end