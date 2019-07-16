NugStats = CreateFrame("Frame", "NugStats", UIParent)
local NugStats = NugStats

NugStats:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

NugStats:RegisterEvent("PLAYER_LOGIN")
NugStats:RegisterEvent("PLAYER_LOGOUT")

local isClassic = select(4,GetBuildInfo()) <= 19999

local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL
local MAX_LINES = 8
local lines = {}

local function SetupDefaults(t, defaults)
    if not defaults then return end
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            elseif t[k] == false then
                t[k] = false --pass
            else
                SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end
local function RemoveDefaults(t, defaults)
    if not defaults then return end
    for k, v in pairs(defaults) do
        if type(t[k]) == 'table' and type(v) == 'table' then
            RemoveDefaults(t[k], v)
            if next(t[k]) == nil then
                t[k] = nil
            end
        elseif t[k] == v then
            t[k] = nil
        end
    end
    return t
end

local defaults = {
    anchor = {
        point = "CENTER",
        parent = "UIParent",
        to = "CENTER",
        x = -50,
        y = -137,
    },
    width = 200,
    height = 20,
    align = "LEFT",
    font = "Interface\\Addons\\NugStats\\ABF.ttf",
    fontSize = 14,
    linesConfig = {
        money = {
            order = 1,
            servers = {
            },
        },
        perfomance = {
            order = 2,
        },
        clock = {
            order = 3,
            format = "%H:%M:%S - %a%d",
        },
        azerite = {
            order = 4,
        },
        exp = {
            order = 5,
        },
        honor = {
            order = 6,
        },
    }
}

function NugStats.PLAYER_LOGIN(self,event,arg1)
    _G.NugStatsDB = _G.NugStatsDB or {}
    NugStatsDB = _G.NugStatsDB
    SetupDefaults(NugStatsDB, defaults)


    NugStats.anchor = NugStats:CreateAnchor(NugStatsDB.anchor)



    for i=1,MAX_LINES do
        lines[i] = NugStats:CreateLine(NugStatsDB.width, NugStatsDB.height)
    end

    for k,v in pairs(NugStatsDB.linesConfig) do
        -- if k == "exp" and UnitLevel("player") == 110 then
        -- else
            NugStats[k] = lines[v.order].text
        -- end
    end
    NugStats:ArrangeLines()

    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
    self:RegisterEvent("SEND_MAIL_COD_CHANGED")
    self:RegisterEvent("PLAYER_TRADE_MONEY")
    self:RegisterEvent("TRADE_MONEY_CHANGED")

    NugStats.SEND_MAIL_MONEY_CHANGED = NugStats.PLAYER_MONEY
    NugStats.SEND_MAIL_COD_CHANGED = NugStats.PLAYER_MONEY
    NugStats.PLAYER_TRADE_MONEY = NugStats.PLAYER_MONEY
    NugStats.TRADE_MONEY_CHANGED = NugStats.PLAYER_MONEY

    -- if self.exp then
    self:RegisterEvent("PLAYER_XP_UPDATE")
    if not isClassic then
        self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
    end
    -- end

    NugStats:SetScript("OnUpdate",function(self, arg1)
        self.OnUpdateCounter = (self.OnUpdateCounter or 0) + arg1
        if self.OnUpdateCounter > 0.5 then
            NugStats:UpdateClock()
            NugStats:UpdatePerfomance()
            self.OnUpdateCounter = 0
        end
    end)

    SLASH_NUGSTATS1= "/nugstats"
    SLASH_NUGSTATS2= "/nstats"
    SlashCmdList["NUGSTATS"] = NugStats.SlashCmd

end

function NugStats:PLAYER_LOGOUT()
    RemoveDefaults(NugStatsDB, defaults)
end

local COLOR_COPPER = "eda55f"
local COLOR_SILVER = "c7c7cf"
local COLOR_GOLD = "ffd700"
local _colored_g = string.format("|cff%sg|r ",COLOR_GOLD)
local _colored_s = string.format("|cff%ss|r ",COLOR_SILVER)
local _colored_c = string.format("|cff%sc|r ",COLOR_COPPER)
function NugStats.PLAYER_MONEY(self)
    local playerName, playerRealm, playerMoney = UnitName("player"), GetRealmName(), GetMoney()
    NugStatsDB.linesConfig.money.servers[playerRealm] = NugStatsDB.linesConfig.money.servers[playerRealm] or {}
    NugStatsDB.linesConfig.money.servers[playerRealm][playerName] = playerMoney

    local globalMoney = 0
    for name,money in pairs(NugStatsDB.linesConfig.money.servers[playerRealm]) do
        globalMoney = globalMoney + money
    end

    local gold = floor(playerMoney / 10000)
	local silver = mod(floor(playerMoney / 100), 100)
	local copper = mod(floor(playerMoney), 100)
    local playerMoneyText = string.format("%d%s %d%s %d%s", gold,_colored_g,silver,_colored_s,copper,_colored_c)
    local globalMoneyText = floor(globalMoney / 10000).._colored_g

    self.money:SetText(string.format("%s - %s",playerMoneyText,globalMoneyText))
