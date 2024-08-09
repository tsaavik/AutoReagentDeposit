--
--  Reagent Banker
--    by Tuhljin 2020
--    Renamed and Hacked back to life by Tsaavik gnoballs@greymane 2024
--
-- You can change CHATLOG to true if you would like a log of all deposits in your chat
local CHATLOG = false
local DEBUG = false

AutoReagentDeposit = {}

local frame = CreateFrame("Frame")
AutoReagentDeposit.Frame = frame
frame:Hide()

local seenBank
local prevContents, awaitingChanges

local REAGENTBANK_ID = ReagentBankFrame:GetID()
local DepositButton = ReagentBankFrame.DespositButton -- Blizzard typo

local LIMIT_LINKS_PER_LINE = 10  --3 --15


--local R, G, B = 1, 0.6, 0.4
local R, G, B = 1, (170 / 255), (128 / 255)

local function chatprint(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, R, G, B);
end

local function doesBagSort(id)
	-- See ContainerFrameFilterDropDown_Initialize in FrameXML\ContainerFrame.lua
	if (id == -1) then
		return not GetBankAutosortDisabled()
	elseif (id == 0) then
		return not GetBackpackAutosortDisabled()
	elseif (id > NUM_BAG_SLOTS) then
		return not GetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP)
	else
		return not GetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP)
	end
end

local function setBagSort(id, value)
	-- See ContainerFrameFilterDropDown_Initialize in FrameXML\ContainerFrame.lua
	if (id == -1) then
		SetBankAutosortDisabled(not value)
	elseif (id == 0) then
		SetBackpackAutosortDisabled(not value)
	elseif (id > NUM_BAG_SLOTS) then
		SetBankBagSlotFlag(id - NUM_BAG_SLOTS, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, not value)
	else
		SetBagSlotFlag(id, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, not value)
	end
end

local function makeBagsSort()
	local changed
	for id=0,NUM_BAG_SLOTS do
		if (not doesBagSort(id)) then
			setBagSort(id, true)
			if (not changed) then  changed = {};  end
			changed[#changed+1] = id
		end
	end
	return changed
end


local function getReagentBankContents()
	if (DEBUG) then  chatprint("getReagentBankContents");  end
	local tab = {}
	local _, count, itemID
	local GetContainerItemInfo = C_Container and _G.C_Container.GetContainerItemInfo or _G.GetContainerItemInfo
	for slot=1,ReagentBankFrame.size do
		--texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemID
		_, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(REAGENTBANK_ID, slot)
		if (itemID) then
			--print("GetContainerItemInfo(",REAGENTBANK_ID,",", slot,") => ",count,itemID)
			tab[itemID] = (tab[itemID] or 0) + count
		end
	end
	if (DEBUG) then
	  local c = 0
	  for id,count in pairs(tab) do  c = c + 1;  end
	  chatprint("- Found " .. c .. " item IDs")
	end
	return tab
end
AutoReagentDeposit.GetReagentBankContents = getReagentBankContents


local preDeposit, postDeposit
do
	local changedSortFlag

	function preDeposit(includeSortIgnored)
		local GetContainerItemInfo = C_Container and _G.C_Container.GetContainerItemInfo or _G.GetContainerItemInfo
		if (DEBUG) then  chatprint("preDeposit");  end
		changedSortFlag = includeSortIgnored and makeBagsSort() or nil
		if (CHATLOG) then
			prevContents = getReagentBankContents()
			awaitingChanges = true
		else
			prevContents = nil
			awaitingChanges = false
		end
	end

	function postDeposit()
		if (DEBUG) then  chatprint("postDeposit");  end
		if (changedSortFlag) then
			for i,id in ipairs(changedSortFlag) do
				setBagSort(id, false)
			end
			changedSortFlag = nil
		end
	end
end

local function depositReaction()
	if (DEBUG) then  chatprint("depositReaction");  end
	local newContents = getReagentBankContents()
	local numAdded = 0 -- numAdded is the number of item IDs that saw an addition of any size
	local added = {}
	for id,count in pairs(newContents) do
		local prev = prevContents[id] or 0
		if (count > prev) then
			if (not added) then  added = {};  end
			added[id] = count - prev
			numAdded = numAdded + 1
		end
	end
	prevContents = nil

	if (numAdded > 0) then
		local numLines, numLeft = 0, numAdded
		local links = {}
		for id,diff in pairs(added) do
			local _, link = GetItemInfo(id)
			links[#links + 1] = diff == 1 and link or L.CHATLOG_DEPOSITED_COUNT:format(link, diff)
			numLeft = numLeft - 1
			if (#links == LIMIT_LINKS_PER_LINE) then
				local s = table.concat(links, L.CHATLOG_DEPOSITED_SEP .. ' ')
				if (numLeft > 0) then  s = s .. L.CHATLOG_DEPOSITED_SEP;  end
				links = {}
				numLines = numLines + 1
				chatprint(numLines == 1 and L.CHATLOG_DEPOSITED:format(s) or "   " .. s)
			end
		end
		if (#links > 0) then
			local s = table.concat(links, L.CHATLOG_DEPOSITED_SEP .. ' ')
			numLines = numLines + 1
			chatprint(numLines == 1 and L.CHATLOG_DEPOSITED:format(s) or "   " .. s)
		end
	end
end


local function OnEvent(self, event, ...)
	if (DEBUG) then  chatprint("AutoReagentDeposit: OnEvent Triggered was:");  end
	if (DEBUG) then  chatprint(event);  end
	if (event == "BANKFRAME_OPENED") then
		if (DEBUG) then  chatprint("Event: BANKFRAME_OPENED");  end
		if (not IsReagentBankUnlocked()) then  return;  end
		if (not seenBank) then
			-- If we haven't been to the bank before this session, we need elements of the reagent tab to load in order to prevent an error in
			-- function BankFrameItemButton_Update that happens when we try to make a deposit at this time.
			ReagentBankFrame_OnShow(ReagentBankFrame)
			seenBank = true
		end

		if (deposit) then
			C_Timer.After(0, function() -- This delay may prevent the intermittent problem where items already in the reagent bank appear to be newly deposited because getReagentBankContents() somehow failed to find any items when called by preDeposit().
				preDeposit()
				DepositReagentBank()
				postDeposit()
			end)
		end


	elseif (event == "PLAYERREAGENTBANKSLOTS_CHANGED") then
		if (DEBUG) then  chatprint(event);  end
		if (awaitingChanges) then
			awaitingChanges = false
			-- Consolidate all PLAYERREAGENTBANKSLOTS_CHANGED events into one reaction:
			C_Timer.After(0, depositReaction) -- 0 seconds because we should receive all the events at once so the function ought to be triggered after all of them are in
		end

	-- REAGENTBANK_UPDATE ?

	end
end

frame:RegisterEvent("ADDON_LOADED")
if (DEBUG) then  chatprint("AutoReagentDeposit loaded");  end
frame:SetScript("OnEvent", function(self, event, arg1)
	if (arg1 == "AutoReagentDeposit") then
		frame:UnregisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", OnEvent)
		if (DEBUG) then  chatprint("AutoReagentDeposit: onEvent registered");  end
		frame:RegisterEvent("BANKFRAME_OPENED")
		if (DEBUG) then  chatprint("AutoReagentDeposit: event BANKFRAME_OPENED registered");  end
	end
end)


local DepositButton_click_old = DepositButton:GetScript("OnClick")
DepositButton:SetScript("OnClick", function(...)
	if (DEBUG) then  chatprint("Deposit Button clicked");  end
	preDeposit()
	DepositButton_click_old(...)
	postDeposit()
end)