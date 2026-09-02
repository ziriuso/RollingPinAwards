# Protected Keyboard Input Fix Design

## Problem

`Components.SetVisible` calls `SetPropagateKeyboardInput(true)` on every visible UI object that exposes the method. Retail WoW restricts that setter in protected execution contexts, so opening `/rpa` can emit `ADDON_ACTION_BLOCKED` while the content panel is being created.

The main window also enables keyboard input and changes propagation from its `OnKeyDown` handler even though it is already registered in `UISpecialFrames`, which provides Blizzard's standard Escape-to-close behavior.

## Required Behavior

- Showing or hiding a reusable component must only change its visibility and optional frame raising.
- Rolling Pin Awards must not call `SetPropagateKeyboardInput` at runtime.
- The main window must not capture keyboard input solely to implement Escape-to-close.
- The main window must remain registered in `UISpecialFrames` so Blizzard closes it on Escape.
- Opening, closing, and reopening the window must continue to work.
- The addon patch version becomes `1.4.5`.

## Test Design

- Replace `CreateFrame` in a regression test with frames whose `SetPropagateKeyboardInput` method raises the same class of protected-call failure.
- Initialize the addon and open the main window; the operation must complete without reaching the restricted setter.
- Retain coverage for `UISpecialFrames` registration, the close button, and repeated window toggling.
- Update the release-version assertion to `1.4.5`.
