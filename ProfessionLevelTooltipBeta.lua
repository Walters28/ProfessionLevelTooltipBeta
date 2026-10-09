local tooltip = GameTooltip
local editedLines = setmetatable({}, { __mode = "k" })
local blockedTooltip = false
local lastError
local objectTooltip = false
local addedSkillLine, addedSkillText, addedSkillOriginalStyle
local updatingTooltip = false

-- Standard herb world-object names. A gatherable plant can show only its
-- name, with no visible "Herbalism" requirement line to annotate.
local herbNodes = {
    ["Peacebloom"] = true, ["Silverleaf"] = true, ["Earthroot"] = true,
    ["Mageroyal"] = true, ["Briarthorn"] = true, ["Stranglekelp"] = true,
    ["Bruiseweed"] = true, ["Wild Steelbloom"] = true, ["Grave Moss"] = true,
    ["Kingsblood"] = true, ["Liferoot"] = true, ["Fadeleaf"] = true,
    ["Goldthorn"] = true, ["Khadgar's Whisker"] = true, ["Wintersbite"] = true,
    ["Firebloom"] = true, ["Purple Lotus"] = true, ["Arthas' Tears"] = true,
    ["Sungrass"] = true, ["Blindweed"] = true, ["Ghost Mushroom"] = true,
    ["Gromsblood"] = true, ["Golden Sansam"] = true, ["Dreamfoil"] = true,
    ["Mountain Silversage"] = true, ["Plaguebloom"] = true,
    ["Icecap"] = true, ["Black Lotus"] = true,
}

-- Standard English ore nodes whose tooltips can show only the node name.
local miningNodes = {
    ["Copper Vein"] = true, ["Tin Vein"] = true, ["Silver Vein"] = true,
    ["Iron Deposit"] = true, ["Gold Vein"] = true,
    ["Mithril Deposit"] = true, ["Truesilver Deposit"] = true,
    ["Small Thorium Vein"] = true, ["Rich Thorium Vein"] = true,
    ["Dark Iron Deposit"] = true, ["Small Obsidian Chunk"] = true,
    ["Large Obsidian Chunk"] = true,
}

local function fishingSchoolTitle(text)
    -- Only use these names when the tooltip system identifies a world object.
    return text:find("School of ", 1, true) == 1
        or text:match(" School$") ~= nil
        or text:match(" Fishing Pool$") ~= nil
        or (text:find("Pool of ", 1, true) == 1 and text:find("Fish", 1, true) ~= nil)
end

local function usable(value)
    return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

local function readFontStyle(line)
    local style = {}
    if type(line.GetFont) == "function" then
        local ok, face, size, flags = pcall(line.GetFont, line)
        if ok and usable(face) and usable(size) and (flags == nil or usable(flags)) then
            style.font = { face, size, flags }
        end
    end
    if type(line.GetTextColor) == "function" then
        local ok, red, green, blue, alpha = pcall(line.GetTextColor, line)
        if ok and usable(red) and usable(green) and usable(blue)
            and (alpha == nil or usable(alpha)) then
            style.color = { red, green, blue, alpha }
        end
    end
    if type(line.GetShadowColor) == "function" then
        local ok, red, green, blue, alpha = pcall(line.GetShadowColor, line)
        if ok and usable(red) and usable(green) and usable(blue)
            and (alpha == nil or usable(alpha)) then
            style.shadowColor = { red, green, blue, alpha }
        end
    end
    if type(line.GetShadowOffset) == "function" then
        local ok, x, y = pcall(line.GetShadowOffset, line)
        if ok and usable(x) and usable(y) then style.shadowOffset = { x, y } end
    end
    return style
end

local function sameStyleValues(first, second, count)
    if not first or not second then return false end
    for index = 1, count do
        if first[index] ~= second[index] then return false end
    end
    return true
end

