# Window Pin

A small Mac menu bar app for when you keep switching between two windows. Pin a window and
it stays on top of everything, so you can keep a small window over a big one and still
click and type in both.

- **Size it how you like.** Make the window you want to pin small and put it where you want
  it, then pin it.
- **Stays on top.** When you click into another window, the pinned one stays visible above
  it, still live.
- **Still usable.** Click the pinned window and you're working in it again. Type, scroll,
  click buttons. Click back into the big window and the pinned one stays on top.
- **One shortcut.** Press **⌃⌥P** (Control-Option-P) to pin the window you're looking at.
  Press it again in that window to unpin it.

## Requirements

- macOS 13 or later
- Swift 5.9 or later (install Xcode, or run `xcode-select --install` for the command line tools)

## Try it

From this folder, in Terminal:

```sh
./scripts/build-app.sh
open "build/Window Pin.app"
```

The first time, macOS asks for two permissions:

1. **Screen Recording**, to show the pinned window while another window is in front.
   Nothing is recorded or saved.
2. **Accessibility**, to bring the pinned window forward and pass your click on to it.

After allowing both, quit Window Pin from its menu bar icon and open it again.

A pin icon appears in the menu bar.

## Using it

1. Resize the window you want to keep on top and move it where you want it.
2. Click the pin icon and choose that window, or press **⌃⌥P** while it's in front.
3. Click into your big window and work as usual. The pinned window stays on top.
4. Click the pinned window to use it. Your click goes through to it, and you can type in it
   right away.

Right-click the pinned window while it's covering another one to change its opacity or
unpin it. You can also unpin from the menu bar list, or with ⌃⌥P. You can pin several
windows at once. A pin goes away when its window closes.

### How it works

macOS doesn't let one app keep another app's real window on top. So while the pinned window
is behind other windows, Window Pin lays a live copy of it exactly over it, at the same
size and position. When you click the copy, the copy hides, the real window comes forward,
and the click is passed on to it. When you click another window, the copy covers it again.

The copy updates up to 30 times a second and follows the window when you move or resize it.

### Running from Terminal with debug output

```sh
swift run WindowPin --debug
```

The permissions then belong to Terminal instead of Window Pin. If this fails with "Invalid
manifest", that's a problem with the Command Line Tools' package manager, not with this
app; use the build script above instead. To fix the tools themselves, reinstall them:

```sh
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

## Rebuilding

The build is signed only for this Mac, so after a rebuild macOS may treat it as a new app.
If the pinned window stops showing or clicks stop going through, remove Window Pin from the
Screen Recording and Accessibility lists in System Settings → Privacy & Security and allow
it again.

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

- Untested on a real Mac so far, so the first build may need small fixes.
- The first click on the pinned window is passed on as a plain click. To drag something in
  it (or the window itself), click once, then drag.
- When the copy is showing, it's a picture: hovering over it doesn't highlight anything
  until you click it.
- Both windows must be on the same desktop. Pinning over an app in full-screen mode doesn't
  work, because that app is on a desktop of its own. Use a large normal window instead.
- macOS 15 and later asks every so often whether Window Pin may keep capturing the screen.
  That's a system prompt for all screen capture apps.
