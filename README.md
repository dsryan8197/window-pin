# Window Pin

A small Mac menu bar app for when you keep switching between two windows. Pin any window
and a small live copy of it floats on top of everything, so you can keep an eye on it while
you work in another app.

- **Live.** The pinned copy updates as the original changes: a video call, a build log, a
  chat, a dashboard, notes you're copying from.
- **Stays out of the way.** It floats above other windows on every Space, including
  full-screen apps. Clicking it doesn't take focus from the app you're typing in.
- **One shortcut.** Press **⌃⌥P** (Control-Option-P) to pin the window you're looking at.
  Press it again in that window to unpin it.

## Requirements

- macOS 13 or later
- Swift 5.9 or later (install Xcode, or run `xcode-select --install` for the command line tools)

## Try it

From this folder, in Terminal:

```sh
swift run WindowPin --debug
```

The first time, macOS asks for **Screen Recording** permission. Window Pin needs it to show
the live copy. Nothing is recorded or saved. Because you started the app from Terminal, the
permission goes to **Terminal**. After allowing it, stop the app (Ctrl+C) and run the same
command again.

A pin icon appears in the menu bar.

## Using it

- **Pin a window.** Click the pin icon and choose a window from the list, or press **⌃⌥P**
  while the window is in front.
- **Move and resize** the floating copy by its title bar and edges. It keeps the original
  window's shape.
- **Double-click** the copy to jump to the original window.
- **Right-click** the copy to jump to the original, change its opacity, or unpin it.
- **Unpin** with the copy's close button, from the menu bar list, or with ⌃⌥P.

You can pin several windows at once. A copy closes when its original window closes.

### Optional: Accessibility

Without Accessibility permission, double-clicking a copy brings the original's *app* to the
front. With it, the exact window comes forward, even if it's behind other windows from the
same app or minimised. To turn it on, choose **Allow Accessibility to jump to exact
windows…** in the menu.

### If `swift run` fails with "Invalid manifest"

That's a problem with the Command Line Tools' package manager, not with this app. Skip it
and build the app directly instead (next section). To fix the tools themselves, reinstall
them:

```sh
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

## Build a standalone app

```sh
./scripts/build-app.sh
open "build/Window Pin.app"
```

Drag it to Applications if you like. The permissions then belong to Window Pin instead of
Terminal. The build is signed only for this Mac, so after a rebuild macOS may treat it as a
new app. If the copies stop updating, remove Window Pin from the Screen Recording list in
System Settings → Privacy & Security and allow it again.

## How it works

1. The menu lists the app windows that are on screen, using the macOS window list.
2. Pinning a window starts a ScreenCaptureKit stream of just that window, at up to 30 frames
   a second. The stream captures the window even when other windows cover it.
3. Each frame is shown in a small floating panel that doesn't take focus.
4. Once a second the app checks the original window. If it was resized, the copy follows its
   new shape. If it closed, the copy closes too.

## If something doesn't work

Run with `--debug`. The Terminal output shows:

- `screen recording allowed`. This must be `true`. If you just allowed it, quit and restart
  the app.
- `window …` lines listing the windows the app can see. If titles are empty (`""`), Screen
  Recording permission is missing.
- Messages when a pin starts, stops, or fails.

If ⌃⌥P does nothing, another app may already use that shortcut. The output then shows
`couldn't register ⌃⌥P`.

## Known limitations

- Untested on a real Mac so far. It was written without a Mac to compile on, so the first
  build may need small fixes.
- Minimised windows can't be pinned, and a pinned window shows its last frame while it is
  minimised.
- macOS 15 and later asks every so often whether Window Pin may keep capturing the screen.
  That's a system prompt for all screen capture apps.
- The copy is view-only. To type into the window, double-click the copy to jump to it.
