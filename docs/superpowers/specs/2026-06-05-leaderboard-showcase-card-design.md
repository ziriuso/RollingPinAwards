# Leaderboard Showcase Card Design

## Scope

- rebuild the leaderboard recipient popup around `Media/cleancard.png`
- use `Media/Fonts/Amarante-Regular.ttf` for the large character name and count text
- render the character name at 28 pt in the shared card-value gold
- render Burnt and Golden counts at 24 pt in the same gold, with Burnt on the left and Golden on the right
- place the scrollable award-history table in the lower parchment region of the card
- use an invisible close hitbox over the built-in close-button artwork in the card background

## Design

`UI/Styles.lua` exposes the new reusable media and typography tokens:

- `Fonts.amarante`
- `Media.leaderboardShowcaseBackground`
- `Typography.leaderboardShowcaseName`
- `Typography.leaderboardCount`

`UI/Tabs/Leaderboard.lua` keeps using the shared modal factory for layering, dragging, visibility, and ESC behavior, but swaps the content to a full-card host sized to the clean card artwork. The card background already includes trophy art and the close-button graphic, so the modal no longer draws separate trophy icons or a visible button. The close control remains a real clickable button, but its label and backdrop are cleared.

After live visual tuning, the name sits 20 pixels lower than the initial card pass and uses 28 pt Amarante. The Burnt and Golden counts share the same vertical plane. Golden sits 35 pixels lower and 35 pixels farther left than the prior pass, while Burnt moves onto that same plane and 44 pixels to the right.

## Tests

- `tests/bridge_spec.lua` asserts the popup uses the clean card background, Amarante 24 pt gold text for the character and counts, Burnt count left, Golden count right, lower table placement, and invisible close hitbox.
- `tests/media_spec.lua` asserts the clean card and Amarante font payload sizes.
