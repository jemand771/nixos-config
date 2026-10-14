const { contextBridge, ipcRenderer, webFrame } = require("electron");

contextBridge.exposeInMainWorld("outlookWeb", { focus: () => ipcRenderer.send("focus") });

// clicking a notification should bring the window back, even from the tray
webFrame.executeJavaScript(`
  window.Notification = class extends window.Notification {
    constructor(...args) {
      super(...args);
      this.addEventListener("click", () => window.outlookWeb.focus());
    }
  };
`);
