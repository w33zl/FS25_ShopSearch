--[[
SHORT DESCRIPTION OF WHAT YOUR MOD DOES GOES HERE

Author:     w33zl
Version:    1.0.0
Modified:   2024-12-28

Changelog:

]]

ShopSearch = Mod:init()

ShopSearch:source("lib/DevHelper.lua")

-- Event that is executed when your mod is loading (after the map has been loaded and before the game starts)
function ShopSearch:loadMap(filename)
    self.shopMenu = g_shopMenu
end

-- Event that is continuously, USE WITH CAUTION! Any demanding code here (even just a simple "print()" command) will cause poor performance, stuttering and FPS drops
function ShopSearch:update(dt)
end

-- Event that is executed when the player chooses to start the mission (after the map has been loaded and before the game starts)
function ShopSearch:startMission()
end

-- ShopController.getItemsByCategory = Utils.overwrittenFunction(ShopController.getItemsByCategory, function(self, superFunc, ...)
--     return XnhancedShopSorting:getItemsByCategory(self, superFunc, ...)
-- end)


-- ShopMenu.onOpen = Utils.overwrittenFunction(ShopMenu.onOpen, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onOpen")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClose = Utils.overwrittenFunction(ShopMenu.onClose, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClose")
--     return superFunc(self, ...)
-- end)

-- -- ShopMenu.onClickMenu = Utils.overwrittenFunction

-- ShopMenu.exitMenu = Utils.overwrittenFunction(ShopMenu.exitMenu, function(self, superFunc, ...)
--     Log:debug("ShopMenu.exitMenu")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClickItemCategory = Utils.overwrittenFunction(ShopMenu.onClickItemCategory, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClickItemCategory")
--     return superFunc(self, ...)
-- end)

function ShopSearch:registerHotkeys()
    -- Log:debug("XnhancedShopSorting.registerHotkeys")
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
    -- local v19 = p17:makeSelfCallback(p17.onClickItemCategory)
    -- p17.pageShopVehicles:initialize(g_storeManager:getCategoryTypes(), g_shopController:getShopCategories(), v19, v18, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), ShopMenu.SLICE_ID.VEHICLES, ShopMenu.LIST_CELL_NAME_CATEGORY, ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY)    
    
    -- local v142 = g_shopController:getVehicleCategories()[p140]
    -- p139:popDetail()
    -- p139:onClickItemCategory(v142.id, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), v142.label, ShopMenu.SLICE_ID.VEHICLES, p139.currentCategoryFilter)

    -- p171:changeScreen(ShopMenu)
	-- p171:goToPage(p171.pageShopVehicles)
	-- p171:onClickItemCategory(ShopController.COINS_CATEGORY, nil, g_i18n:getText("ui_coins"))

			-- p16:addCategoryForDisplay(g_storeManager:getCategoryByName(ShopController.COINS_CATEGORY))
    local displayItems = self:filterStoreItems(text)
    self:displaySearchResults(displayItems)
end

function ShopSearch:filterStoreItems(text)
    local MAX_ITEMS = 25
    -- local USE_SIMPLE_SEARCH = true --* NOTE: important! If this is disabled, the search will be case sensitive
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
            Log:debug("Not a mod: %s", storeItem.name)
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
            Log:debug("Match: '%s' using value '%s' with pattern '%s'", storeItem.name, value, searchText)
            storeItem.matchWeight = (storeItem.matchWeight or 0) + weight
        end
        return isMatch
    end

    local function filterStoreItem(i, storeItem)
        
        if #displayItems >= MAX_ITEMS then
            print("skip")
            return true
        end

        -- for _, storeItem in pairs(g_storeManager:getItems()) do
        local isHidden = storeItem.isBundleItem or not (storeItem.showInStore and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL))

        if isHidden then
            print("Was hidden")
            return
        end

        -- print("search")

        -- if storeItem.isMod then
        --     Log:debug("%d: Is mod item: %s [%d]", i, storeItem.name, storeItem.id)
        --     return
        -- end

        -- local isMod
        -- if storeItem.customEnvironment == nil then
        -- 	isMod = false
        -- else
        -- 	isMod = storeItem.species == StoreSpecies.VEHICLE
        -- end
        -- if not isHidden then
        --TODO: add match weights and calculate result sort score
        local isMatch = false
        isMatch = isMatch or tryMatch(storeItem, storeItem.name, 1.2)
        isMatch = isMatch or tryMatch(storeItem, storeItem.dlcTitle, 0.9)
        isMatch = isMatch or tryMatch(storeItem, storeItem.brandNameRaw, 0.7) --TODO: can we improve performance by using brand index and pre-fetch the index?
        isMatch = isMatch or tryMatch(storeItem, getAuthorName(storeItem), 0.9)
        if isMatch then
            local displayItem = g_shopController:makeDisplayItem(storeItem)
            table.insert(displayItems, displayItem)
            -- if #displayItems >= MAX_ITEMS then
            --     return
            -- end
        end
        -- end        
    end

    local executionTimer = DevHelper.measureStart("Search took %d ms")
    table.foreach(g_storeManager:getItems(), filterStoreItem)
    executionTimer:stop()

    return displayItems