end

function NugStats:UpdateClock()
    self.clock:SetText(date(NugStatsDB.linesConfig.clock.format))
end

-- function NugStats:HONOR_CURRENCY_UPDATE()
--     hk, hrp = GetPVPSessionStats();
--     -- self.honor.honorString = (hrp == 0 and "") or string.format("%s hr",hrp)
--     self.honor:SetText((hrp == 0 and "") or string.format("%s hr",hrp))
-- end

local azerite_color = ARTIFACT_BAR_COLOR:GenerateHexColor()
function NugStats:AZERITE_ITEM_EXPERIENCE_CHANGED()
    if not self.azerite then return end

    -- print('update')

    local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
	if (not azeriteItemLocation) then
		return;
	end
    local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation);

	local xp, max = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
	local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation);
    local toGo = max - xp
    local percentToGo = math.floor(toGo / max * 100)

    local str = string.format("|c%sAP:|r %d (%d%%)", azerite_color, toGo, percentToGo)
    self.azerite:SetText(str)
end


local xp_color = CreateColor(0.7, 0.7, 1):GenerateHexColor()
function NugStats:PLAYER_XP_UPDATE()
    if not self.exp then return end
    local max, xp = UnitXPMax("player"), UnitXP("player")
    local toGo = max - xp
    local percentToGo = math.floor(toGo / max * 100)

    local expstr = string.format("|c%sXP:|r %d (%d%%)", xp_color, toGo, percentToGo)
    local rested = GetXPExhaustion()
    if rested then
        local restedPercent = math.floor((rested / max) * 100)
        expstr = expstr .. string.format(" [+%d%%]",restedPercent)
    end

    self.exp:SetText(expstr)
end

function NugStats:UpdatePerfomance()
    local framerate = floor(GetFramerate() + 0.5)
	local fps = string.format("|cff%s%d|r fps", self:GetThresholdHexColor(framerate / 60), framerate)
    local latency = select(3, GetNetStats())
    local lag = string.format("|cff%s%d|r ms", self:GetThresholdHexColor(latency, 1000, 500, 250, 100, 0), latency)

    self.perfomance:SetText(fps.." "..lag)
end


function NugStats:PLAYER_ENTERING_WORLD()
    self:UpdatePerfomance()
    self:UpdateClock()
    self:PLAYER_MONEY()

    if UnitLevel("player") < MAX_PLAYER_LEVEL  then self:PLAYER_XP_UPDATE() end
    if not isClassic then self:AZERITE_ITEM_EXPERIENCE_CHANGED() end
end

function NugStats:CreateAnchor(db_tbl)
    local f = CreateFrame("Frame", "NugStatsAnchor",UIParent)
    f:SetHeight(20)
    f:SetWidth(20)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:Hide()

    local t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0,0.25,0,1)
    t:SetAllPoints(f)

    t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0.25,0.49,0,1)
    t:SetVertexColor(1, 0, 0)
    t:SetAllPoints(f)

    f.db_tbl = db_tbl

    f:SetScript("OnMouseDown",function(self)
        self:StartMoving()
    end)
    f:SetScript("OnMouseUp",function(self)
            local opts = self.db_tbl
            self:StopMovingOrSizing();
            local point,_,to,x,y = self:GetPoint(1)
            opts.point = point
            opts.parent = "UIParent"
            opts.to = to
            opts.x = x
            opts.y = y
    end)

    local pos = f.db_tbl
    f:SetPoint(pos.point, pos.parent, pos.to, pos.x, pos.y)
    return f
end

function NugStats.CreateLine(self, width, height)
    local f = CreateFrame("Frame",nil,self)
    -- f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(3)
    f:SetWidth(width)
    f:SetHeight(height)
    f.text = f:CreateFontString(nil, "OVERLAY");
    f.text:SetFont(NugStatsDB.font,NugStatsDB.fontSize)
    f.text:SetAllPoints(f)
    f.text:SetJustifyH(NugStatsDB.align)
