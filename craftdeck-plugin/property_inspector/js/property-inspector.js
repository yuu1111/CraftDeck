// global websocket, used to communicate from/to Stream Deck software
// as well as some info about our plugin, as sent by Stream Deck software 
var websocket = null,
  uuid = null,
  inInfo = null,
  actionInfo = {},
  settingsModel = {
	Command: "",
	PlayerName: "",
	DisplayMode: "command",
	ServerUrl: "ws://localhost:8080",
	AutoConnect: true
  };

function connectElgatoStreamDeckSocket(inPort, inUUID, inRegisterEvent, inInfo, inActionInfo) {
  uuid = inUUID;
  actionInfo = JSON.parse(inActionInfo);
  inInfo = JSON.parse(inInfo);
  websocket = new WebSocket('ws://localhost:' + inPort);

  //initialize values
  if (actionInfo.payload.settings.settingsModel) {
	var settings = actionInfo.payload.settings.settingsModel;
	settingsModel.Command = settings.Command || "";
	settingsModel.PlayerName = settings.PlayerName || "";
	settingsModel.DisplayMode = settings.DisplayMode || "command";
	settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
	settingsModel.AutoConnect = settings.AutoConnect !== undefined ? settings.AutoConnect : true;
  }

  // Set initial values in the UI
  document.getElementById('command').value = settingsModel.Command;
  document.getElementById('playerName').value = settingsModel.PlayerName;
  document.getElementById('displayMode').value = settingsModel.DisplayMode;
  document.getElementById('serverUrl').value = settingsModel.ServerUrl;
  document.getElementById('autoConnect').checked = settingsModel.AutoConnect;

  websocket.onopen = function () {
	var json = { event: inRegisterEvent, uuid: inUUID };
	// register property inspector to Stream Deck
	websocket.send(JSON.stringify(json));
  };

  websocket.onmessage = function (evt) {
	// Received message from Stream Deck
	var jsonObj = JSON.parse(evt.data);
	var sdEvent = jsonObj['event'];
	switch (sdEvent) {
	  case "didReceiveSettings":
		if (jsonObj.payload.settings.settingsModel) {
		  var settings = jsonObj.payload.settings.settingsModel;
		  settingsModel.Command = settings.Command || "";
		  settingsModel.PlayerName = settings.PlayerName || "";
		  settingsModel.DisplayMode = settings.DisplayMode || "command";
		  settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
		  settingsModel.AutoConnect = settings.AutoConnect !== undefined ? settings.AutoConnect : true;
		  
		  // Update UI
		  document.getElementById('command').value = settingsModel.Command;
		  document.getElementById('playerName').value = settingsModel.PlayerName;
		  document.getElementById('displayMode').value = settingsModel.DisplayMode;
		  document.getElementById('serverUrl').value = settingsModel.ServerUrl;
		  document.getElementById('autoConnect').checked = settingsModel.AutoConnect;
		}
		break;
	  default:
		break;
	}
  };
}

const setSettings = (value, param) => {
  if (websocket) {
	settingsModel[param] = value;
	var json = {
	  "event": "setSettings",
	  "context": uuid,
	  "payload": {
		"settingsModel": settingsModel
	  }
	};
	websocket.send(JSON.stringify(json));
  }
};

// Update connection status (this would be called from the main plugin)
function updateConnectionStatus(isConnected) {
  var statusElement = document.getElementById('connectionStatus');
  if (statusElement) {
	statusElement.textContent = isConnected ? "Connected" : "Disconnected";
	statusElement.style.color = isConnected ? "#4CAF50" : "#999";
  }
}

