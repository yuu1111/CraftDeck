// Command Action Property Inspector JavaScript
var websocket = null,
  uuid = null,
  inInfo = null,
  actionInfo = {},
  settingsModel = {
    Command: "",
    PlayerName: "",
    ServerUrl: "ws://localhost:8080"
  };

function connectElgatoStreamDeckSocket(inPort, inUUID, inRegisterEvent, inInfo, inActionInfo) {
  uuid = inUUID;
  actionInfo = JSON.parse(inActionInfo);
  inInfo = JSON.parse(inInfo);
  websocket = new WebSocket('ws://localhost:' + inPort);

  // Initialize values
  if (actionInfo.payload.settings.settingsModel) {
    var settings = actionInfo.payload.settings.settingsModel;
    settingsModel.Command = settings.Command || "";
    settingsModel.PlayerName = settings.PlayerName || "";
    settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
  }

  // Set initial values in the UI
  document.getElementById('command').value = settingsModel.Command;
  document.getElementById('playerName').value = settingsModel.PlayerName;
  document.getElementById('serverUrl').value = settingsModel.ServerUrl;

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
          settingsModel.Command = settings.Command || "";
          settingsModel.PlayerName = settings.PlayerName || "";
          settingsModel.ServerUrl = settings.ServerUrl || "ws://localhost:8080";
          
          // Update UI
          document.getElementById('command').value = settingsModel.Command;
          document.getElementById('playerName').value = settingsModel.PlayerName;
          document.getElementById('serverUrl').value = settingsModel.ServerUrl;
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