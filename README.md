# FridayNightProfessions by Walters

A World of Warcraft Forever Beta addon that shows your current and maximum gathering skill in the standard tooltip. It annotates Herbalism, Mining, and Skinning requirement lines; recognized English herb and ore world-node titles without requirement lines; and recognized Fishing school or pool titles when the client identifies the tooltip as a world object. Item tooltips are excluded from the node-title fallback.

Fishing support applies only to hovered schools or pools. It does not change open-water casting, fishing bobbers, or catch chances. The displayed value is your own skill, not a required level for the target. Cooking and campfire tooltips are not included until a live campfire tooltip can be checked.

The existing `/plt` command prints the four detected skill values and the last tooltip update error, if any.

## Current build

- Addon folder and identifier: `ProfessionLevelTooltipBeta`
- Version: `1.1.0`
- TOC interface: `16001`
- Target client: `_classic_beta_` (WoW Forever Beta)

To install, copy the `ProfessionLevelTooltipBeta` folder containing the `.toc` and `.lua` files into the relevant WoW client's `Interface/AddOns` directory, then load or reload the game. The `tests` directory, `package.json`, and this README are development files and are not needed in the installed addon folder.

## Testing

With Node.js and npm installed, run `npm install` followed by `npm test`. The test uses Fengari mocks for herb and ore nodes, requirement lines, skinnable units, Fishing schools and pools, unrelated objects, item exclusions, unlearned skills, missing APIs, and repeated updates. These mocks do not confirm the exact tooltip layout of live game objects; verify in game before release.

Herb and ore title fallbacks use fixed lists of standard English node names. Fishing school and pool recognition needs the client's world-object tooltip callback. Other locales and custom node names may need additional support.

## Source and release status

This repository is prepared from the local development copy used for the installed Classic Beta addon. No third-party artwork or library code is included in the addon itself. A license has not yet been chosen, so no license is granted by this repository until one is added.
