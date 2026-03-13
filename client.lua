local QBCore = exports['qb-core']:GetCoreObject()
local scoreboardOpen = false
local activities = {}
local playerCounts = {
    police = 0,
    ambulance = 0,
    mechanic = 0,
    bennys = 0,
    biker = 0,
    pizzathis = 0,
    cardealer = 0,
    beanmachine = 0,
    total = 0
}

-- Configuration
local config = {
    defaultTheme = "red",
    defaultScale = 100,
    activityRefresh = 3000,
    policeJobNames = {'police', 'sheriff', 'state'}
}

-- Activities Configuration with Level Requirements
local activityConfig = {
    activities = {
        {
            name = "chopchop",
            label = "Vehicle Dismantle",
            description = "Rob the jewelry store in the city",
            icon = "fas fa-car",
            minPolice = 3,
            minLevel = 1,
            requiredItem = nil,
            available = false,
            cooldown = 0
        },
        {
            name = "houserobbery",
            label = "House Robbery",
            description = "Break into and rob houses",
            icon = "fas fa-home",
            minPolice = 3,
            minLevel = 2,
            requiredItem = "advancedlockpick",
            available = false,
            cooldown = 0
        },
        {
            name = "storerobbery",
            label = "Store Robbery",
            description = "Rob a random store",
            icon = "fas fa-store",
            minPolice = 4,
            minLevel = 11,
            requiredItem = "crowbar",
            available = false,
            cooldown = 0
        },
        {
            name = "containerrobbery",
            label = "Container Robbery",
            description = "Rob a random container",
            icon = "fas fa-box",
            minPolice = 4,
            minLevel = 26,
            requiredItem = "crowbar",
            available = false,
            cooldown = 0
        },
        {
            name = "yachtrobbery",
            label = "Yacht Raid",
            description = "Raid a cartel's yacht",
            icon = "fas fa-ship",
            minPolice = 4,
            minLevel = 30,
            requiredItem = "weapon_bat",
            available = false,
            cooldown = 0
        },
        {
            name = "jewelrystore",
            label = "Jewelry Store",
            description = "Rob the jewelry store in the city",
            icon = "fas fa-gem",
            minPolice = 6,
            minLevel = 41,
            requiredItem = "crowbar",
            available = false,
            cooldown = 0
        },
        {
            name = "ammunationrobbery",
            label = "Ammunation Robbery",
            description = "Rob an Ammunation store for ammo",
            icon = "fas fa-gun",
            minPolice = 8,
            minLevel = 51,
            requiredItem = "trojan_usb",
            available = false,
            cooldown = 0
        },
        {
            name = "bankrobbery",
            label = "Fleeca Bank Robbery",
            description = "Rob a Fleeca Bank branch",
            icon = "fas fa-university",
            minPolice = 10,
            minLevel = 71,
            requiredItem = "trojan_usb",
            available = false,
            cooldown = 0
        },
        {
            name = "bobcatrobbery",
            label = "Bobcat Robbery",
            description = "Rob a Bobcat branch",
            icon = "fas fa-truck",
            minPolice = 10,
            minLevel = 86,
            requiredItem = "thermite",
            available = false,
            cooldown = 0
        },
        {
            name = "pacificrobbery",
            label = "Pacific Bank Robbery",
            description = "Rob the Pacific bank",
            icon = "fas fa-landmark",
            minPolice = 20,
            minLevel = 86,
            requiredItem = "thermite",
            available = false,
            cooldown = 0
        }
    }
}

-- Local variables
local currentTheme = config.defaultTheme
local currentScale = config.defaultScale
local playerLevel = 1
local playerItems = {}
local isDataLoading = false
local pendingOpen = false
local dataLoadTimeout = nil

-- Themes definition
local themes = {
    purple = {
        primary = "#6366f1",
        secondary = "#8b5cf6",
        accent = "#ec4899",
        bg = "#1a1a2e"
    },
    red = {
        primary = "#ef4444",
        secondary = "#dc2626",
        accent = "#f87171",
        bg = "#111827"
    },
    green = {
        primary = "#10b981",
        secondary = "#059669",
        accent = "#34d399",
        bg = "#0f1a15"
    },
    pink = {
        primary = "#ec4899",
        secondary = "#db2777",
        accent = "#f472b6",
        bg = "#1a0f15"
    },
    blue = {
        primary = "#3b82f6",
        secondary = "#2563eb",
        accent = "#60a5fa",
        bg = "#0f141a"
    },
    orange = {
        primary = "#f59e0b",
        secondary = "#d97706",
        accent = "#fbbf24",
        bg = "#1a150f"
    },
    cyan = {
        primary = "#06b6d4",
        secondary = "#0891b2",
        accent = "#22d3ee",
        bg = "#0f1a1a"
    },
    white = {
        primary = "#ffffff",
        secondary = "#f3f4f6",
        accent = "#e5e7eb",
        bg = "#111827"
    },
    black = {
        primary = "#374151",
        secondary = "#1f2937",
        accent = "#4b5563",
        bg = "#0a0a0a"
    },
    yellow = {
        primary = "#facc15",
        secondary = "#eab308",
        accent = "#fbbf24",
        bg = "#1a180f"
    }
}