local function applyFontStyle(line, style)
    if not style then return false end
    local current = readFontStyle(line)
    local changed = false
    if style.font and type(line.SetFont) == "function"
        and not sameStyleValues(style.font, current.font, 3) then
        local ok, result = pcall(line.SetFont, line,
            style.font[1], style.font[2], style.font[3])
        changed = (ok and result ~= false) or changed
    end
    if style.color and type(line.SetTextColor) == "function"
        and not sameStyleValues(style.color, current.color, 4) then
        changed = pcall(line.SetTextColor, line,
            style.color[1], style.color[2], style.color[3], style.color[4]) or changed
    end
    if style.shadowColor and type(line.SetShadowColor) == "function"
        and not sameStyleValues(style.shadowColor, current.shadowColor, 4) then
        changed = pcall(line.SetShadowColor, line,
            style.shadowColor[1], style.shadowColor[2],
            style.shadowColor[3], style.shadowColor[4]) or changed
    end
    if style.shadowOffset and type(line.SetShadowOffset) == "function"
        and not sameStyleValues(style.shadowOffset, current.shadowOffset, 2) then
        changed = pcall(line.SetShadowOffset, line,
            style.shadowOffset[1], style.shadowOffset[2]) or changed
    end
    return changed
end

local function professionLevels()
    local levels = {}

    if GetProfessions and GetProfessionInfo then
        for _, index in pairs({ GetProfessions() }) do
            local name, _, rank, maxRank = GetProfessionInfo(index)
            if usable(name) and usable(rank) and usable(maxRank)
                and (name == "Herbalism" or name == "Mining" or name == "Skinning"
                    or name == "Fishing" or name == "Cooking")
                and type(rank) == "number" and type(maxRank) == "number" then
                levels[name] = rank .. "/" .. maxRank
            end
        end
    end

    local countSkills = (C_SkillInfo and C_SkillInfo.GetNumSkillLines) or GetNumSkillLines
    local getSkill = (C_SkillInfo and C_SkillInfo.GetSkillLineInfo) or GetSkillLineInfo
    if not countSkills or not getSkill then
        return levels
    end

    for index = 1, countSkills() do
        local name, isHeader, _, rank, _, _, maxRank = getSkill(index)
        if usable(name) and type(name) == "table" then
            local skill = name
            name, isHeader, rank, maxRank = skill.name, skill.isHeader, skill.rank, skill.maxRank
        end
        if usable(name) and usable(isHeader) and usable(rank) and usable(maxRank)
            and not isHeader and (name == "Herbalism" or name == "Mining"
                or name == "Skinning" or name == "Fishing" or name == "Cooking")
            and type(rank) == "number" and type(maxRank) == "number" and not levels[name] then
            levels[name] = rank .. "/" .. maxRank
        end
    end
    return levels
end

local function professionForLine(text, levels)
    if levels.Herbalism and text:find("Herbalism", 1, true) then
        return "Herbalism"
    end
    if levels.Mining and (text == "Mining" or text:find("Requires Mining", 1, true)
        or text:find("Mineable", 1, true)) then
        return "Mining"
    end
    if levels.Skinning and
        (text:find("Skinning", 1, true) or text:find("Skinnable", 1, true)) then
        return "Skinning"
    end
end

local function updateLine(line, levels, forcedProfession)
    if not line or line:GetObjectType() ~= "FontString" or not line:IsVisible() then return end
    local text = line:GetText()
    if not usable(text) then return end
    local previous = editedLines[line]
    local original = previous and text == previous.edited and previous.original or text
    local profession = forcedProfession or professionForLine(original, levels)
    if not profession then return end
    local edited = original .. " (" .. levels[profession] .. ")"
    if text ~= edited then
        local red, green, blue, alpha = line:GetTextColor()
        line:SetText(edited)
        line:SetTextColor(red, green, blue, alpha)
        editedLines[line] = { original = original, edited = edited }
    end
    return line:GetStringWidth()
end

