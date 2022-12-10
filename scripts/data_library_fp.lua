--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local rRaceRecordInfo = LibraryData.getRecordTypeInfo("race");
	table.insert(rRaceRecordInfo.aGMListButtons, "button_race_peasant_view");
	LibraryData.setRecordTypeInfo("race_peasant_traits",
	{
		bExport = true,
		bExportListSkip = true,
		bHidden = true,
		aDataMap = { "race_peasant_traits" },
		sListDisplayClass = "race_peasant_trait_item",
		bNoCategories = true,
		aCustomFilters = {
			["Ancestry"] = { sField = "race" },
			["Heritage"] = { sField = "subrace" },
		}
	});
end