local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

RPA.UIStyles = {
  Window = {
    width = 884,
    height = 736,
    title = "Rolling Pin Awards",
    subtitle = "Hall of Fame & Hall of Shame",
  },
  TabOrder = {
    "dashboard",
    "award",
    "nominations",
    "history",
    "leaderboard",
    "admin",
  },
  Colors = {
    shell = { 0.15, 0.10, 0.07, 0.98 },
    shellShadow = { 0.31, 0.21, 0.13, 0.88 },
    parchment = { 0.95, 0.91, 0.83, 0.98 },
    parchmentSoft = { 0.90, 0.85, 0.76, 0.94 },
    parchmentMuted = { 0.86, 0.79, 0.69, 0.92 },
    bannerPanel = { 0.88, 0.72, 0.50, 0.78 },
    brass = { 0.82, 0.64, 0.45, 1.0 },
    brassMuted = { 0.62, 0.51, 0.37, 1.0 },
    accent = { 0.85, 0.47, 0.25, 1.0 },
    accentSoft = { 0.79, 0.63, 0.41, 1.0 },
    ink = { 0.20, 0.14, 0.10, 1.0 },
    inkMuted = { 0.47, 0.39, 0.30, 1.0 },
    darkPanel = { 0.12, 0.08, 0.06, 0.98 },
    glow = { 0.98, 0.86, 0.45, 0.26 },
  },
  Layout = {
    headerHeight = 86,
    tabRailHeight = 52,
    tabWidth = 108,
    tabGap = 10,
    contentInset = 22,
    cardGap = 16,
  },
  Media = {
    addonBackground = "Interface\\AddOns\\RollingPinAwards\\Media\\addon-background.png",
    headerIcon = "Interface\\AddOns\\RollingPinAwards\\Media\\flameember.png",
    awardIcon = "Interface\\AddOns\\RollingPinAwards\\Media\\burnt-rolling-pin.png",
    leaderboardIcon = "Interface\\AddOns\\RollingPinAwards\\Media\\golden-rolling-pin.png",
    minimapIcon = "Interface\\AddOns\\RollingPinAwards\\Media\\minimap-button.png",
    modalBackground = "Interface\\AddOns\\RollingPinAwards\\Media\\modal-background.png",
    standardPinIcon = "Interface\\AddOns\\RollingPinAwards\\Media\\rollingpin.png",
  },
  Dashboard = {
    statCardWidth = 178,
    statCardHeight = 96,
    footerButtonHeight = 42,
  },
}

return RPA.UIStyles
