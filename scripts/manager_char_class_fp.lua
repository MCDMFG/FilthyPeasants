--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

local addClassOriginal;
local addClassProficiencyOriginal;

function onInit()
	addClassOriginal = CharClassManager.addClass;
	CharClassManager.addClass = addClass;

	addClassProficiencyOriginal = CharClassManager.addClassProficiency;
	CharClassManager.addClassProficiency = addClassProficiency;

end

function addClass(nodeChar, sClass, sRecord, bWizard)
	if PeasantManager.isPeasant(nodeChar) then
		PeasantManager.promotePeasant({ nodePeasant = nodeChar, nodePendingClass = DB.findNode(sRecord) });
	else
		addClassOriginal(nodeChar, sClass, sRecord, bWizard);
	end
end

function addClassProficiency(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	if DB.getValue(nodeChar, "peasant") == 1 then
		if rAdd.sSourceType == "savingthrows" or rAdd.sSourceType == "skills" then
			return;
		end
	end

	addClassProficiencyOriginal(nodeChar, sClass, sRecord, bWizard);
end