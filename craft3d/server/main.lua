local ESX = exports['es_extended']:getSharedObject()

local pendingCrafts = {}

local function hasIngredients(xPlayer, recipe)
    for _, requirement in ipairs(recipe.requirements or {}) do
        local item = xPlayer.getInventoryItem(requirement.item)
        if not item or item.count < requirement.count then
            return false, requirement
        end
    end
    return true
end

RegisterNetEvent('craft3d:attemptCraft', function(recipeIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local recipe = Config.Recipes[recipeIndex]
    if not recipe then
        xPlayer.showNotification('Recette inconnue')
        return
    end

    if pendingCrafts[src] then
        xPlayer.showNotification('Vous êtes déjà en train de fabriquer un objet')
        return
    end

    local success, missing = hasIngredients(xPlayer, recipe)
    if not success then
        xPlayer.showNotification(('Il vous manque %sx %s'):format(missing.count, missing.item))
        return
    end

    for _, requirement in ipairs(recipe.requirements) do
        xPlayer.removeInventoryItem(requirement.item, requirement.count)
    end

    pendingCrafts[src] = recipeIndex
    TriggerClientEvent('craft3d:startProgress', src, recipeIndex)
end)

RegisterNetEvent('craft3d:finishCraft', function(recipeIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local pending = pendingCrafts[src]
    if not pending or pending ~= recipeIndex then
        TriggerClientEvent('craft3d:cancelProgress', src)
        return
    end

    local recipe = Config.Recipes[recipeIndex]
    if not recipe then
        pendingCrafts[src] = nil
        xPlayer.showNotification('Recette introuvable')
        return
    end

    xPlayer.addInventoryItem(recipe.result.item, recipe.result.count)
    xPlayer.showNotification(('Vous avez fabriqué %sx %s'):format(recipe.result.count, recipe.result.item))
    pendingCrafts[src] = nil
end)

AddEventHandler('playerDropped', function()
    pendingCrafts[source] = nil
end)
