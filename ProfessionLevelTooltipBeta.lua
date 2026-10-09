local tooltip = GameTooltip
local editedLines = setmetatable({}, { __mode = "k" })
local blockedTooltip = false
local lastError

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

local function usable(value)
    return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

local function professionLevels()
    local levels = {}

    if GetProfessions and GetProfessionInfo then
        local first, second = GetProfessions()
        for _, index in pairs({ first, second }) do
            local name, _, rank, maxRank = GetProfessionInfo(index)
            if usable(name) and usable(rank) and usable(maxRank)
                and (name == "Herbalism" or name == "Skinning")
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
            and not isHeader and (name == "Herbalism" or name == "Skinning")
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

local function herbTitleWithoutRequirement(shownTooltip, levels)
    if shownTooltip ~= tooltip or not levels.Herbalism then return end
    local title = _G.GameTooltipTextLeft1
    if not title or not usable(title:GetText()) then return end
    local previous = editedLines[title]
    local text = title:GetText()
    local original = previous and text == previous.edited and previous.original or text
    if not herbNodes[original] then return end
    -- The herb item has the same title as its world node. Never add a
    -- gathering overlay to bag, merchant or auction item tooltips.
    if type(shownTooltip.GetItem) ~= "function" then return end
    local ok, _, link = pcall(shownTooltip.GetItem, shownTooltip)
    if not ok or (link ~= nil and (not usable(link) or link)) then return end
    for index = 2, shownTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. index]
        local lineText = line and line:GetText()
        if usable(lineText) and lineText:find("Herbalism", 1, true) then return end
    end
    return title
end

local function updateTooltip(shownTooltip)
    shownTooltip = shownTooltip or tooltip
    if not shownTooltip:IsShown() then return end
    local levels = professionLevels()
    local professionWidth = 0
    if shownTooltip == tooltip then
        local herbTitle = herbTitleWithoutRequirement(shownTooltip, levels)
        for index = 2, tooltip:NumLines() do
            professionWidth = math.max(professionWidth,
                updateLine(_G["GameTooltipTextLeft" .. index], levels) or 0)
        end
        if herbTitle then
            professionWidth = math.max(professionWidth,
                updateLine(herbTitle, levels, "Herbalism") or 0)
        end
    end
    for _, region in ipairs({ shownTooltip:GetRegions() }) do
        professionWidth = math.max(professionWidth, updateLine(region, levels) or 0)
    end
    if professionWidth > 0 and shownTooltip:GetWidth() < professionWidth + 24 then
        shownTooltip:SetWidth(professionWidth + 24)
    end
end

local function safeUpdate(shownTooltip)
    if blockedTooltip then return end
    local ok, err = pcall(updateTooltip, shownTooltip)
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
    blockedTooltip = false
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
    print("Profession Level Tooltip: Herbalism " .. tostring(levels.Herbalism or "not found")
        .. ", Skinning " .. tostring(levels.Skinning or "not found")
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
            local function onTooltip(shownTooltip)
                if shownTooltip == tooltip then
                    blockedTooltip = false
                    safeUpdate()
                end
            end
            if Enum.TooltipDataType.Object then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, onTooltip)
            end
            if Enum.TooltipDataType.Unit then
                TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onTooltip)
            end
        end
    else
        safeUpdate()
    end
end)
