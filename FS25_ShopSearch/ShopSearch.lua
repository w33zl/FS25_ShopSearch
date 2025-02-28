--[[
SHORT DESCRIPTION OF WHAT YOUR MOD DOES GOES HERE

Author:     w33zl
Version:    1.0.0
Modified:   2024-12-28

Changelog:

]]

ShopSearch = Mod:init()

ShopSearch:source("scripts/modLib/DevHelper.lua")

-- Event that is executed when your mod is loading (after the map has been loaded and before the game starts)
function ShopSearch:loadMap(filename)
    self.shopMenu = g_shopMenu
end



function ShopSearch:registerHotkeys()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local success, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.SEARCH_SHOP, self, self.mainKeyEvent, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)

    if success then
        Log:debug("Registered main key for XnhancedShopSorting")
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    -- else
    --     Log:debug("Failed to register main key for XnhancedShopSorting")
    --     Log:var("state", success)
    --     Log:var("actionId", actionEventId)
    end    
    
end

function ShopSearch:mainKeyEvent()
    Log:debug("ShopSearch.mainKeyEvent")
    if g_shopMenu.isOpen then
        Log:debug("Open search...")
        self:showDialog()
    end
end

function ShopSearch:doSearch(text)
    local executionTimer = DevHelper.measureStart("Search took %d ms.")
    local displayItems = self:filterStoreItems(text)
    self:displaySearchResults(displayItems, text)
    executionTimer:stop(true)
    Log:info("Searching for '%s' resulted in %d hits, search took %.2f ms.", text, #displayItems, executionTimer.diff * 1000)
end

function ShopSearch:filterStoreItems(text)
    local MAX_ITEMS = 5000
    local displayItems = {}

    local function convertTextToPattern(text)
        text = string.trim(text or "")
        local pattern = ""
        -- for each character in x, add it to pattern with both lower and upper case as [aA]
        for i = 1, #text do
            pattern = pattern .. "[" .. string.upper(text:sub(i, i)) .. string.lower(text:sub(i, i)) .. "]"
        end
        return pattern
        
    end
    local searchText = convertTextToPattern(text)

    local function getAuthorName(storeItem)
        if not storeItem.isMod or not storeItem.customEnvironment then
            -- Log:debug("Not a mod: %s", storeItem.name)
            return ""
        end
        local customEnvironment = storeItem.customEnvironment
        local mod = g_modManager.nameToMod[customEnvironment]
        return mod.author or ""
    end

    local function tryMatch(storeItem, value, weight)
        if type(value) == "function" then
            local valueDelegate = value
            value = valueDelegate(storeItem)
        end
        local isMatch = string.find(value, searchText) ~= nil
        if isMatch then
            -- Log:debug("Match: '%s' using value '%s' with pattern '%s'", storeItem.name, value, searchText)
            storeItem.matchWeight = (storeItem.matchWeight or 0) + weight
        end
        return isMatch
    end

    local function filterStoreItem(i, storeItem)
        
        if #displayItems >= MAX_ITEMS then
            print("skip")
            return true
        end

        local isHidden = storeItem.isBundleItem or not (storeItem.showInStore and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL))

        if isHidden then
            -- print("Was hidden")
            return
        end

        local isMatch = false
        isMatch = isMatch or tryMatch(storeItem, storeItem.name, 1.2)
        isMatch = isMatch or tryMatch(storeItem, storeItem.dlcTitle, 0.9)
        isMatch = isMatch or tryMatch(storeItem, storeItem.brandNameRaw, 0.7) --TODO: can we improve performance by using brand index and pre-fetch the index?
        isMatch = isMatch or tryMatch(storeItem, getAuthorName(storeItem), 0.9)
        if isMatch then
            local displayItem = g_shopController:makeDisplayItem(storeItem)
            table.insert(displayItems, displayItem)
        end
    end

    -- local executionTimer = DevHelper.measureStart("Search took %d ms")
    table.foreach(g_storeManager:getItems(), filterStoreItem)
    -- executionTimer:stop()

    return displayItems
end

function ShopSearch:displaySearchResults(items, text)
    local shopMenu = self.shopMenu
    shopMenu.currentCategoryName = "misc"
    shopMenu.currentDisplayItems = items
    shopMenu.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    shopMenu.pageShopItemDetails:setDisplayItems(items)
    shopMenu:updateSubPageSelector()
    
    -- Display text should be max 20 characters from 'text'
    local displayText = string.sub(text, 1, 40)
    local headerText = g_i18n:getText("searchResultsHeader") .. ": " .. displayText

    shopMenu.pageShopItemDetails:setCategory("SEARCH", headerText, ShopMenu.SLICE_ID.VEHICLES)
    shopMenu:pushDetail(shopMenu.pageShopItemDetails)
    shopMenu:updateSubPageSelector()
end

function ShopSearch:showDialog()

    local dialogTitle = g_i18n:getText("dialogTitle") or g_modManager.nameToMod[g_currentModName].title

    TextInputDialog.createFromExistingGui({
        onTextEntered = function(text, clickOk) -- target, text, clickOk, args
            -- Log:table("onTextEntered", {
            --     self = self,
            --     text = text,
            --     clickOk = clickOk,
            --     args = args,
            -- }, 2)

            --TODO: add check for min text lengfht
            if clickOk then
                Log:debug("Search for %s", text)
                self:doSearch(text)
            else
                Log:debug("Cancelled")
            end
        end,
        target = nil,
        defaultText = "", -- "Default text",
        dialogPrompt = dialogTitle,
        imePrompt = "",
        maxCharacters = 40,
        confirmText = g_i18n:getText("searchButton"),
        -- callbackArgs = {  },
        inputText = "",
        applyTextFilter = false --BUG: Doesn't work, maybe Giants forgot something?
    })

    -- TextInputDialog.INSTANCE.applyTextFilter = false --HACK: trying to force this, nothing seems to work
    -- TextInputDialog.INSTANCE.textElement.applyTextFilter = false
    if TextInputDialog.INSTANCE.textElement then
        TextInputDialog.INSTANCE.textElement.applyProfanityFilter = false --HACK: forcing this, 'applyTextFilter' doesn't seem to work
    end

    
end

function ShopSearch:getItemsByCategory(shopController, superFunc, ...)
    Log:debug("ShopController.getItemsByCategory")

    local items = superFunc(shopController, ...)

    return items
end


-- function ShopSearch:updateDisplayItems()
--     Log:debug("ShopSearch.updateDisplayItems")
--     -- g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
-- end

-- ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
--     -- Log:debug("ShopItemsFrame.setDisplayItems")
--     if items and #items > 0 then 
        
--     end
--     return superFunc(self, items, ...)
-- end)

TabbedMenuWithDetails.onOpen = Utils.overwrittenFunction(TabbedMenuWithDetails.onOpen, function(self, superFunc, ...)
    local returnValue superFunc(self, ...)
    -- Log:var("g_shopMenu.isOpen", g_shopMenu.isOpen)
    if g_shopMenu.isOpen then
        ShopSearch:registerHotkeys()
    end
    
    return returnValue
end)