-- Load player data with timeout
function LoadPlayerData(callback)
    if isDataLoading then
        if callback then callback(false) end
        return
    end
    
    isDataLoading = true
    
    -- Clear any existing timeout
    if dataLoadTimeout then
        dataLoadTimeout = nil
    end
    
    -- Set a timeout for data loading
    dataLoadTimeout = GetGameTimer() + 5000 -- 5 second timeout
    
    -- Get player level
    QBCore.Functions.TriggerCallback('qb-scoreboard:GetPlayerLevel', function(level)
        if not isDataLoading then return end -- Already timed out
        
        playerLevel = level or 1
        
        -- Get player items
        QBCore.Functions.TriggerCallback('qb-scoreboard:GetPlayerItems', function(items)
            if not isDataLoading then return end -- Already timed out
            
            playerItems = items or {}
            isDataLoading = false
            
            if callback then callback(true) end
        end)
    end)
end

-- Check if data loading has timed out
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isDataLoading and dataLoadTimeout and GetGameTimer() > dataLoadTimeout then
            print("^1[qb-SCOREBOARD] Warning: Player data loading timed out^7")
            isDataLoading = false
            dataLoadTimeout = nil
        end
    end
end)

-- Check if player has required item for activity
function HasRequiredItem(activity)
    if not activity.requiredItem then
        return true
    end
    
    -- Handle multiple required items (comma separated)
    if type(activity.requiredItem) == "string" and string.find(activity.requiredItem, ",") then
        local requiredItems = {}
        for item in string.gmatch(activity.requiredItem, '([^,]+)') do
            table.insert(requiredItems, item:gsub("^%s*(.-)%s*$", "%1")) -- Trim whitespace
        end
        
        -- Check if player has at least one of the required items
        for _, requiredItem in ipairs(requiredItems) do
            for _, item in ipairs(playerItems) do
                if item.name == requiredItem and item.amount and item.amount > 0 then
                    return true
                end
            end
        end
        return false
    end
    
    -- Single item check
    for _, item in ipairs(playerItems) do
        if item.name == activity.requiredItem and item.amount and item.amount > 0 then
            return true
        end
    end
    
    return false
end

-- Check if player meets level requirement
function MeetsLevelRequirement(activity)
    return playerLevel >= activity.minLevel
end

-- Format activities for NUI
function GetFormattedActivities()
    local formatted = {}
    
    for _, activity in ipairs(activityConfig.activities) do
        local hasPolice = playerCounts.police >= activity.minPolice
        local hasLevel = MeetsLevelRequirement(activity)
        local hasItem = HasRequiredItem(activity)
        local noCooldown = activity.cooldown <= GetGameTimer()
        
        local available = hasPolice and hasLevel and hasItem and noCooldown
        
        table.insert(formatted, {
            name = activity.name,
            label = activity.label,
            description = activity.description,
            icon = activity.icon,
            minPolice = activity.minPolice,
            minLevel = activity.minLevel,
            requiredItem = activity.requiredItem,
            available = available,
            policeCount = playerCounts.police,
            playerLevel = playerLevel,
            playerHasItem = hasItem,
            timeLeft = activity.cooldown > GetGameTimer() and math.floor((activity.cooldown - GetGameTimer()) / 1000) or 0,
            unmetRequirements = {
                police = not hasPolice,
                level = not hasLevel,
                item = not hasItem,
                cooldown = not noCooldown
            }
        })
    end
    
    return formatted
end

-- Load settings
function LoadSettings()
    local settings = GetResourceKvpString("vd_scoreboard_settings")
    if settings then
        settings = json.decode(settings)
        currentTheme = settings.theme or config.defaultTheme
        currentScale = settings.scale or config.defaultScale
    end
    
    SendNUIMessage({
        action = "loadSettings",
        theme = currentTheme,
        scale = currentScale
    })
end

-- Save settings
function SaveSettings()
    local settings = {
        theme = currentTheme,
        scale = currentScale
    }
    SetResourceKvp("vd_scoreboard_settings", json.encode(settings))
end

-- Main functions
function ToggleScoreboard()
    if scoreboardOpen then
        CloseScoreboard()
    else
        OpenScoreboard()
    end