end

function ShopSearch:displaySearchResults(items)
    local shopMenu = self.shopMenu
    -- local items = g_shopController:getItemsByCategory(categoryName)
    shopMenu.currentCategoryName = "misc"
    shopMenu.currentDisplayItems = items
    -- shopMenu.currentCategoryFilter = filter
    shopMenu.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    shopMenu.pageShopItemDetails:setDisplayItems(items)
    shopMenu:updateSubPageSelector()
    
    shopMenu.pageShopItemDetails:setCategory("DRIVABLES", "SEARCH RESULTS", ShopMenu.SLICE_ID.VEHICLES)
    shopMenu:pushDetail(shopMenu.pageShopItemDetails)
    shopMenu:updateSubPageSelector()
end

-- function ShopMenu.viewVehicle(self, vehicleFilename)
-- 	local vehicleFilename = vehicleFilename:gsub("\\", "/")
-- 	local basePath = getAppBasePath()
-- 	if vehicleFilename:startsWith(basePath) then
-- 		vehicleFilename = vehicleFilename:sub(basePath:len() + 1)
-- 	end
-- 	local storeItem = g_storeManager:getItemByXMLFilename(vehicleFilename)
-- 	if storeItem ~= nil then
-- 		g_gui:changeScreen(nil, ShopMenu)
-- 		local category = nil
-- 		for i = 1, #storeItem.categoryNames do
-- 			category = g_storeManager:getCategoryByName(storeItem.categoryNames[i])
-- 			if category ~= nil then
-- 				break
-- 			end
-- 		end
-- 		if category ~= nil then
-- 			self:onClickItemCategory(category.name, g_i18n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES), category.title, self.currentCategoryFilter)
-- 		end
-- 		g_shopMenu:showConfigurationScreen(storeItem, nil, nil)
-- 	end
-- end


function ShopSearch:showDialog()

    local dialogTitle = g_i18n:getText("dialogTitle") or g_modManager.nameToMod[g_currentModName].title

    TextInputDialog.createFromExistingGui({
        onTextEntered = function(text, clickOk) -- self, text, clickOk, args
            -- Log:table("onTextEntered", {
            --     self = self,
            --     text = text,
            --     clickOk = clickOk,
            --     args = args,
            -- }, 2)
            if clickOk then
                Log:debug("Search for %s", text)
                -- Log:debug("Click OK")
                -- Log:var("text", text)
                -- Log:var("args", args)
                -- Log:var("self", self)
                -- Log:var("clickOk", clickOk)
                self:doSearch(text)
            else
                Log:debug("Cancelled")
            end
        end,
        target = nil,
        defaultText = "", -- "Default text",
        dialogPrompt = "Search Store:",
        imePrompt = "",
        maxCharacters = 40,
        confirmText = "Search",
        -- callbackArgs = {  },
        inputText = "",
        applyTextFilter = false
    })

    
end

function ShopSearch:getItemsByCategory(shopController, superFunc, ...)
    Log:debug("ShopController.getItemsByCategory")

    local items = superFunc(shopController, ...)

    -- for i = 1, #items do
    --     Log:debug("#%d: %s [%d]: %d", i, items[i].storeItem.name, items[i].storeItem.id, items[i].orderValue)
    -- end

    return items
end


function ShopSearch:updateDisplayItems()
    Log:debug("ShopSearch.updateDisplayItems")
    -- g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
end

ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
    -- Log:debug("ShopItemsFrame.setDisplayItems")
    if items and #items > 0 then 
        
    end
    return superFunc(self, items, ...)
end)

TabbedMenuWithDetails.onOpen = Utils.overwrittenFunction(TabbedMenuWithDetails.onOpen, function(self, superFunc, ...)
    -- Log:debug("TabbedMenuWithDetails.onOpen")
    
    local returnValue superFunc(self, ...)
    -- Log:var("g_shopMenu.isOpen", g_shopMenu.isOpen)
    if g_shopMenu.isOpen then
        ShopSearch:registerHotkeys()
    end
    
    return returnValue
end)

-- TabbedMenuWithDetails.onDetailOpened = Utils.overwrittenFunction(TabbedMenuWithDetails.onDetailOpened, function(self, superFunc, ...)
--     Log:debug("TabbedMenuWithDetails.onDetailOpened")
--     return superFunc(self, ...)
-- end)