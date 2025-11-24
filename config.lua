Config = {}

Config.Locale = 'fr'

Config.Tables = {
    {
        model = `prop_tool_bench02_ld`,
        coords = vector4(-518.18, -171.05, 37.65, 28.0),
        radius = 2.0
    }
}

Config.Recipes = {
    {
        label = 'Kit de réparation',
        result = { item = 'fixkit', count = 1 },
        requirements = {
            { item = 'metal', count = 5 },
            { item = 'plastic', count = 2 }
        },
        time = 5000
    },
    {
        label = 'Chargeur bricolé',
        result = { item = 'clip', count = 1 },
        requirements = {
            { item = 'scrapmetal', count = 8 },
            { item = 'spring', count = 2 }
        },
        time = 7500
    },
    {
        label = 'Trousse médicale',
        result = { item = 'medikit', count = 1 },
        requirements = {
            { item = 'bandage', count = 2 },
            { item = 'alcohol', count = 1 }
        },
        time = 6000
    }
}

Config.UseProgressBar = true -- si vous avez un export de barre de progression type ox_lib / rprogress
-- Définissez la ressource et la méthode exportée à appeler: exports[resource][method](duration, label)
Config.ProgressExport = {
    resource = 'ox_lib',
    method = 'progressBar'
}
Config.Debug = false
