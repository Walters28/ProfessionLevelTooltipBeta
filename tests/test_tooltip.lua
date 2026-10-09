local function line(text, isTitle)
    return {
        text = text,
        fontFace = isTitle and "Title.ttf" or "Body.ttf",
        fontSize = isTitle and 16 or 12,
        fontFlags = isTitle and "OUTLINE" or "",
        red = isTitle and 1 or 1,
        green = isTitle and 0.82 or 1,
        blue = isTitle and 0.25 or 1,
        alpha = 1,
        shadowRed = 0,
        shadowGreen = 0,
        shadowBlue = 0,
        shadowAlpha = isTitle and 0.8 or 0,
        shadowX = isTitle and 1 or 0,
        shadowY = isTitle and -1 or 0,
        GetObjectType = function() return "FontString" end,
        IsVisible = function() return true end,
        GetText = function(self) return self.text end,
        SetText = function(self, value) self.text = value end,
        GetFont = function(self) return self.fontFace, self.fontSize, self.fontFlags end,
        SetFont = function(self, face, size, flags)
            self.fontFace, self.fontSize, self.fontFlags = face, size, flags
        end,
        GetTextColor = function(self) return self.red, self.green, self.blue, self.alpha end,
        SetTextColor = function(self, red, green, blue, alpha)
            self.red, self.green, self.blue, self.alpha = red, green, blue, alpha
        end,
        GetShadowColor = function(self)
            return self.shadowRed, self.shadowGreen, self.shadowBlue, self.shadowAlpha
        end,
        SetShadowColor = function(self, red, green, blue, alpha)
            self.shadowRed, self.shadowGreen, self.shadowBlue, self.shadowAlpha =
                red, green, blue, alpha
        end,
        GetShadowOffset = function(self) return self.shadowX, self.shadowY end,
        SetShadowOffset = function(self, x, y) self.shadowX, self.shadowY = x, y end,
        GetStringWidth = function(self) return #self.text * self.fontSize / 2 end,
    }
end

GameTooltip = { scripts = {}, width = 100, height = 20, itemLink = nil, lines = {} }
function GameTooltip:HookScript(event, handler) self.scripts[event] = handler end
function GameTooltip:IsShown() return true end
function GameTooltip:NumLines() return #self.lines end
function GameTooltip:GetRegions() return table.unpack(self.lines) end
function GameTooltip:GetWidth() return self.width end
function GameTooltip:SetWidth(value) self.width = value end
function GameTooltip:GetHeight() return self.height end
function GameTooltip:AddLine(text)
    local index = #self.lines + 1
    self.lines[index] = line(text)
    _G["GameTooltipTextLeft" .. index] = self.lines[index]
end
function GameTooltip:Show()
    self.height = 8 + #self.lines * 14
    if self.secureShowHook then self.secureShowHook(self) end
end
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
    GameTooltip.lines = { line(title, true) }
    if second then GameTooltip.lines[2] = line(second) end
    GameTooltip.height = 8 + #GameTooltip.lines * 14
    GameTooltipTextLeft1, GameTooltipTextLeft2 = GameTooltip.lines[1], GameTooltip.lines[2]
    GameTooltip.itemLink = itemLink
    GameTooltip.scripts.OnShow(GameTooltip)
    if kind then tooltipCallbacks[Enum.TooltipDataType[kind]](GameTooltip) end
    return GameTooltip.lines[1].text, GameTooltip.lines[2] and GameTooltip.lines[2].text,
        GameTooltip.lines[3] and GameTooltip.lines[3].text
end

local function assertSameStyle(actual, expected)
    local af, as, ax = actual:GetFont()
    local ef, es, ex = expected:GetFont()
    assert(af == ef and as == es and ax == ex, "font differs from title")
    local ar, ag, ab, aa = actual:GetTextColor()
    local er, eg, eb, ea = expected:GetTextColor()
    assert(ar == er and ag == eg and ab == eb and aa == ea, "color differs from title")
    local asr, asg, asb, asa = actual:GetShadowColor()
    local esr, esg, esb, esa = expected:GetShadowColor()
    assert(asr == esr and asg == esg and asb == esb and asa == esa,
        "shadow color differs from title")
    local axo, ayo = actual:GetShadowOffset()
    local exo, eyo = expected:GetShadowOffset()
    assert(axo == exo and ayo == eyo, "shadow offset differs from title")
end

local function assertBodyStyle(value)
    local face, size, flags = value:GetFont()
    local red, green, blue, alpha = value:GetTextColor()
    assert(face == "Body.ttf" and size == 12 and flags == "")
    assert(red == 1 and green == 1 and blue == 1 and alpha == 1)
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
hooksecurefunc = function(frame, method, handler)
    assert(method == "Show")
    frame.secureShowHook = handler
end
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