end

function OpenScoreboard()
    if scoreboardOpen then return end
    
    -- Hide UI first to ensure clean state
    SendNUIMessage({
        action = "hideUI"
    })
    
    Citizen.Wait(50)
    
    -- Show loading state
    scoreboardOpen = true
    SetNuiFocus(true, true)
    
    -- Get updated counts from server
    QBCore.Functions.TriggerCallback('qb-scoreboard:GetAllCounts', function(counts)
        if not counts then
            print("^1[qb-SCOREBOARD] Error: Failed to get player counts^7")
            -- Use default counts if server callback fails
            counts = {
                police = 0,
                ambulance = 0,
                mechanic = 0,
                bennys = 0,
                biker = 0,
                pizzathis = 0,
                cardealer = 0,
                beanmachine = 0,
                total = 0
            }
        end
        
        playerCounts = counts
        
        -- Load player data
        LoadPlayerData(function(success)
            -- Update activities based on requirements
            for i, activity in ipairs(activityConfig.activities) do
                local hasPolice = counts.police >= activity.minPolice
                local hasLevel = MeetsLevelRequirement(activity)
                local hasItem = HasRequiredItem(activity)
                local noCooldown = activity.cooldown <= GetGameTimer()
                
                activityConfig.activities[i].available = hasPolice and hasLevel and hasItem and noCooldown
            end
            
            local activitiesData = GetFormattedActivities()
            
            -- Send data to NUI
            SendNUIMessage({
                action = "openScoreboard",
                activities = activitiesData,
                counts = counts,
                playerLevel = playerLevel
            })
            
            -- Double-check that UI is visible
            Citizen.Wait(100)
            if scoreboardOpen then
                SetNuiFocus(true, true)
            end
        end)
    end)
end

function CloseScoreboard()
    if not scoreboardOpen then return end
    
    scoreboardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "closeScoreboard"
    })
    
    -- Force hide after a short delay to ensure it's closed
    Citizen.Wait(100)
    SendNUIMessage({
        action = "hideUI"
    })
end

-- Emergency reset function
function ResetScoreboard()
    scoreboardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hideUI"
    })
    print("^2[qb-SCOREBOARD] Scoreboard reset completed^7")
end

-- NUI Callbacks
RegisterNUICallback('closeScoreboard', function(data, cb)
    CloseScoreboard()
    cb('ok')
end)

RegisterNUICallback('openSettings', function(data, cb)
    SendNUIMessage({
        action = "openSettings",
        theme = currentTheme
    })
    cb('ok')
end)

RegisterNUICallback('closeSettings', function(data, cb)
    SendNUIMessage({
        action = "closeSettings"
    })
    cb('ok')
end)

RegisterNUICallback('updateSettings', function(data, cb)
    if data.theme then
        currentTheme = data.theme
        applyTheme(data.theme)
    end
    if data.scale then
        currentScale = data.scale
        applyScale(data.scale)
    end
    SaveSettings()
    cb('ok')
end)

-- Error handling for NUI callbacks
RegisterNUICallback('error', function(data, cb)
    print("^1[qb-SCOREBOARD] NUI Error: " .. tostring(data.error) .. "^7")
    cb('ok')
end)

-- Apply theme
function applyTheme(themeName)
    local theme = themes[themeName]
    if theme then
        SendNUIMessage({
            action = "applyTheme",
            theme = theme
        })
    end
end

-- Apply scale
function applyScale(scale)
    SendNUIMessage({
        action = "applyScale",
        scale = scale
    })
end

-- Activity cooldown functions (export for other scripts)
exports('SetActivityCooldown', function(activityName, cooldownSeconds)
    for i, activity in ipairs(activityConfig.activities) do
        if activity.name == activityName then
            activityConfig.activities[i].cooldown = GetGameTimer() + (cooldownSeconds * 1000)
            return true
        end
    end
    return false
end)

exports('GetActivityStatus', function(activityName)
    for _, activity in ipairs(activityConfig.activities) do
        if activity.name == activityName then
            return {
                available = activity.available,
                policeNeeded = activity.minPolice,
                policeOnline = playerCounts.police,
                levelNeeded = activity.minLevel,
                cooldown = activity.cooldown > GetGameTimer() and math.floor((activity.cooldown - GetGameTimer()) / 1000) or 0
            }
        end
    end
    return nil
end)

-- API for other scripts to add activities
exports('AddActivity', function(activityData)
    table.insert(activityConfig.activities, {
        name = activityData.name,
        label = activityData.label or activityData.name,
        description = activityData.description or "No description available",
        icon = activityData.icon or "fas fa-question-circle",
        minPolice = activityData.minPolice or 0,
        minLevel = activityData.minLevel or 0,
        requiredItem = activityData.requiredItem or nil,
        available = false,
        cooldown = 0
    })
end)

