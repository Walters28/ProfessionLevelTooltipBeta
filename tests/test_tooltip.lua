local function line(text)
    return {
        text = text,
        GetObjectType = function() return "FontString" end,
        IsVisible = function() return true end,
        GetText = function(self) return self.text end,
        SetText = function(self, value) self.text = value end,
        GetTextColor = function() return 1, 1, 1, 1 end,
        SetTextColor = function() end,
        GetStringWidth = function(self) return #self.text * 6 end,
    }
end

GameTooltip = { scripts = {}, width = 100, itemLink = nil, lines = {} }
function GameTooltip:HookScript(event, handler) self.scripts[event] = handler end
function GameTooltip:IsShown() return true end
function GameTooltip:NumLines() return #self.lines end
function GameTooltip:GetRegions() return table.unpack(self.lines) end
function GameTooltip:GetWidth() return self.width end
function GameTooltip:SetWidth(value) self.width = value end
function GameTooltip:GetItem() return nil, self.itemLink end

local tooltipCallbacks = {}
Enum = { TooltipDataType = { Object = 1, Unit = 2, Item = 3, Spell = 4 } }
TooltipDataProcessor = {
    AddTooltipPostCall = function(kind, callback)
        tooltipCallbacks[kind] = callback
    end,
}

local function show(title, second, itemLink, kind)
    GameTooltip.scripts.OnHide(GameTooltip)
    GameTooltip.lines = { line(title) }
    if second then GameTooltip.lines[2] = line(second) end
    GameTooltipTextLeft1, GameTooltipTextLeft2 = GameTooltip.lines[1], GameTooltip.lines[2]
    GameTooltip.itemLink = itemLink
    GameTooltip.scripts.OnShow(GameTooltip)
    if kind then tooltipCallbacks[Enum.TooltipDataType[kind]](GameTooltip) end
    return GameTooltip.lines[1].text, GameTooltip.lines[2] and GameTooltip.lines[2].text
end

local skillInfo = {
    [1] = { "Herbalism", 120, 225 },
    [2] = { "Skinning", 150, 225 },
    [4] = { "Fishing", 90, 150 },
    [5] = { "Cooking", 80, 150 },
}
GetProfessions = function() return 1, 2, nil, 4, 5 end
GetProfessionInfo = function(index)
    local info = skillInfo[index]
    if info then return info[1], nil, info[2], info[3] end
end
GetNumSkillLines = function() return 2 end
GetSkillLineInfo = function(index)
    if index == 1 then return "Professions", true end
    return "Mining", false, nil, 75, nil, nil, 150
end
hooksecurefunc = function() end
SlashCmdList = {}
local eventHandler
CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, handler) eventHandler = handler end,
    }
end

assert(load(__addon))()
eventHandler(nil, "ADDON_LOADED", "ProfessionLevelTooltipBeta")

local title, second = show("Wild Steelbloom")
assert(title == "Wild Steelbloom (120/225)" and not second)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltipTextLeft1.text == "Wild Steelbloom (120/225)")
title, second = show("Peacebloom", "Requires Herbalism (1)")
assert(title == "Peacebloom" and second == "Requires Herbalism (1) (120/225)")
assert(show("Wild Steelbloom", nil, "item:3355", "Item") == "Wild Steelbloom")

title, second = show("Copper Vein")
assert(title == "Copper Vein (75/150)" and not second)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltipTextLeft1.text == "Copper Vein (75/150)")
title, second = show("Iron Deposit", "Requires Mining (125)")
assert(title == "Iron Deposit" and second == "Requires Mining (125) (75/150)")
title, second = show("Rock Elemental", "Mineable", nil, "Unit")
assert(title == "Rock Elemental" and second == "Mineable (75/150)")
assert(show("Copper Vein", nil, "item:2770", "Item") == "Copper Vein")
title, second = show("Mining Pick", "Equip: Mining Pick", "Item")
assert(title == "Mining Pick" and second == "Equip: Mining Pick")
assert(show("Veta de cobre", nil, nil, "Object") == "Veta de cobre")