local third
title, second, third = show("School of Deviate Fish", nil, nil, "Object")
assert(title == "School of Deviate Fish" and second == "Fishing: 90/150" and not third)
assert(GameTooltip:NumLines() == 2 and GameTooltip:GetHeight() > 22)
assert(GameTooltip:GetWidth() >= GameTooltipTextLeft2:GetStringWidth() + 24)
assertSameStyle(GameTooltipTextLeft2, GameTooltipTextLeft1)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Fishing: 90/150")
GameTooltipTextLeft1:SetFont("Dynamic.ttf", 20, "THICKOUTLINE")
GameTooltipTextLeft1:SetTextColor(0.3, 0.6, 0.9, 1)
GameTooltipTextLeft1:SetShadowOffset(2, -2)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assertSameStyle(GameTooltipTextLeft2, GameTooltipTextLeft1)
skillInfo[4] = { "Fishing", 91, 150 }
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Fishing: 91/150")
skillInfo[4] = { "Fishing", 90, 150 }
title, second = show("Oily Blackmouth School", nil, nil, "Object")
assert(title == "Oily Blackmouth School" and second == "Fishing: 90/150")
title, second = show("Pool of Fish", nil, nil, "Object")
assert(title == "Pool of Fish" and second == "Fishing: 90/150")
title, second, third = show("School of Deviate Fish", "Requires Fishing (50)", nil, "Object")
assert(title == "School of Deviate Fish" and second == "Requires Fishing (50)"
    and third == "Fishing: 90/150" and GameTooltip:NumLines() == 3)
assertBodyStyle(GameTooltipTextLeft2)
assertSameStyle(GameTooltipTextLeft3, GameTooltipTextLeft1)
title, second = show("School of Deviate Fish (90/150)", nil, nil, "Object")
assert(title == "School of Deviate Fish" and second == "Fishing: 90/150")
assert(show("School of Deviate Fish", nil, "item:999", "Item") == "School of Deviate Fish")
assert(GameTooltip:NumLines() == 1)
title, second = show("Fishing Rod", "Requires Fishing (50)", "item:999", "Item")
assert(title == "Fishing Rod" and second == "Requires Fishing (50)")
assert(show("School of Deviate Fish") == "School of Deviate Fish")
assert(show("Fishing Bobber", nil, nil, "Object") == "Fishing Bobber")
assert(show("Pool of Acid", nil, nil, "Object") == "Pool of Acid")
assert(show("School of Magic", nil, nil, "Unit") == "School of Magic")
title, second, third = show("Basic Campfire", nil, nil, "Object")
assert(title == "Basic Campfire" and second == "Cooking: 80/150" and not third)
assert(GameTooltip:NumLines() == 2 and GameTooltip:GetHeight() > 22)
assertSameStyle(GameTooltipTextLeft2, GameTooltipTextLeft1)
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Cooking: 80/150")
local getFont, getShadowColor = GameTooltipTextLeft1.GetFont, GameTooltipTextLeft1.GetShadowColor
GameTooltipTextLeft1.GetFont, GameTooltipTextLeft1.GetShadowColor = nil, nil
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
GameTooltipTextLeft1.GetFont, GameTooltipTextLeft1.GetShadowColor = getFont, getShadowColor
skillInfo[5] = { "Cooking", 81, 150 }
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Cooking: 81/150")
skillInfo[5] = { "Cooking", 80, 150 }

-- Reuse one visible tooltip without an OnHide event between object types.
GameTooltipTextLeft1:SetText("School of Deviate Fish")
tooltipCallbacks[Enum.TooltipDataType.Object](GameTooltip)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Fishing: 90/150")
GameTooltipTextLeft1:SetText("Basic Campfire")
tooltipCallbacks[Enum.TooltipDataType.Object](GameTooltip)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Cooking: 80/150")
skillInfo[5] = nil
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "")
skillInfo[5] = { "Cooking", 80, 150 }
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltip:NumLines() == 2 and GameTooltipTextLeft2.text == "Cooking: 80/150")
GameTooltipTextLeft1:SetText("Fishing Rod")
GameTooltip.itemLink = "item:999"
tooltipCallbacks[Enum.TooltipDataType.Item](GameTooltip)
assert(GameTooltipTextLeft2.text == "")
assertBodyStyle(GameTooltipTextLeft2)

title, second = show("Basic Campfire (80/150)", nil, nil, "Object")
assert(title == "Basic Campfire" and second == "Cooking: 80/150")
local ownedLine = GameTooltipTextLeft2
GameTooltip.scripts.OnHide(GameTooltip)
assert(ownedLine.text == "")
assertBodyStyle(ownedLine)
assert(show("Basic Campfire", nil, "item:123", "Item") == "Basic Campfire")
assert(GameTooltip:NumLines() == 1)
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
title, second = show("Basic Campfire", nil, nil, "Object")
assert(title == "Basic Campfire" and second == "Cooking: 60/150")
C_SkillInfo = nil
GetProfessions, GetNumSkillLines, GetSkillLineInfo = oldProfessions, oldCount, oldSkill

SlashCmdList.PROFESSIONLEVELTOOLTIPBETA()
print("Gathering tooltip mocks passed")
