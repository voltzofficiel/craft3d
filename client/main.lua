local ESX = exports['es_extended']:getSharedObject()

local craftingTables = {}
local openTable
local menuOpen = false
local selectedRecipe = 1
local isCrafting = false

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
            local obj = CreateObject(tableData.model, tableData.coords.x, tableData.coords.y, tableData.coords.z - 1.0, false, false, true)
            SetEntityHeading(obj, tableData.heading or 0.0)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
            tableData.entity = obj
            craftingTables[#craftingTables + 1] = tableData
            debugPrint(('Table spawnée à %s'):format(tableData.coords))
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

local function DrawFloatingCard(text, onScreenX, onScreenY, width, height, active)
    local alpha = active and 180 or 120
    DrawRect(onScreenX, onScreenY, width, height, 10, 10, 10, alpha)
    DrawRect(onScreenX, onScreenY - height / 2 + 0.005, width, 0.003, 255, 163, 26, 200)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(active and 255 or 200, active and 255 or 200, 255, 255)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(onScreenX, onScreenY - 0.012)
end

local function DrawControlHints(text, x, y)
    SetTextScale(0.3, 0.3)
    SetTextFont(0)
    SetTextColour(255, 255, 255, 200)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function drawMenu(tableData)
    local base = tableData.coords + vector3(0.0, 0.0, 1.05)
    local onScreen, anchorX, anchorY = World3dToScreen2d(base.x, base.y, base.z)
    if not onScreen then return end

    local width = 0.18
    local height = 0.045
    for idx, recipe in ipairs(Config.Recipes) do
        local offsetZ = (idx - 1) * 0.06
        local show, cardX, cardY = World3dToScreen2d(base.x, base.y, base.z + offsetZ)
        if show then
            DrawFloatingCard(recipe.label, cardX, cardY, width, height, selectedRecipe == idx)
        end
    end

    DrawControlHints('↑/↓ Sélection   ~y~E~s~ Craft   ~r~Retour~s~ Quitter', anchorX, anchorY + 0.12)
end

local function closeMenu()
    menuOpen = false
    openTable = nil
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

    local endTime = GetGameTimer() + recipe.time
    while GetGameTimer() < endTime do
        Wait(0)
        DrawRect(0.5, 0.92, 0.2, 0.015, 10, 10, 10, 150)
        local remaining = (endTime - GetGameTimer()) / recipe.time
        DrawRect(0.5 - (1 - remaining) * 0.1, 0.92, 0.2 * remaining, 0.008, 255, 163, 26, 220)
        DrawControlHints(('Fabrication en cours... %ds'):format(math.ceil((endTime - GetGameTimer()) / 1000)), 0.5, 0.88)
    end
end

local function startCraft(recipe)
    if isCrafting then return end
    isCrafting = true

    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_HAMMERING', 0, true)

    runProgress(recipe)

    ClearPedTasks(ped)
    TriggerServerEvent('craft3d:finishCraft', selectedRecipe)
    isCrafting = false
end

RegisterNetEvent('craft3d:startProgress', function(recipeIndex)
    local recipe = Config.Recipes[recipeIndex]
    if not recipe then return end
    startCraft(recipe)
end)

RegisterNetEvent('craft3d:cancelProgress', function()
    ClearPedTasks(PlayerPedId())
    isCrafting = false
end)

local function openMenu(tableData)
    if menuOpen then return end
    openTable = tableData
    menuOpen = true
    selectedRecipe = 1

    CreateThread(function()
        while menuOpen do
            Wait(0)
            drawMenu(tableData)

            if IsControlJustPressed(0, 172) then
                selectedRecipe = selectedRecipe - 1
                if selectedRecipe < 1 then selectedRecipe = #Config.Recipes end
            elseif IsControlJustPressed(0, 173) then
                selectedRecipe = selectedRecipe + 1
                if selectedRecipe > #Config.Recipes then selectedRecipe = 1 end
            elseif IsControlJustPressed(0, 38) then
                TriggerServerEvent('craft3d:attemptCraft', selectedRecipe)
            elseif IsControlJustPressed(0, 202) then
                closeMenu()
            end
        end
    end)
end

CreateThread(function()
    Wait(500)
    spawnTables()

    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearTable

        for _, tableData in ipairs(craftingTables) do
            local distance = #(playerCoords - tableData.coords)
            if distance <= (tableData.radius + 0.5) then
                nearTable = tableData
                sleep = 0
                Draw3DText(tableData.coords + vector3(0.0, 0.0, 1.0), '~y~E~s~ - Utiliser l\'établi de craft', 0.35)
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
