Config = {}

Config.Locale = 'fr'

Config.Tables = {
    {
        model = `prop_tool_bench02_ld`,
        coords = vector3(-518.18, -171.05, 37.65),
        heading = 28.0,
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
Config.ProgressExport = 'progressBar' -- fonction client appelée progressBar(duration, label)
Config.Debug = false
