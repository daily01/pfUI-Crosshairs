local addonPath = "Interface\\AddOns\\pfUI-Crosshairs"
local ROT_SPEED, PULSE_SPEED, PULSE_RANGE = 0.8, 4.5, 0.08
local BASE_SIZE = 50      -- 基础尺寸
local LINE_THICKNESS, LINE_LENGTH, LINE_ALPHA, GAP_FACTOR = 1.2, 5000, 0.3, 0.9
local MAX_ALPHA, MIN_ALPHA, SCALE_BASE = 1.0, 0.6, 1.2
local SQRT2 = 1.41421356

local function Get2DRotation(angle)
    local c, s = math.cos(angle)*SQRT2, math.sin(angle)*SQRT2
    return 0.5-0.5*c-0.5*s, 0.5-0.5*s+0.5*c, 0.5-0.5*c+0.5*s, 0.5-0.5*s-0.5*c, 0.5+0.5*c-0.5*s, 0.5+0.5*s+0.5*c, 0.5+0.5*c+0.5*s, 0.5+0.5*s-0.5*c
end

local function EnsureCrosshair(plate)
    if not plate or plate.crosshair then return plate.crosshair end
    local ch = CreateFrame("Frame", nil, plate)
    ch:SetPoint("CENTER", plate.health or plate, "CENTER", 0, 0)
    ch:SetWidth(600); ch:SetHeight(600); ch:SetFrameLevel(10); ch:EnableMouse(false)
    
    local lines = {"lineTop", "lineBottom", "lineLeft", "lineRight"}
    for _, n in ipairs(lines) do
        ch[n] = ch:CreateTexture(nil, "BACKGROUND")
        ch[n]:SetTexture(1, 1, 1)
    end
    ch.lineTop:SetWidth(LINE_THICKNESS); ch.lineTop:SetHeight(LINE_LENGTH)
    ch.lineBottom:SetWidth(LINE_THICKNESS); ch.lineBottom:SetHeight(LINE_LENGTH)
    ch.lineLeft:SetWidth(LINE_LENGTH); ch.lineLeft:SetHeight(LINE_THICKNESS)
    ch.lineRight:SetWidth(LINE_LENGTH); ch.lineRight:SetHeight(LINE_THICKNESS)

    ch.circle = ch:CreateTexture(nil, "OVERLAY")
    ch.circle:SetTexture(addonPath.."\\img\\circle")
    ch.circle:SetPoint("CENTER", ch, "CENTER", 0, 0)
    ch.arrows = ch:CreateTexture(nil, "OVERLAY")
    ch.arrows:SetTexture(addonPath.."\\img\\arrows")
    ch.arrows:SetPoint("CENTER", ch, "CENTER", 0, 0)
    
    ch:Hide(); plate.crosshair = ch
    return ch
end

local function HookNameplates()
    if not pfUI or not pfUI.nameplates or pfUI.nameplates.CrosshairHooked then return pfUI and pfUI.nameplates and pfUI.nameplates.CrosshairHooked end
    local target = pfUI.nameplates
    local rawOnData = target.OnDataChanged
    target.OnDataChanged = function(self, plate)
        if rawOnData then rawOnData(self, plate) end
        local ch = EnsureCrosshair(plate)
        if ch then
            if plate.istarget and UnitExists("target") then
                ch:Show(); local r, g, b = 1, 0.9, 0
                ch.circle:SetVertexColor(r, g, b); ch.arrows:SetVertexColor(r, g, b)
                ch.lineTop:SetVertexColor(r, g, b, LINE_ALPHA); ch.lineBottom:SetVertexColor(r, g, b, LINE_ALPHA)
                ch.lineLeft:SetVertexColor(r, g, b, LINE_ALPHA); ch.lineRight:SetVertexColor(r, g, b, LINE_ALPHA)
            else ch:Hide() end
        end
    end

    local rawOnUpdate = target.OnUpdate
    target.OnUpdate = function()
        if rawOnUpdate then rawOnUpdate() end
        local plate = this.nameplate
        if plate and plate.istarget and plate.crosshair and plate.crosshair:IsShown() then
            local ch, t = plate.crosshair, GetTime()
            local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = Get2DRotation(t * ROT_SPEED)
            ch.circle:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
            ch.arrows:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)

            local visualSize = BASE_SIZE * (SCALE_BASE + (math.sin(t * PULSE_SPEED) * PULSE_RANGE))
            local renderSize = visualSize * SQRT2
            ch.circle:SetWidth(renderSize); ch.circle:SetHeight(renderSize)
            ch.arrows:SetWidth(renderSize); ch.arrows:SetHeight(renderSize)

            local gap = (visualSize / 2) * GAP_FACTOR
            ch.lineTop:SetPoint("BOTTOM", ch, "CENTER", 0, gap)
            ch.lineBottom:SetPoint("TOP", ch, "CENTER", 0, -gap)
            ch.lineLeft:SetPoint("RIGHT", ch, "CENTER", -gap, 0)
            ch.lineRight:SetPoint("LEFT", ch, "CENTER", gap, 0)

            local alpha = MAX_ALPHA - (((math.sin(t * PULSE_SPEED) + 1) / 2) * (MAX_ALPHA - MIN_ALPHA))
            ch.circle:SetAlpha(alpha * 0.6); ch.arrows:SetAlpha(alpha)
        end
    end
    target.CrosshairHooked = true
    return true
end

local loader = CreateFrame("Frame")
loader:SetScript("OnUpdate", function() if HookNameplates() then this:Hide() end end)