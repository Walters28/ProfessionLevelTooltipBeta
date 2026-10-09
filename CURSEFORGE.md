# CurseForge listing draft

Project name: **Friday Night Professions by Walters**

Short summary: Shows your profession skill on gathering and Basic Campfire tooltips in WoW Forever Beta.

## Description

Friday Night Professions by Walters adds your current and maximum skill to the standard tooltip for Herbalism, Mining, and Skinning interactions. It recognizes a fixed list of English herb and ore world-node names when the tooltip has no requirement line.

Fishing schools and recognized pools show a separate `Fishing: current/max` line. The exact English `Basic Campfire` world object shows a separate `Cooking: current/max` line. Those lines use the title's current font, color, and shadow without changing the title. The `/plt` command reports the five detected skill values and the last tooltip update error.

This beta build targets WoW Forever Beta (`Interface: 16001`). Fishing support requires the client's world-object tooltip callback and does not change open-water casting, bobbers, or catch chances. Cooking support applies to `Basic Campfire` only. The displayed skill is your character's skill, not the skill required by an object. Other locales and custom resource names may need support.

Fishing and Cooking were confirmed in game with the current styling. Mining has automated mock coverage but still needs a live hover check.

## 1.1.3 changelog

- Added current/max Herbalism, Mining, and Skinning values to matching gathering tooltips.
- Added labeled Fishing and Cooking lines for recognized fishing schools or pools and Basic Campfire.
- Matched the Fishing and Cooking lines to the current tooltip title style.
- Kept the installed folder name `ProfessionLevelTooltipBeta` and `/plt` command compatible.

Release maturity: **Beta**. A license still needs to be selected before publication; this draft does not choose one.
