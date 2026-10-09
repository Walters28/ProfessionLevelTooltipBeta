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
local function show(title, second, itemLink)
    GameTooltip.lines = { line(title) }
    if second then GameTooltip.lines[2] = line(second) end
    GameTooltipTextLeft1, GameTooltipTextLeft2 = GameTooltip.lines[1], GameTooltip.lines[2]
    GameTooltip.itemLink = itemLink
    GameTooltip.scripts.OnShow(GameTooltip)
    return GameTooltip.lines[1].text, GameTooltip.lines[2] and GameTooltip.lines[2].text
end

GetProfessions = function() return 1, 2 end
GetProfessionInfo = function(index)
    if index == 1 then return "Herbalism", nil, 120, 225 end
    if index == 2 then return "Skinning", nil, 150, 225 end
end
hooksecurefunc = function() end
SlashCmdList = {}
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end

assert(load(__addon))()
local title, second = show("Wild Steelbloom")
SlashCmdList.PROFESSIONLEVELTOOLTIPBETA()
assert(title == "Wild Steelbloom (120/225)" and not second,
    "Wild Steelbloom world node must show current/max: " .. tostring(title))
GameTooltip.scripts.OnUpdate(GameTooltip, 0.4)
assert(GameTooltipTextLeft1.text == "Wild Steelbloom (120/225)",
    "repeated updates must not append another skill value")
title = show("Bruiseweed")
assert(title == "Bruiseweed (120/225)",
    "another herb world node must use the same fallback")
title = show("Wild Steelbloom", nil, "item:3355")
assert(title == "Wild Steelbloom",
    "inventory herb items must not receive a node overlay")
title, second = show("Peacebloom", "Requires Herbalism (1)")
assert(title == "Peacebloom" and second == "Requires Herbalism (1) (120/225)",
    "existing requirement line must remain the sole Herbalism overlay")
title, second = show("Boar", "Skinnable")
assert(title == "Boar" and second == "Skinnable (150/225)",
    "working Skinning behavior must remain unchanged")
title = show("Chest")
assert(title == "Chest", "non-herb objects must remain unchanged")
print("Profession tooltip node/item and Skinning mocks passed")
