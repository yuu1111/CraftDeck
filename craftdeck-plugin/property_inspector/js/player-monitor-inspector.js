// Player Monitor Property Inspector JavaScript
var websocket = null,
  uuid = null,
  inInfo = null,
  actionInfo = {},
  settingsModel = {
    PlayerName: "",
    ServerUrl: "ws://localhost:8080",
    AutoConnect: true,
    DisplayFormat: "",
    Language: "auto"
  },
  localizationData = null,
  currentLanguage = "en";

function connectElgatoStreamDeckSocket(inPort, inUUID, inRegisterEvent, inInfo, inActionInfo) {
  uuid = inUUID;
  actionInfo = JSON.parse(inActionInfo);
  inInfo = JSON.parse(inInfo);
  websocket = new WebSocket('ws://localhost:' + inPort);

  // Detect language from application info
  var appInfo = JSON.parse(inInfo);
  if (appInfo.application && appInfo.application.language) {
    currentLanguage = appInfo.application.language;
    console.log('StreamDeck language detected:', currentLanguage);
  }

  // Initialize values
  if (actionInfo.payload.settings.settingsModel) {
    var settings = actionInfo.payload.settings.settingsModel;
    settingsModel.PlayerName = settings.PlayerName || "";
    settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
    settingsModel.AutoConnect = settings.AutoConnect !== undefined ? settings.AutoConnect : true;
    settingsModel.DisplayFormat = settings.DisplayFormat || "";
    settingsModel.Language = settings.Language || "auto";
  }

  // Load localization and initialize UI
  loadLocalization().then(() => {
    // Set initial values in the UI
    document.getElementById('playerName').value = settingsModel.PlayerName;
    document.getElementById('serverUrl').value = settingsModel.ServerUrl;
    document.getElementById('autoConnect').checked = settingsModel.AutoConnect;
    document.getElementById('displayFormat').value = settingsModel.DisplayFormat;
    document.getElementById('language').value = settingsModel.Language;
    
    // Apply localization to UI
    localizeUI();
  });

  websocket.onopen = function () {
    var json = { event: inRegisterEvent, uuid: inUUID };
    websocket.send(JSON.stringify(json));
  };

  websocket.onmessage = function (evt) {
    var jsonObj = JSON.parse(evt.data);
    var sdEvent = jsonObj['event'];
    switch (sdEvent) {
      case "didReceiveSettings":
        if (jsonObj.payload.settings.settingsModel) {
          var settings = jsonObj.payload.settings.settingsModel;
          settingsModel.PlayerName = settings.PlayerName || "";
          settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
          settingsModel.AutoConnect = settings.AutoConnect !== undefined ? settings.AutoConnect : true;
          settingsModel.DisplayFormat = settings.DisplayFormat || "";
          settingsModel.Language = settings.Language || "auto";
          
          // Update UI
          document.getElementById('playerName').value = settingsModel.PlayerName;
          document.getElementById('serverUrl').value = settingsModel.ServerUrl;
          document.getElementById('autoConnect').checked = settingsModel.AutoConnect;
          document.getElementById('displayFormat').value = settingsModel.DisplayFormat;
          document.getElementById('language').value = settingsModel.Language;
        }
        break;
      default:
        break;
    }
  };
}

// Load localization data
async function loadLocalization() {
  try {
    // Determine which language file to load
    var language = settingsModel.Language;
    if (language === "auto") {
      language = currentLanguage;
    }
    
    // Fallback to English if not supported
    if (language !== "en" && language !== "ja") {
      language = "en";
    }
    
    console.log('Loading localization for language:', language);
    
    // Load the localization file
    var response = await fetch(`../${language}.json`);
    if (response.ok) {
      localizationData = await response.json();
      console.log('Localization loaded:', localizationData);
    } else {
      console.warn('Failed to load localization file, using fallback');
      loadFallbackLocalization();
    }
  } catch (error) {
    console.error('Error loading localization:', error);
    loadFallbackLocalization();
  }
}

// Load fallback localization (English)
function loadFallbackLocalization() {
  localizationData = {
    "Localization": {
      "Player Name": "Player Name",
      "Server URL": "Server URL",
      "Auto Connect": "Auto Connect",
      "Display Format": "Display Format",
      "Language": "Language",
      "Information": "Information"
    }
  };
}

// Get localized string
function getLocalizedString(key, fallback) {
  if (localizationData && localizationData.Localization && localizationData.Localization[key]) {
    return localizationData.Localization[key];
  }
  return fallback || key;
}

// Apply localization to UI elements
function localizeUI() {
  if (!localizationData) return;
  
  // Localize elements with data-localize attribute
  var elements = document.querySelectorAll('[data-localize]');
  elements.forEach(function(element) {
    var key = element.getAttribute('data-localize');
    var localizedText = getLocalizedString(key, element.textContent);
    element.textContent = localizedText;
  });
  
  // Localize placeholders
  var placeholderElements = document.querySelectorAll('[data-localize-placeholder]');
  placeholderElements.forEach(function(element) {
    var key = element.getAttribute('data-localize-placeholder');
    var localizedText = getLocalizedString(key, element.placeholder);
    element.placeholder = localizedText;
  });
}

const setSettings = (value, param) => {
  if (websocket) {
    // 改行文字などの特殊文字を適切に処理
    if (typeof value === 'string') {
      settingsModel[param] = value;
    } else {
      settingsModel[param] = value;
    }
    
    // Language changed - reload localization
    if (param === 'Language') {
      loadLocalization().then(() => {
        localizeUI();
      });
    }
    
    try {
      var json = {
        "event": "setSettings",
        "context": uuid,
        "payload": {
          "settingsModel": settingsModel
        }
      };
      
      // JSON.stringifyは自動的に改行文字を\nにエスケープするので、そのまま送信
      var jsonString = JSON.stringify(json);
      console.log('Sending settings:', jsonString);
      websocket.send(jsonString);
    } catch (error) {
      console.error('Error sending settings:', error);
    }
  }
};