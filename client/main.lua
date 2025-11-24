local ESX = exports['es_extended']:getSharedObject()

local craftingTables = {}
local openTable
local menuOpen = false
local selectedRecipe = 1
local isCrafting = false
local clamp = function(value, min, max)
    return math.max(min, math.min(max, value))
end

local function getCoordsComponents(coords)
    if not coords then return end

    local coordsType = type(coords)

    if coordsType == 'vector4' then
        return coords.x, coords.y, coords.z, coords.w
    elseif coordsType == 'vector3' then
        return coords.x, coords.y, coords.z, 0.0
    elseif coordsType == 'table' then
        local x = coords.x or coords[1]
        local y = coords.y or coords[2]
        local z = coords.z or coords[3]
        local w = coords.w or coords[4] or coords.heading
        return x, y, z, w
    end
end

local function getTablePosition(tableData)
    local x, y, z = getCoordsComponents(tableData.coords)

    if x and y and z then
        return vector3(x + 0.0, y + 0.0, z + 0.0)
    end

    return vector3(0.0, 0.0, 0.0)
end

local function getTableHeading(tableData)
    local _, _, _, w = getCoordsComponents(tableData.coords)

    if w then
        return w + 0.0
    end

    return tableData.heading or 0.0
end

local function debugPrint(msg)
    if Config.Debug then
        print(('[craft3d] %s'):format(msg))
    end
end

local function loadModel(model)
    if not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) do
        Wait(50)
        attempts += 1
        if attempts > 100 then
            return false
        end
    end

    return true
end

local function spawnTables()
    for _, tableData in ipairs(Config.Tables) do
        if loadModel(tableData.model) then
            local position = getTablePosition(tableData)
            local heading = getTableHeading(tableData)
            local obj = CreateObject(tableData.model, position.x, position.y, position.z - 1.0, false, false, true)
            SetEntityHeading(obj, heading)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
            tableData.entity = obj
            craftingTables[#craftingTables + 1] = tableData
            debugPrint(('Table spawnée à %s'):format(position))
        else
            print(('[craft3d] Impossible de charger le modèle %s'):format(tableData.model))
        end
    end
end

local function Draw3DText(coords, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function closeMenu()
    if not menuOpen then return end

    menuOpen = false
    openTable = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu(tableData)
    if menuOpen or isCrafting then return end

    openTable = tableData
    menuOpen = true
    selectedRecipe = 1

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        recipes = Config.Recipes,
        selected = selectedRecipe,
        title = 'Établi de craft'
    })
end

local function runProgress(recipe)
    if Config.UseProgressBar then
        local progress = Config.ProgressExport
        local resource = progress and progress.resource
        local method = progress and progress.method

        if resource and method and exports[resource] and exports[resource][method] then
            exports[resource][method](recipe.time, ('Fabrication: %s'):format(recipe.label))
            return
        end

        debugPrint('Progression: export introuvable, utilisation de la barre locale')
    end

    SendNUIMessage({
        action = 'progress',
        label = ('Fabrication: %s'):format(recipe.label),
        duration = recipe.time
    })

    local endTime = GetGameTimer() + recipe.time
    while GetGameTimer() < endTime do
        Wait(0)
    end

    SendNUIMessage({ action = 'progress-finish' })
end

local function startCraft(recipeIndex)
    if isCrafting then return end

    local recipe = Config.Recipes[recipeIndex]
    if not recipe then return end

    isCrafting = true
    selectedRecipe = recipeIndex
    closeMenu()

    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_HAMMERING', 0, true)

    runProgress(recipe)

    ClearPedTasks(ped)
    TriggerServerEvent('craft3d:finishCraft', recipeIndex)
    isCrafting = false
end

RegisterNetEvent('craft3d:startProgress', function(recipeIndex)
    startCraft(recipeIndex)
end)

RegisterNetEvent('craft3d:cancelProgress', function()
    ClearPedTasks(PlayerPedId())
    isCrafting = false
    SendNUIMessage({ action = 'progress-finish' })
end)

RegisterNUICallback('craft3d:close', function(_, cb)
    closeMenu()
    cb({})
end)

RegisterNUICallback('craft3d:select', function(data, cb)
    local index = tonumber(data and data.index) or 1
    selectedRecipe = clamp(index, 1, #Config.Recipes)
    cb({})
end)

RegisterNUICallback('craft3d:start', function(data, cb)
    local index = tonumber(data and data.index) or selectedRecipe
    selectedRecipe = index
    TriggerServerEvent('craft3d:attemptCraft', selectedRecipe)
    cb({})
end)

CreateThread(function()
    Wait(500)
    spawnTables()

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearTable

        for _, tableData in ipairs(craftingTables) do
            local tablePosition = getTablePosition(tableData)
            local distance = #(playerCoords - tablePosition)
            if distance <= (tableData.radius + 0.5) then
                nearTable = tableData
                sleep = 0
                Draw3DText(tablePosition + vector3(0.0, 0.0, 1.0), '~y~E~s~ - Utiliser l\'établi de craft', 0.35)
                if IsControlJustPressed(0, 38) and not menuOpen and not isCrafting then
                    openMenu(tableData)
                end
            end
        end

        if not nearTable and menuOpen then
            closeMenu()
        end

        Wait(sleep)
    end
end)
