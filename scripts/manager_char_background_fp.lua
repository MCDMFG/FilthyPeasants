--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local addBackgroundOriginal;
local helperAddBackgroundSkillsOriginal;

function onInit()
	addBackgroundOriginal = CharBackgroundManager.addBackground;
	CharBackgroundManager.addBackground = addBackground;

	helperAddBackgroundSkillsOriginal = CharBackgroundManager.helperAddBackgroundSkills;
	CharBackgroundManager.helperAddBackgroundSkills = helperAddBackgroundSkills;
end

function addBackground(nodeChar, sClass, sRecord, bWizard)
	if PeasantManager.isPeasant(nodeChar) then
		PeasantManager.promotePeasant({ nodePeasant = nodeChar, nodePendingBackground = true });
	else
		addBackgroundOriginal(nodeChar, sClass, sRecord, bWizard);
	end
end

function helperAddBackgroundSkills(rAdd)
	if DB.getValue(rAdd.nodeChar, "peasant") == 1 then
		return;
	end

	helperAddBackgroundSkillsOriginal(rAdd);
end