# Postlite — Windows setup

## Install as a desktop app (recommended)

1. Put all the Postlite files in a permanent folder, e.g. `C:\Tools\Postlite\`.
2. Double-click **`Install-Postlite.bat`**.

That creates a **Postlite** icon on your Desktop and in the Start Menu (search
"Postlite"). Launching it runs `Postlite.bat` by default — Postlite opens in its
own app window (no tabs/address bar) with web security disabled, using an
isolated profile next to the files, so your normal Chrome is untouched and you
don't have to close anything.

- **Pin to taskbar:** launch it once, right-click its taskbar icon → *Pin to taskbar*.
- **Remove the app shortcuts:** run `Uninstall-Postlite.bat` (your files stay).

> Note on "PWA": a true browser *Install* needs the page served over
> `http://localhost`/HTTPS with a service worker, which `file://` can't do and
> which can't use `--disable-web-security`. The shortcut above gives you the same
> installed-desktop-app experience while keeping the CORS bypass. If you prefer a
> real PWA install instead, serve the folder over `http://localhost` and use the
> local proxy (below) for VPN APIs.

## Files (keep them together in one folder)

- `postlite.html` — the app
- `Postlite.bat` — Windows launcher (Chrome app window + CORS disabled)
- `manifest.json`, `icon.svg` — app metadata/icon (used if you ever serve it)

Put all of them in a permanent folder, e.g. `C:\Tools\Postlite\`.

## Run it

Double-click **`Postlite.bat`**. Chrome opens Postlite in its own window — no
tabs, no address bar — and internal endpoints that don't send CORS headers will
work. This is the equivalent command it runs:

```
chrome.exe --app="file:///C:/Tools/Postlite/postlite.html" ^
           --disable-web-security ^
           --user-data-dir=a fixed path
```

## Make it feel like an installed app

**Pin to taskbar / Start:**
1. Run `Postlite.bat` once.
2. Right-click the Chrome window's taskbar icon → **Pin to taskbar**.
   (That pinned icon will relaunch the app window.)

**Desktop shortcut with the Postlite icon:**
1. Right-click `Postlite.bat` → **Create shortcut** (or **Send to → Desktop**).
2. Right-click the shortcut → **Properties** → **Change Icon…** → **Browse…**
   and pick an `.ico`. (Windows can't use `.svg` directly for icons; convert
   `icon.svg` to `.ico` with any online converter if you want the branded icon,
   otherwise any icon works.)
3. Optional: in **Properties → Shortcut → Run:** choose **Minimized** so the
   black console flash is hidden.

## Notes

- The `--user-data-dir=a fixed path` is a throwaway Chrome profile kept
  separate from your normal browsing. Disabling web security in your everyday
  profile is unsafe; this keeps it isolated. Don't use this window for general
  web browsing.
- All Postlite data (collections, environments, tabs, settings) is stored in
  that profile's local storage. If Windows clears `%TEMP%`, that data is lost —
  **export your collections** (the ⤓ on each collection) for backup. To make the
  data permanent, change `plchrome-profile` (next to the launcher) in `Postlite.bat` to a fixed path
  like `C:\Tools\Postlite\profile`.
- A genuine "Install as PWA" (Start-menu entry via Chrome's install button)
  requires serving the file over `http://localhost` or HTTPS with a service
  worker; that path can't also use `--disable-web-security`, so for internal
  VPN testing the app-mode launcher above is the recommended way.

---

## Troubleshooting: it didn't open with the flags

1. **Close ALL Chrome windows first, then run the launcher.**
   If a Chrome process is already using the `plchrome` profile, a new launch
   just opens a window in the existing process and the flags are *not*
   re-applied. Close existing Postlite/Chrome windows and run `Postlite.bat`
   again.

2. **Confirm the flags actually applied.** In the opened window go to
   `chrome://version` and check the **Command Line** row — it should list
   `--disable-web-security` and `--user-data-dir=...\plchrome`. A yellow
   "You are using an unsupported command-line flag" bar is also a good sign.

3. **Run the .bat from a Command Prompt to see errors.** Open `cmd`, `cd` into
   the folder, and run `Postlite.bat`. Any "file not found" / path message will
   be visible instead of flashing past.

4. **Corporate-managed Chrome may block it.** On a managed machine, enterprise
   policy can ignore `--disable-web-security` or force your normal profile.
   Check `chrome://policy`. If it's blocked, alternatives: use a portable
   Chrome/Chromium, or run a tiny local CORS proxy instead.

5. **chrome.exe not found.** Open `Postlite.bat` in Notepad and set the path
   manually near the top:
   `set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"`

---

## Better option: run in a NORMAL browser using the local proxy (no Chrome flag)

If you don't want to close Chrome or use a special profile, run the included
**local proxy** instead. It runs on your machine, reaches the API server-side
(no browser CORS), and adds CORS headers — so Postlite works in your everyday
Chrome/Edge/Firefox with your normal profile.

1. Double-click **`Proxy.bat`** and leave its window open. It prints
   `http://localhost:8010`.
   - **No Python needed.** `Proxy.bat` uses Python if it is installed, otherwise
     it automatically falls back to the built-in **PowerShell** proxy
     (`proxy.ps1`) — nothing to install.
   - If your machine blocks PowerShell scripts by policy, either install Python
     from python.org (tick "Add to PATH") and rerun, or use `Postlite-Edge.bat`.
2. In Postlite, click **`Proxy`** (top bar), tick **Route requests through local
   proxy**, confirm the URL is `http://localhost:8010`, **Save**.
3. Send requests as usual — they now go through the proxy. The proxy window logs
   each call.

**Important:** the proxy must run on the machine that has the VPN, so it can
reach internal hosts. SSL verification is disabled in the proxy (like Postman's
"disable SSL verification"), so TLS-inspected corporate HTTPS works.

## Other option: open in EDGE instead of Chrome (keeps Chrome open)

`--disable-web-security` is ignored only when the *same browser+profile* is
already running. **Edge is a different browser**, so you can run Postlite in Edge
with the flag while your normal Chrome stays open. Double-click
**`Postlite-Edge.bat`**.

## Files

- `postlite.html`, `manifest.json`, `icon.svg` — the app
- `Postlite.bat` — open in Chrome app window (flag)
- `Postlite-Edge.bat` — open in Edge app window (flag; leaves Chrome alone)
- `proxy.py` + `Proxy.bat` — local CORS proxy (normal browser, no flag)
