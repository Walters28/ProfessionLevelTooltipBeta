# FridayNightProfessions by Walters

A World of Warcraft Forever Beta addon that shows your current and maximum profession skill in the standard tooltip. It annotates Herbalism, Mining, and Skinning lines; recognized English herb and ore world-node titles without requirement lines; and recognized Fishing school or pool titles when the client identifies the tooltip as a world object. It also shows Cooking on the exact English `Basic Campfire` world-object tooltip. Item tooltips are excluded from the title fallback.

Fishing support applies only to hovered schools or pools. It does not change open-water casting, fishing bobbers, or catch chances. Cooking support applies only to `Basic Campfire`, not other cooking heat sources, spells, or items. The displayed value is your own skill, not a required level for the target.

The existing `/plt` command prints the five detected skill values and the last tooltip update error, if any.

## Current build

- Addon folder and identifier: `ProfessionLevelTooltipBeta`
- Version: `1.1.1`
- TOC interface: `16001`
- Target client: `_classic_beta_` (WoW Forever Beta)

To install, copy the `ProfessionLevelTooltipBeta` folder containing the `.toc` and `.lua` files into the relevant WoW client's `Interface/AddOns` directory, then load or reload the game. The `tests` directory, `package.json`, and this README are development files and are not needed in the installed addon folder.

## Testing

With Node.js and npm installed, run `npm install` followed by `npm test`. The test uses Fengari mocks for herb and ore nodes, requirement lines, skinnable units, Fishing schools and pools, Basic Campfire, unrelated objects, item and spell exclusions, unlearned skills, missing APIs, and repeated updates. Live screenshots confirmed a Fishing school displays the skill value and that `Basic Campfire` has a hover tooltip; the new Cooking suffix still needs in-game verification before release.

Herb and ore title fallbacks use fixed lists of standard English node names. Fishing and Cooking title recognition need the client's world-object tooltip callback. Other locales and custom node names may need additional support.

## Source and release status

This repository is prepared from the local development copy used for the installed Classic Beta addon. No third-party artwork or library code is included in the addon itself. A license has not yet been chosen, so no license is granted by this repository until one is added.
