---@diagnostic disable: undefined-global
local DEBUG = false

-- Initialize addon namespace and create main frame
AutoReagentDeposit = {}
local frame = CreateFrame("Frame")

local CHAT_COLOR_R, CHAT_COLOR_G, CHAT_COLOR_B = 1, (170 / 255), (128 / 255)
local function chat_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, CHAT_COLOR_R, CHAT_COLOR_G, CHAT_COLOR_B)
end

-- Event handler that auto-deposits reagents into the reagent bank when the bank frame is opened
local function OnEvent(self, event, ...)
    if DEBUG then chat_print("AutoReagentDeposit: OnEvent Triggered was: " .. event) end
    
    if event == "BANKFRAME_OPENED" then
        if C_Bank and C_Bank.AutoDepositItemsIntoBank then
            if DEBUG then chat_print("AutoReagentDeposit: BANKFRAME opened, doing deposit") end
            C_Bank.AutoDepositItemsIntoBank(2) -- Warband https://warcraft.wiki.gg/wiki/API_C_Bank.AutoDepositItemsIntoBank
            C_Bank.AutoDepositItemsIntoBank(0) -- Bank https://warcraft.wiki.gg/wiki/API_C_Bank.AutoDepositItemsIntoBank
        else
            chat_print("AutoReagentDeposit: C_Bank API not available")
        end
    end
end

-- Initialize addon by registering ADDON_LOADED event, then switch to OnEvent handler and register BANKFRAME_OPENED event
frame:RegisterEvent("ADDON_LOADED")
if DEBUG then chat_print("AutoReagentDeposit loaded") end

frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "AutoReagentDeposit" then
        frame:UnregisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", OnEvent)
        if DEBUG then chat_print("AutoReagentDeposit: onEvent registered") end
        frame:RegisterEvent("BANKFRAME_OPENED")
        if DEBUG then chat_print("AutoReagentDeposit: event BANKFRAME_OPENED registered") end
    end
end)
