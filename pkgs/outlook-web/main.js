const { app, BrowserWindow, Menu, Tray, clipboard, dialog, ipcMain, session, shell } = require("electron");
const { spawn } = require("node:child_process");
const path = require("node:path");

const baseUrl = "https://outlook.cloud.microsoft/";
const internalHosts = [
  "outlook.cloud.microsoft",
  "outlook.office.com",
  "outlook.office365.com",
  "login.microsoftonline.com",
  "login.microsoft.com",
  "login.live.com",
];
const teamsHosts = ["teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft"];
const windowOptions = {
  width: 1400,
  height: 900,
  autoHideMenuBar: true,
  icon: path.join(__dirname, "icon.png"),
  webPreferences: {
    preload: path.join(__dirname, "preload.js"),
    // keep the push connection alive while hidden in the tray
    backgroundThrottling: false,
  },
};

let mainWindow;
let quitting = false;

app.userAgentFallback = app.userAgentFallback.replace(/ (outlook-web|Electron)\/\S+/g, "");

function isInternal(raw) {
  // blob: urls carry their creator's origin
  return raw === "about:blank" || internalHosts.includes(URL.parse(URL.parse(raw)?.origin)?.hostname);
}

function teamsMeeting(raw) {
  let url = URL.parse(raw);
  if (url?.hostname.endsWith(".safelinks.protection.outlook.com")) {
    url = URL.parse(url.searchParams.get("url"));
  }
  if (
    teamsHosts.includes(url?.hostname) &&
    (url.pathname.startsWith("/l/meetup-join/") ||
      url.pathname.startsWith("/meet/") ||
      url.searchParams.has("meetingjoin"))
  ) {
    return url.href;
  }
}

function composeUrl(mailto) {
  const decode = (s) => {
    try {
      return decodeURIComponent(s);
    } catch {
      return s;
    }
  };
  // not URLSearchParams: "+" is a literal plus in mailto (RFC 6068), not a space
  const [to, ...query] = mailto.replace(/^mailto:/i, "").split("?");
  const pairs = [`to=${to}`, ...query.join("?").split("&")].map((pair) => pair.split("="));
  const compose = new URL("mail/deeplink/compose", baseUrl);
  for (const key of ["to", "cc", "bcc", "subject", "body"]) {
    const value = pairs
      .filter(([k]) => decode(k).toLowerCase() === key)
      .map(([, ...v]) => decode(v.join("=")))
      .filter(Boolean)
      .join(",");
    if (value) {
      compose.searchParams.set(key, value);
    }
  }
  return compose.href;
}

function openCompose(mailto) {
  new BrowserWindow(windowOptions).loadURL(composeUrl(mailto));
}

function openOutside(url) {
  const teams = teamsMeeting(url);
  if (teams) {
    spawn(process.env.OUTLOOK_WEB_TEAMS, [teams], { detached: true, stdio: "ignore" }).unref();
  } else if (/^mailto:/i.test(url)) {
    openCompose(url);
  } else if (/^https?:/i.test(url)) {
    shell.openExternal(url);
  }
}

function handleArgs(argv) {
  const mailto = argv.find((arg) => /^mailto:/i.test(arg));
  if (mailto) {
    openCompose(mailto);
  }
}

function show(win) {
  win.show();
  win.focus();
}

function popupContextMenu(contents, params) {
  Menu.buildFromTemplate([
    ...params.dictionarySuggestions.map((word) => ({
      label: word,
      click: () => contents.replaceMisspelling(word),
    })),
    ...(params.misspelledWord
      ? [
          {
            label: "Add to dictionary",
            click: () => contents.session.addWordToSpellCheckerDictionary(params.misspelledWord),
          },
        ]
      : []),
    { type: "separator" },
    ...(params.linkURL ? [{ label: "Copy link", click: () => clipboard.writeText(params.linkURL) }] : []),
    { type: "separator" },
    { role: "cut", enabled: params.editFlags.canCut },
    { role: "copy", enabled: params.editFlags.canCopy },
    { role: "paste", enabled: params.editFlags.canPaste },
    { role: "selectAll" },
  ]).popup();
}

app.on("web-contents-created", (_, contents) => {
  contents.setWindowOpenHandler(({ url }) => {
    if (isInternal(url)) {
      return { action: "allow", overrideBrowserWindowOptions: windowOptions };
    }
    openOutside(url);
    return { action: "deny" };
  });
  contents.on("will-navigate", (event, url) => {
    if (teamsMeeting(url) || !/^(https?|about):/.test(url)) {
      event.preventDefault();
      openOutside(url);
    }
  });
  // without a handler, electron silently cancels the close
  contents.on("will-prevent-unload", (event) => {
    const leave = dialog.showMessageBoxSync({
      type: "question",
      buttons: ["Leave", "Stay"],
      cancelId: 1,
      message: "Leave this page? Changes you made may not be saved.",
    });
    if (leave === 0) {
      event.preventDefault();
    } else {
      quitting = false;
    }
  });
  contents.on("context-menu", (_, params) => popupContextMenu(contents, params));
});

if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on("second-instance", (_, argv) => {
    show(mainWindow);
    handleArgs(argv);
  });
  app.on("before-quit", () => (quitting = true));
  ipcMain.on("focus", (event) => show(BrowserWindow.fromWebContents(event.sender)));

  app.whenReady().then(() => {
    session.defaultSession.setPermissionRequestHandler((_, permission, callback, { requestingUrl }) =>
      callback(permission !== "openExternal" && isInternal(requestingUrl)),
    );

    mainWindow = new BrowserWindow({ ...windowOptions, show: false });
    mainWindow.on("close", (event) => {
      if (!quitting) {
        event.preventDefault();
        mainWindow.hide();
      }
    });
    if (!process.argv.includes("--minimized")) {
      mainWindow.once("ready-to-show", () => show(mainWindow));
    }
    mainWindow.loadURL(new URL("mail/", baseUrl).href);

    const tray = new Tray(windowOptions.icon);
    tray.setToolTip("Outlook");
    tray.setContextMenu(
      Menu.buildFromTemplate([
        { label: "Show", click: () => show(mainWindow) },
        { label: "Quit", click: () => app.quit() },
      ]),
    );
    tray.on("click", () => show(mainWindow));

    handleArgs(process.argv);
  });
}
