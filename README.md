# Profession Level Tooltip Beta

A small World of Warcraft Classic Beta addon that appends your current and maximum Herbalism or Skinning skill to matching lines in the standard game tooltip. It also adds the Herbalism value to the title of recognized English herb world nodes when the tooltip has no Herbalism requirement line. Herb items in bags, shops, or auctions are excluded from that title fallback.

The `/plt` command prints the detected Herbalism and Skinning values and the last tooltip update error, if any.

## Current build

- Addon folder and identifier: `ProfessionLevelTooltipBeta`
- Version: `1.0.8`
- TOC interface: `16001`
- Tested installation: `_classic_beta_` on October 7, 2026

To install, copy the `ProfessionLevelTooltipBeta` folder containing the `.toc` and `.lua` files into the relevant WoW client's `Interface/AddOns` directory, then load or reload the game. The `tests` directory, `package.json`, and this README are development files and are not needed in the installed addon folder.

## Testing

With Node.js and npm installed, run `npm install` followed by `npm test`. The test uses Fengari to mock tooltips for herb nodes, herb items, Herbalism requirement lines, skinnable units, unrelated objects, and repeated updates. These mocks cannot confirm the exact tooltip layout of every live game object; verify in game as well.

The title fallback uses a fixed list of standard English herb names. Other locales and custom herb names may need additional support.

## Source and release status

This repository is prepared from the local development copy used for the installed Classic Beta addon. No third-party artwork or library code is included in the addon itself. A license has not yet been chosen, so no license is granted by this repository until one is added.