-- Update player level function
exports('UpdatePlayerLevel', function(level)
    playerLevel = level
end)

-- Update player items function
exports('UpdatePlayerItems', function(items)
    playerItems = items
end)

-- Event handlers
RegisterNetEvent('qb-scoreboard:UpdateCounts')
AddEventHandler('qb-scoreboard:UpdateCounts', function(counts)
    if not counts then return end
    
    playerCounts = counts
    
    if scoreboardOpen then
        -- Update activities based on new counts
        for i, activity in ipairs(activityConfig.activities) do
            local hasPolice = counts.police >= activity.minPolice
            local hasLevel = MeetsLevelRequirement(activity)
            local hasItem = HasRequiredItem(activity)
            local noCooldown = activity.cooldown <= GetGameTimer()
            
            activityConfig.activities[i].available = hasPolice and hasLevel and hasItem and noCooldown
        end
        
        local activitiesData = GetFormattedActivities()
        
        SendNUIMessage({
            action = "updateData",
            activities = activitiesData,
            counts = counts,
            playerLevel = playerLevel
        })
    end
end)

RegisterNetEvent('qb-scoreboard:UpdatePlayerLevel')
AddEventHandler('qb-scoreboard:UpdatePlayerLevel', function(level)
    playerLevel = level
    
    if scoreboardOpen then
        local activitiesData = GetFormattedActivities()
        
        SendNUIMessage({
            action = "updateData",
            activities = activitiesData,
            counts = playerCounts,
            playerLevel = playerLevel
        })
    end
end)

RegisterNetEvent('qb-scoreboard:UpdatePlayerItems')
AddEventHandler('qb-scoreboard:UpdatePlayerItems', function(items)
    playerItems = items
    
    if scoreboardOpen then
        local activitiesData = GetFormattedActivities()
        
        SendNUIMessage({
            action = "updateData",
            activities = activitiesData,
            counts = playerCounts,
            playerLevel = playerLevel
        })
    end
end)

RegisterNetEvent('qb-scoreboard:ForceClose')
AddEventHandler('qb-scoreboard:ForceClose', function()
    CloseScoreboard()
end)

-- Emergency reset command
RegisterCommand('resetscoreboard', function()
    ResetScoreboard()
    TriggerEvent('QBCore:Notify', 'Scoreboard reset completed', 'success')
end, false)

-- Periodic updates
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(config.activityRefresh)
        
        if scoreboardOpen then
            -- Request updated counts from server
            QBCore.Functions.TriggerCallback('qb-scoreboard:GetAllCounts', function(counts)
                if not counts then return end
                
                playerCounts = counts
                
                -- Update activities
                for i, activity in ipairs(activityConfig.activities) do
                    local hasPolice = counts.police >= activity.minPolice
                    local hasLevel = MeetsLevelRequirement(activity)
                    local hasItem = HasRequiredItem(activity)
                    local noCooldown = activity.cooldown <= GetGameTimer()
                    
                    activityConfig.activities[i].available = hasPolice and hasLevel and hasItem and noCooldown
                end
                
                local activitiesData = GetFormattedActivities()
                
                SendNUIMessage({
                    action = "updateData",
                    activities = activitiesData,
                    counts = counts,
                    playerLevel = playerLevel
                })
            end)
        end
    end
end)

-- Key mapping
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- F10 key to toggle scoreboard
        if IsControlJustPressed(0, 212) then -- F10 key
            ToggleScoreboard()
        end
        
        -- Close scoreboard on escape if open
        if scoreboardOpen and IsControlJustPressed(0, 200) then -- ESC key
            CloseScoreboard()
        end
    end
end)

-- Initialize and hide UI
Citizen.CreateThread(function()
    -- Hide the UI immediately when resource starts
    SendNUIMessage({
        action = "hideUI"
    })
    
    -- Wait for core to be ready
    Citizen.Wait(1000)
    
    -- Load player data
    LoadPlayerData()
    
    -- Load settings
    LoadSettings()
    
    -- Send theme data to NUI
    SendNUIMessage({
        action = "initThemes",
        themes = themes
    })
    
    -- Apply current theme
    applyTheme(currentTheme)
    applyScale(currentScale)
    
    -- Ensure UI is hidden
    Citizen.Wait(100)
    SendNUIMessage({
        action = "closeScoreboard"
    })
    
    print("^2[qb-SCOREBOARD] Resource started successfully^7")
end)

-- Handle resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ResetScoreboard()
    end
end)