--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	onValueChanged();
end

function onDrop(_, _, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	if class and class[1] and class[1] == sClass then
		setValue(sClass, sRecord);
		return true;
	end
end

function onValueChanged()
	local nameControl = window[getName() .. "_name"];
	if nameControl then
		nameControl.setValue(DB.getValue(getTargetDatabaseNode(), "name", ""));
	end
end