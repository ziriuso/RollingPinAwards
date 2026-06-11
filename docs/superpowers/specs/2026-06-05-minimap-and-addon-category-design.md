# Minimap Button And Addon Category Design

## Scope

- group Rolling Pin Awards under the `Guild` heading in the Retail addon list
- anchor the custom minimap button to the outer minimap ring instead of the minimap's top-left corner
- allow left-dragging the minimap button around the ring
- persist the minimap button angle in local SavedVariables so the position survives reloads

## Design

Retail 11.1+ addon grouping is controlled by the TOC `## Category:` directive, so `RollingPinAwards.toc` declares `## Category: Guild`.

`UI/MinimapButton.lua` keeps the button parented to `Minimap` when available. The button is centered on the minimap and positioned from a saved angle with a fixed ring radius of 82 UI units. During a left-button drag, an `OnUpdate` handler reads the cursor position relative to `Minimap:GetCenter()`, converts that vector into an angle, saves it to local settings, and reapplies the center/ring anchor.

`Data/Defaults.lua` and `Data/Database.lua` include `localSettings.minimapAngle` so older SavedVariables receive a stable default. The minimap button reads and writes through existing local settings instead of introducing a new SavedVariables root.

## Tests

- `tests/commands_spec.lua` covers custom icon behavior, click-to-toggle behavior, minimap parentage, movable/drag registration, center/ring anchoring, drag-time angle updates, and angle persistence.
- `tests/embedded_ace3_spec.lua` asserts `## Category: Guild` is present in the TOC.