skillInfo[3] = { "Mining", 95, 150 }
local originalProfessions = GetProfessions
GetProfessions = function() return 1, 2, 3, 4, 5 end
assert(show("Copper Vein") == "Copper Vein (95/150)")
GetProfessions = originalProfessions
skillInfo[3] = nil

title, second = show("Boar", "Skinnable", nil, "Unit")
assert(title == "Boar" and second == "Skinnable (150/225)")

title, second = show("School of Deviate Fish", nil, nil, "Object")
assert(title == "School of Deviate Fish (90/150)" and not second)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltipTextLeft1.text == "School of Deviate Fish (90/150)")
assert(show("Oily Blackmouth School", nil, nil, "Object") ==
    "Oily Blackmouth School (90/150)")
assert(show("Pool of Fish", nil, nil, "Object") == "Pool of Fish (90/150)")
title, second = show("School of Deviate Fish", "Requires Fishing (50)", nil, "Object")
assert(title == "School of Deviate Fish" and second == "Requires Fishing (50) (90/150)")
assert(show("School of Deviate Fish", nil, "item:999", "Item") == "School of Deviate Fish")
title, second = show("Fishing Rod", "Requires Fishing (50)", "item:999", "Item")
assert(title == "Fishing Rod" and second == "Requires Fishing (50)")
assert(show("School of Deviate Fish") == "School of Deviate Fish")
assert(show("Fishing Bobber", nil, nil, "Object") == "Fishing Bobber")
assert(show("Pool of Acid", nil, nil, "Object") == "Pool of Acid")
assert(show("School of Magic", nil, nil, "Unit") == "School of Magic")
assert(show("Basic Campfire", nil, nil, "Object") == "Basic Campfire (80/150)")
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltipTextLeft1.text == "Basic Campfire (80/150)")
assert(show("Basic Campfire", nil, "item:123", "Item") == "Basic Campfire")
assert(show("Basic Campfire", nil, nil, "Spell") == "Basic Campfire")
assert(show("Basic Campfire", nil, nil, "Unit") == "Basic Campfire")
assert(show("Basic Campfire") == "Basic Campfire")
assert(show("Cooking Fire", nil, nil, "Object") == "Cooking Fire")
assert(show("Chest", nil, nil, "Object") == "Chest")

skillInfo[4] = nil
assert(show("School of Deviate Fish", nil, nil, "Object") == "School of Deviate Fish")
skillInfo[4] = { "Fishing", 90, 150 }

skillInfo[5] = nil
assert(show("Basic Campfire", nil, nil, "Object") == "Basic Campfire")
skillInfo[5] = { "Cooking", 80, 150 }

local getItem = GameTooltip.GetItem
GameTooltip.GetItem = nil
assert(show("Copper Vein") == "Copper Vein")
GameTooltip.GetItem = getItem

local oldProfessions, oldCount, oldSkill = GetProfessions, GetNumSkillLines, GetSkillLineInfo
GetProfessions, GetNumSkillLines, GetSkillLineInfo = nil, nil, nil
assert(show("Copper Vein") == "Copper Vein")
assert(show("School of Deviate Fish", nil, nil, "Object") == "School of Deviate Fish")
assert(show("Basic Campfire", nil, nil, "Object") == "Basic Campfire")

C_SkillInfo = {
    GetNumSkillLines = function() return 2 end,
    GetSkillLineInfo = function(index)
        if index == 1 then
            return { name = "Mining", isHeader = false, rank = 88, maxRank = 150 }
        end
        return { name = "Cooking", isHeader = false, rank = 60, maxRank = 150 }
    end,
}
assert(show("Iron Deposit") == "Iron Deposit (88/150)")
assert(show("Basic Campfire", nil, nil, "Object") == "Basic Campfire (60/150)")
C_SkillInfo = nil
GetProfessions, GetNumSkillLines, GetSkillLineInfo = oldProfessions, oldCount, oldSkill

SlashCmdList.PROFESSIONLEVELTOOLTIPBETA()
print("Gathering tooltip mocks passed")
