# Slash Command Registry Taint Fix Design

## Problem

`RPA:RegisterFallbackSlashCommand` assigns `_G.SlashCmdList` back to itself before registering `/rpa`. Blizzard owns and initializes this shared global registry. Reassigning its global binding from addon code can taint Blizzard's slash-command dispatch path and cause protected commands such as `/tm` to fail with Rolling Pin Awards blamed for the blocked action.

## Required Behavior

- Rolling Pin Awards must not assign or replace the global `SlashCmdList` binding.
- The addon may write only its own `ROLLINGPINAWARDS` entry in Blizzard's existing registry.
- `/rpa` must continue to bootstrap the addon when invoked before ordinary initialization.
- Repeated fallback registration must remain safe.
- This correction ships in the pending `1.4.5` patch.

## Test Design

- Provide the existing slash registry through `_G` lookup while rejecting assignment to the `SlashCmdList` global binding.
- Call `RPA:RegisterFallbackSlashCommand` under that guard.
- Verify registration succeeds without binding reassignment and leaves the `ROLLINGPINAWARDS` handler available.
- Retain the existing slash bootstrap, command-routing, and full-suite coverage.
