# Wipeout Run Prototype

Roblox obstacle-course prototype focused on simple, readable Wipeout-style movement challenges.

Current build includes:

- A straight walled course with no required size switching.
- Four obstacle zones: floating step pads, spinning sweeper, moving punch blocks, and final spinner bridge.
- Water pools that send the player back to the latest checkpoint/start of that obstacle instead of hard-killing the run.
- Green checkpoints after each major obstacle.
- Coins along the main route plus bonus coins on riskier lines.
- Run timer and best-time HUD for replay attempts.
- A one-paste Studio installer and a standalone course builder.

## Fastest Setup Without Rojo

1. Open Roblox Studio.
2. Create a new Baseplate.
3. Open **View > Command Bar**.
4. Paste the full contents of `studio-command-bar/InstallTinyGiantObby.lua`.
5. Press Enter.
6. Press Play.

## Controls

| Platform | Controls |
| --- | --- |
| Keyboard | Standard Roblox movement and jump |
| Mobile | Standard Roblox thumbstick and jump |
| Gamepad | Standard Roblox movement and jump |

## Test Pass

Use Play Solo and check:

1. The player spawns at the first green checkpoint facing down the course.
2. The HUD title says `WIPEOUT RUN`.
3. Falling into the water under the step pads resets the player to the start of that obstacle.
4. The yellow sweeper arms rotate during Play.
5. The gray punch blocks move side-to-side during Play.
6. Touching a pit or sweeper resets the player near the latest checkpoint.
7. The finish gate records a run time and best time.

## Next Build Step

Tune spacing, timing, and visuals after a manual playtest. The next meaningful upgrade is stronger presentation: themed set dressing, animated crowd/arena props, sound effects, and better reward feedback.
