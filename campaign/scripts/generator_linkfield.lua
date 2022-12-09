--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	onValueChanged();
	
	Module.onModuleAdded = onValueChanged;
	Module.onModuleUpdated = onValueChanged;
	Module.onModuleRemoved = onValueChanged;
end

function onClose()
end

function onDrop(_, _, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	if class and class[1] and class[1] == sClass then
		setValue(sClass, sRecord);
		return true;
	end
end

function onValueChanged()
	local sName;
	local bHasLink = true;
	local sClass, sRecord = getValue();
	local node = getTargetDatabaseNode();
	if node then
		sName = DB.getValue(node, "name", "");
		if sName == "" then
			sName = Interface.getString("library_recordtype_empty_" .. sClass);
		end
	else
		if sRecord then
			local sModule = sRecord:match("@(.+)$");
			if sModule then
				sName = Interface.getString("module_not_loaded");
			end
		end
		if not sName then
			sName = Interface.getString("export_missing_recordtype_single");
			bHasLink = false;
		end
	end

	setEnabled(bHasLink);

	local nameControl = window[getName() .. "_name"];
	if nameControl then
		nameControl.setValue(sName);
	end
end