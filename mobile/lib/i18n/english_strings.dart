Map<String, Map<String, String>> get englishStrings => {
  "US" : {
  },
  "CA" : {
  },
  "default" : {
    "appName" : "Anglers' Log",

    "cancel" : "Cancel",
    "done" : "Done",
    "save" : "Save",
    "edit" : "Edit",
    "delete" : "Delete",
    "none" : "None",
    "next" : "Next",
    "ok" : "Ok",
    "error" : "Error",
    "warning" : "Warning",
    "continue" : "Continue",
    "yes" : "Yes",
    "no" : "No",
    "clear" : "Clear",
    "today" : "Today",
    "yesterday" : "Yesterday",
    "directions" : "Directions",
    "latLng" : "Lat: %s, Lng: %s",
    "latLng_noLabels" : "%s, %s",
    "add" : "Add",
    "more" : "More",

    "fieldType_number" : "Number",
    "fieldType_boolean" : "Checkbox",
    "fieldType_text" : "Text",

    "input_requiredMessage" : "%s is required",
    "input_nameLabel" : "Name",
    "input_genericRequired" : "Required",
    "input_descriptionLabel" : "Description",
    "input_invalidNumber" : "Invalid number input",
    "input_photoLabel" : "Photo",
    "input_photosLabel" : "Photos",
    "input_notSelected" : "Not Selected",
    "input_emailLabel" : "Email",
    "input_invalidEmail" : "Invalid email",

    "catchListPage_menuLabel" : "Catches",
    "catchListPage_title" : "Catches (%s)",
    "catchListPage_searchHint" : "Search catches",
    "catchListPage_noSearchResults" : "No catches found",

    "catchPage_deleteMessage" : "Are you sure you want to delete catch %s? This cannot be undone.",

    "saveCatchPage_newTitle" : "New Catch",
    "saveCatchPage_editTitle" : "Edit Catch",
    "saveCatchPage_dateTimeLabel" : "Date & Time",
    "saveCatchPage_dateLabel" : "Date",
    "saveCatchPage_timeLabel" : "Time",
    "saveCatchPage_speciesLabel" : "Species",
    "saveCatchPage_imagesLabel" : "Photos",
    "saveCatchPage_fishingSpotLabel" : "Fishing Spot",
    "saveCatchPage_baitLabel" : "Bait",

    "photosPage_menuLabel" : "Photos",
    "photosPage_title" : "Photos (%s)",

    "baitListPage_menuLabel" : "Baits",
    "baitListPage_title" : "Baits (%s)",
    "baitListPage_pickerTitle" : "Select Bait",
    "baitListPage_otherCategory" : "No Category",
    "baitListPage_searchHint" : "Search baits",
    "baitListPage_noSearchResults" : "No baits found",

    "baitPage_deleteMessage" : "%s is associated with %s catches; are you sure you want to delete it? This cannot be undone.",
    "baitPage_deleteMessageSingular" : "%s is associated with %s catch; are you sure you want to delete it? This cannot be undone.",

    "saveBaitPage_newTitle" : "New Bait",
    "saveBaitPage_editTitle" : "Edit Bait",
    "saveBaitPage_categoryLabel" : "Bait Category",
    "saveBaitPage_baitExists" : "A bait with these properties already exists. Please change at least one field and try again.",

    "saveBaitCategoryPage_newTitle" : "New Bait Category",
    "saveBaitCategoryPage_editTitle" : "Edit Bait Category",
    "saveBaitCategoryPage_existsMessage" : "Bait category already exists",

    "baitCategoryListPage_menuTitle" : "Bait Categories",
    "baitCategoryListPage_title" : "Bait Categories (%s)",
    "baitCategoryListPage_pickerTitle" : "Select Bait Category",
    "baitCategoryListPage_deleteMessage" : "%s is associated with %s baits; are you sure you want to delete it? This cannot be undone.",
    "baitCategoryListPage_deleteMessageSingular" : "%s is associated with %s bait; are you sure you want to delete it? This cannot be undone.",
    "baitCategoryListPage_searchHint" : "Search bait categories",
    "baitCategoryListPage_noSearchResults" : "No bait categories found",

    "statsPage_title" : "Stats",

    "morePage_title" : "More",

    "tripListPage_menuLabel" : "Trips",
    "tripListPage_title" : "Trips (%s)",

    "settingsPage_title" : "Settings",

    "mapPage_menuLabel" : "Map",
    "mapPage_deleteFishingSpot" : "%s is associated with %s catches; are you sure you want to delete it? This cannot be undone.",
    "mapPage_deleteFishingSpotNoName" : "This fishing spot is associated with %s catches; are you sure you want to delete it? This cannot be undone.",
    "mapPage_addCatch" : "Add Catch",
    "mapPage_searchHint" : "Search fishing spots",
    "mapPage_noSearchResults" : "No fishing spots found",
    "mapPage_droppedPin" : "Dropped Pin",
    "mapPage_mapTypeNormal" : "Normal",
    "mapPage_mapTypeSatellite" : "Satellite",
    "mapPage_mapTypeTerrain" : "Terrain",
    "mapPage_mapTypeHybrid" : "Hybrid",
    "mapPage_errorGettingLocation" : "Unable to retrieve current location. Please try again later.",

    "saveFishingSpotPage_newTitle" : "New Fishing Spot",
    "saveFishingSpotPage_editTitle" : "Edit Fishing Spot",

    "formPage_manageFieldText" : "Manage Fields",
    "formPage_removeFieldsText" : "Remove Fields",
    "formPage_confirmRemoveField" : "Remove 1 Field",
    "formPage_confirmRemoveFields" : "Remove %s Fields",
    "formPage_selectFieldsTitle" : "Select Fields",

    "saveCustomEntityPage_newTitle" : "New Field",
    "saveCustomEntityPage_nameExists" : "Field name already exists",

    "imagePickerPage_noPhotosFound" : "No photos found",
    "imagePickerPage_openCameraLabel" : "Open Camera",
    "imagePickerPage_cameraLabel" : "Camera",
    "imagePickerPage_galleryLabel" : "Gallery",
    "imagePickerPage_browseLabel" : "Browse",
    "imagePickerPage_selectedLabel" : "%s / %s Selected",
    "imagePickerPage_invalidSelectionSingle" : "Must select an image file.",
    "imagePickerPage_invalidSelectionPlural" : "Must select image files.",

    "saveSpeciesPage_newTitle" : "New Species",
    "saveSpeciesPage_editTitle" : "Edit Species",
    "saveSpeciesPage_existsError" : "Species already exists",

    "speciesListPage_menuTitle" : "Species",
    "speciesListPage_title" : "Species (%s)",
    "speciesListPage_pickerTitle" : "Select Species",
    "speciesListPage_confirmDelete" : "%s is associated with 0 catches; are you sure you want to delete it? This cannot be undone.",
    "speciesListPage_catchDeleteError" : "%s is associated with %s catches and cannot be deleted.",
    "speciesListPage_searchHint" : "Search species",
    "speciesListPage_noSearchResults" : "No species found",

    "fishingSpotPickerPage_title" : "Select Fishing Spot",
    "fishingSpotPickerPage_hint" : "Drag the map to use exact coordinates, or select an existing fishing spot.",

    "feedbackPage_title" : "Send Feedback",
    "feedbackPage_send" : "Send",
    "feedbackPage_message" : "Message",
    "feedbackPage_bugType" : "Bug",
    "feedbackPage_suggestionType" : "Suggestion",
    "feedbackPage_feedbackType" : "Feedback",
    "feedbackPage_errorSending" : "Error sending feedback. Please try again later.",
    "feedbackPage_connectionError" : "No internet connection. Please check your connection and try again.",
    "feedbackPage_sending" : "Sending feedback...",

    "importPage_title" : "Import",
    "importPage_description" : "Import data that you previously exported using Anglers' Log. This may take several minutes.",
    "importPage_chooseFile" : "Choose File",
    "importPage_importingImages" : "Copying images...",
    "importPage_importingData" : "Copying fishing data...",
    "importPage_success" : "Successfully imported data!",
    "importPage_error" : "There was an error importing your data. If the backup file you chose was created using Anglers' Log, please send it to us for investigation.",
    "importPage_sendReport" : "Send Report",
    "importPage_errorWarningTitle" : "Warning",
    "importPage_errorWarningMessage" : "You are about to send Anglers' Log all your fishing data (excluding photos).",

    "angler_nameLabel" : "Angler",

    "analysisDuration_allDates" : "All dates",
    "analysisDuration_today" : "Today",
    "analysisDuration_yesterday" : "Yesterday",
    "analysisDuration_thisWeek" : "This week",
    "analysisDuration_thisMonth" : "This month",
    "analysisDuration_thisYear" : "This year",
    "analysisDuration_lastWeek" : "Last week",
    "analysisDuration_lastMonth" : "Last month",
    "analysisDuration_lastYear" : "Last year",
    "analysisDuration_last7Days" : "Last 7 days",
    "analysisDuration_last14Days" : "Last 14 days",
    "analysisDuration_last30Days" : "Last 30 days",
    "analysisDuration_last60Days" : "Last 60 days",
    "analysisDuration_last12Months" : "Last 12 months",
    "analysisDuration_custom" : "Custom",

    "dateTimeFormat" : "%s at %s",
  },
};