local function gatheringTitleWithoutRequirement(shownTooltip, levels)
    if shownTooltip ~= tooltip then return end
    local title = _G.GameTooltipTextLeft1
    if not title or not usable(title:GetText()) then return end
    local previous = editedLines[title]
    local text = title:GetText()
    local original = previous and text == previous.edited and previous.original or text
    local profession
    if herbNodes[original] and levels.Herbalism then
        profession = "Herbalism"
    elseif miningNodes[original] and levels.Mining then
        profession = "Mining"
    end
    if not profession then return end
    -- Items can have the same title as world objects. Never add a skill
    -- overlay to bag, merchant or auction item tooltips.
    if type(shownTooltip.GetItem) ~= "function" then return end
    local ok, _, link = pcall(shownTooltip.GetItem, shownTooltip)
    if not ok or (link ~= nil and (not usable(link) or link)) then return end
    for index = 2, shownTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. index]
        local lineText = line and line:GetText()
        if usable(lineText) then
            local lineEdit = editedLines[line]
            local lineOriginal = lineEdit and lineText == lineEdit.edited
                and lineEdit.original or lineText
            if professionForLine(lineOriginal, levels) == profession then
                -- OnShow may have added the title fallback before this line arrived.
                -- Only undo a title edit that still matches our own text.
                if previous and text == previous.edited then
                    local red, green, blue, alpha = title:GetTextColor()
                    title:SetText(previous.original)
                    title:SetTextColor(red, green, blue, alpha)
                    editedLines[title] = nil
                end
                return
            end
        end
    end
    return title, profession
end

local function clearAddedSkillLine()
    if addedSkillLine and usable(addedSkillLine:GetText())
        and addedSkillLine:GetText() == addedSkillText then
        local changed = addedSkillText ~= ""
        if changed then addedSkillLine:SetText("") end
        changed = applyFontStyle(addedSkillLine, addedSkillOriginalStyle) or changed
        addedSkillText = ""
        return changed
    end
    addedSkillLine, addedSkillText, addedSkillOriginalStyle = nil, nil, nil
    return false
end

local function updateLabeledSkillLine(shownTooltip, levels)
    local title = shownTooltip == tooltip and _G.GameTooltipTextLeft1
    local text = title and title:GetText()
    if not objectTooltip or not usable(text) or type(shownTooltip.GetItem) ~= "function" then
        if clearAddedSkillLine() then shownTooltip:Show() end
        return
    end
    local ok, _, link = pcall(shownTooltip.GetItem, shownTooltip)
    if not ok or (link ~= nil and (not usable(link) or link)) then
        if clearAddedSkillLine() then shownTooltip:Show() end
        return
    end

    -- A previous build placed the number on the title itself. Normalize only
    -- known world-object titles before using a separate skill line.
    local oldTitle = text:match("^(.-) %(%d+/%d+%)$")
    if oldTitle and (oldTitle == "Basic Campfire" or fishingSchoolTitle(oldTitle)) then
        title:SetText(oldTitle)
        text = oldTitle
    end

    local profession
    if text == "Basic Campfire" and levels.Cooking then
        profession = "Cooking"
    elseif fishingSchoolTitle(text) and levels.Fishing then
        profession = "Fishing"
    end
    if not profession then
        if clearAddedSkillLine() then shownTooltip:Show() end
        return
    end

    local label = profession .. ": " .. levels[profession]
    local changed = false
    local lineIsCurrent = false
    for index = 2, shownTooltip:NumLines() do
        if _G["GameTooltipTextLeft" .. index] == addedSkillLine then
            lineIsCurrent = true
            break
        end
    end
    if not lineIsCurrent then
        addedSkillLine, addedSkillText, addedSkillOriginalStyle = nil, nil, nil
    end
    if addedSkillLine and usable(addedSkillLine:GetText())
        and addedSkillLine:GetText() == addedSkillText then
        if addedSkillText ~= label then
            addedSkillLine:SetText(label)
            changed = true
        end
    else
        shownTooltip:AddLine(label, 1, 1, 1)
        addedSkillLine = _G["GameTooltipTextLeft" .. shownTooltip:NumLines()]
        if addedSkillLine then addedSkillOriginalStyle = readFontStyle(addedSkillLine) end
        changed = true
    end
    addedSkillText = label
    if addedSkillLine then
        changed = applyFontStyle(addedSkillLine, readFontStyle(title)) or changed
    end
    if changed then shownTooltip:Show() end
    return addedSkillLine and addedSkillLine:GetStringWidth()