--~     f.text:SetTextColor(0.3,1,0.3,1)

    -- f.text.SetOnEnter = function( self, func )
    --     self:GetParent():SetScript("OnEnter",func)
    -- end
    -- f.text.SetOnLeave = function( self, func )
    --     self:GetParent():SetScript("OnLeave",func)
    -- end
--~     f:Show()
    return f
end

function NugStats.ArrangeLines(self)
    local prev
    for i=1,MAX_LINES do
        lines[i]:SetPoint("TOPLEFT",prev or self.anchor,( prev and "BOTTOMLEFT" ) or "BOTTOMRIGHT", 0,2)
        prev = lines[i]
    end
end


function NugStats.SlashCmd(msg)
    local k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then print([[Usage:
        |cff00ff00/nugstats|r menu
        |cff00ff00/nugstats|r lock
        |cff00ff00/nugstats|r unlock
        |cff00ff00/nugstats|r listcharmoney
        |cff00ff00/nugstats|r delcharmoney <Name>
        |cff00ff00/nugstats|r set width=100 height=20 align=[left|center|right] font=Interface\Addons\NugStats\Fonts\ABF.ttf fontsize=16 ]]
    )end
    if NugStats.Commands[k] then
        NugStats.Commands[k](v)
    end
end



local ParseOpts = function(str)
    local t = {}
    local capture = function(k,v)
        t[k:lower()] = tonumber(v) or v
        return ""
    end
    str:gsub("(%w+)%s*=%s*%[%[(.-)%]%]", capture):gsub("(%w+)%s*=%s*(%S+)", capture)
    return t
end
NugStats.Commands = {
    ["unlock"] = function()
        NugStats.anchor:Show()
    end,
    ["lock"] = function()
        NugStats.anchor:Hide()
    end,
    ["listcharmoney"] = function()
        print("Characters money cache:")
        for k,v in pairs(NugStatsDB.linesConfig.money.chars) do
            print ("   "..k.." = "..v)
        end
    end,
    ["delcharmoney"] = function()
        NugStatsDB.linesConfig.money.chars[v] = nil
    end,
    ["set"] = function()
        local p = NugStats.ParseOpts(v)
        if p["width"] then NugStatsDB.width = p["width"].s end
        if p["height"] then NugStatsDB.height = p["height"].s end
        if p["font"] then NugStatsDB.font = p["font"].s end
        if p["fontsize"] then NugStatsDB.fontSize = p["fontsize"].s end
        if p["align"] then NugStatsDB.align = string.upper(p["align"].s) end
        for i=1,MAX_LINES do
            local f = lines[i]
            f:SetWidth(NugStatsDB.width)
            f:SetHeight(NugStatsDB.height)
            f.text:SetFont(NugStatsDB.font,NugStatsDB.fontSize)
            f.text:SetJustifyH(NugStatsDB.align)
        end
    end
}



function NugStats.Currency()
    for i=1,GetCurrencyListSize() do
        local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon = GetCurrencyListInfo(i)
        if not isHeader then
            print(name.." "..count)
        end
    end
end



-- function from LibCrayon

local function GetThresholdPercentage(quality, ...)
	local n = select('#', ...)
	if n <= 1 then
		return GetThresholdPercentage(quality, 0, ... or 1)
	end

	local worst = ...
	local best = select(n, ...)

	if worst == best and quality == worst then
		return 0.5
	end

	if worst <= best then
		if quality <= worst then
			return 0
		elseif quality >= best then
			return 1
		end
		local last = worst
		for i = 2, n-1 do
			local value = select(i, ...)
			if quality <= value then
				return ((i-2) + (quality - last) / (value - last)) / (n-1)
			end
			last = value
		end

		local value = select(n, ...)
		return ((n-2) + (quality - last) / (value - last)) / (n-1)
	else
		if quality >= worst then
			return 0
		elseif quality <= best then
			return 1
		end
		local last = worst
		for i = 2, n-1 do
			local value = select(i, ...)
			if quality >= value then
				return ((i-2) + (quality - last) / (value - last)) / (n-1)
			end
			last = value
		end

		local value = select(n, ...)
		return ((n-2) + (quality - last) / (value - last)) / (n-1)
	end
end

function NugStats:GetThresholdColor(quality, ...)
	if quality ~= quality then
		return 1, 1, 1
	end

	local percent = GetThresholdPercentage(quality, ...)

	if percent <= 0 then
		return 1, 0, 0
	elseif percent <= 0.5 then
		return 1, percent*2, 0
	elseif percent >= 1 then
		return 0, 1, 0
	else
		return 2 - percent*2, 1, 0
	end
end

function NugStats:GetThresholdHexColor(quality, ...)
	local r, g, b = self:GetThresholdColor(quality, ...)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end