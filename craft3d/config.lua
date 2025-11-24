Config = {}

Config.Locale = 'fr'

Config.Tables = {
    {
        model = `prop_tool_bench02_ld`,
        coords =  vector4(4442.35, -4467.08, 4.33, 195.86) ,
        radius = 2.0
    }
}

Config.Recipes = {
    {
        label = 'Kit de sultan',
        result = { item = 'sultan', count = 1 },
        requirements = {
            { item = 'wood', count = 5 },
        },
        time = 1000
    },
}

Config.UseProgressBar = true -- si vous avez un export de barre de progression type ox_lib / rprogress
-- Définissez la ressource et la méthode exportée à appeler: exports[resource][method](duration, label)
Config.ProgressExport = {
    resource = 'ox_lib',
    method = 'progressBar'
}
Config.Debug = false