end

local function updateTooltip(shownTooltip)
    shownTooltip = shownTooltip or tooltip
    if not shownTooltip:IsShown() then return end
    local levels = professionLevels()
    local professionWidth = 0
    if shownTooltip == tooltip then
        local gatheringTitle, titleProfession = gatheringTitleWithoutRequirement(shownTooltip, levels)
        for index = 2, tooltip:NumLines() do
            professionWidth = math.max(professionWidth,
                updateLine(_G["GameTooltipTextLeft" .. index], levels) or 0)
        end
        if gatheringTitle then
            professionWidth = math.max(professionWidth,
                updateLine(gatheringTitle, levels, titleProfession) or 0)
        end
    end
    for _, region in ipairs({ shownTooltip:GetRegions() }) do
        professionWidth = math.max(professionWidth, updateLine(region, levels) or 0)
    end
    professionWidth = math.max(professionWidth, updateLabeledSkillLine(shownTooltip, levels) or 0)
    if professionWidth > 0 and shownTooltip:GetWidth() < professionWidth + 24 then
        shownTooltip:SetWidth(professionWidth + 24)
    end
end

local function safeUpdate(shownTooltip)
    if blockedTooltip or updatingTooltip then return end
    updatingTooltip = true
    local ok, err = pcall(updateTooltip, shownTooltip)
    updatingTooltip = false
    if not ok then
        blockedTooltip = true
        lastError = tostring(err)
    end
end

tooltip:HookScript("OnShow", function(shownTooltip)
    blockedTooltip = false
    safeUpdate(shownTooltip)
end)
tooltip:HookScript("OnHide", function()
    clearAddedSkillLine()
    addedSkillLine, addedSkillText, addedSkillOriginalStyle = nil, nil, nil
    blockedTooltip = false
    objectTooltip = false
end)
hooksecurefunc(tooltip, "Show", safeUpdate)

local elapsed = 0
tooltip:HookScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.3 then
        elapsed = 0
        safeUpdate()
    end
end)

SLASH_PROFESSIONLEVELTOOLTIPBETA1 = "/plt"
SlashCmdList.PROFESSIONLEVELTOOLTIPBETA = function()
    local levels = professionLevels()
    print("FridayNightProfessions: Herbalism " .. tostring(levels.Herbalism or "not found")
        .. ", Mining " .. tostring(levels.Mining or "not found")
        .. ", Skinning " .. tostring(levels.Skinning or "not found")
        .. ", Fishing " .. tostring(levels.Fishing or "not found")
        .. ", Cooking " .. tostring(levels.Cooking or "not found")
        .. "; last update error: " .. tostring(lastError or "none"))
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= "ProfessionLevelTooltipBeta" then return end
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType then
            local function onTooltip(shownTooltip, isObject)
                if shownTooltip == tooltip then
                    objectTooltip = isObject
                    blockedTooltip = false
                    safeUpdate()
                end
            end
            if Enum.TooltipDataType.Object then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object,
                    function(shownTooltip) onTooltip(shownTooltip, true) end)
            end
            if Enum.TooltipDataType.Unit then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,
                    function(shownTooltip) onTooltip(shownTooltip, false) end)
            end
            if Enum.TooltipDataType.Item then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,
                    function(shownTooltip) onTooltip(shownTooltip, false) end)
            end
            if Enum.TooltipDataType.Spell then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell,
                    function(shownTooltip) onTooltip(shownTooltip, false) end)
            end
        end
    else
        safeUpdate()
    end
end)
