# Friday Night Professions by Walters

A World of Warcraft Forever Beta addon that shows your current and maximum profession skill in the standard tooltip. It annotates Herbalism, Mining, and Skinning lines and recognized English herb and ore world-node titles without requirement lines. Recognized Fishing schools and pools show a separate `Fishing: current/max` line, and the exact English `Basic Campfire` world object shows a separate `Cooking: current/max` line. Their object titles stay unchanged, and the added lines use the current title font, color, and shadow. Item tooltips are excluded from the title fallback.

Fishing support applies only to hovered schools or pools. It does not change open-water casting, fishing bobbers, or catch chances. Cooking support applies only to `Basic Campfire`, not other cooking heat sources, spells, or items. The displayed value is your own skill, not a required level for the target.

The existing `/plt` command prints the five detected skill values and the last tooltip update error, if any.

## Current build

- Addon folder and identifier: `ProfessionLevelTooltipBeta`
- Version: `1.1.3`
- TOC interface: `16001`
- Target client: `_classic_beta_` (WoW Forever Beta)

To install, copy the `ProfessionLevelTooltipBeta` folder containing the `.toc` and `.lua` files into the relevant WoW client's `Interface/AddOns` directory, then load or reload the game. The `tests` directory, `package.json`, and this README are development files and are not needed in the installed addon folder.

## Testing

With Node.js and npm installed, run `npm install` followed by `npm test`. The test uses Fengari mocks for herb and ore nodes, requirement lines, skinnable units, Fishing schools and pools, Basic Campfire, unrelated objects, item and spell exclusions, unlearned skills, missing APIs, skill changes, hover reuse, repeated updates, multiline sizing, and font/color inheritance and restoration. Fishing and Cooking have been confirmed in game with the current styling. Mining is covered by mocks but still needs a live hover check.

Herb and ore title fallbacks use fixed lists of standard English node names. Fishing and Cooking title recognition need the client's world-object tooltip callback. Other locales and custom node names may need additional support.

## Changelog

### 1.1.3

- Matched the Fishing and Cooking lines to their current tooltip title style without changing the title or shared font objects.

### 1.1.2

- Moved Fishing and Cooking values to their own labeled lines below the unchanged object title.

## Source and release status

This repository contains the local development copy used for the installed Classic Beta addon. No third-party library code is included in the runtime addon. A license has not yet been chosen, so no license is granted by this repository until one is added.
