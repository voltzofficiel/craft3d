# Craft 3D ESX

Table de craft immersive avec menu 3D ancré dans le monde pour ESX.

## Fonctionnalités
- Table d'atelier placée sur la carte (configurable) avec modèle d'objet.
- Menu de recettes flottant en 3D : navigation ↑/↓, craft avec **E**, fermeture avec **Retour**.
- Consommation des ressources serveur-side, notifications ESX, protection contre le spam de craft.
- Animation de martelage et barre de progression personnalisable (ox_lib / rprogress ou fallback intégré).

## Installation
1. Copiez la ressource dans votre dossier `resources/[local]` et ajoutez-la à votre `server.cfg` :
   ```
   ensure craft3d
   ```
2. Vérifiez que `es_extended` est chargé ainsi qu'une barre de progression optionnelle si vous activez `Config.UseProgressBar`.
3. Si vous utilisez une autre base de données qu'oxmysql, retirez la ligne correspondante dans `fxmanifest.lua`.

## Configuration
- `Config.Tables` : position, rayon et modèle de chaque établi (plusieurs entrées possibles).
  - Les coordonnées peuvent être définies en `{ x = X, y = Y, z = Z, h = H }` pour utiliser directement X/Y/Z/H.
- `Config.Recipes` : label, item résultant, quantités requises et durée de craft (ms).
- `Config.UseProgressBar` / `Config.ProgressExport` : active un export de barre de progression déjà présent sur votre serveur.
- `Config.Debug` : affiche des logs supplémentaires côté client.

Exemple avec deux établis :

```lua
Config.Tables = {
    {
        model = `prop_tool_bench02_ld`,
        coords = { x = -518.18, y = -171.05, z = 37.65, h = 28.0 },
        radius = 2.0
    },
    {
        model = `prop_tool_bench02_ld`,
        coords = { x = -350.0, y = -128.0, z = 39.0, h = 90.0 },
        radius = 2.0
    }
}
```

## Utilisation en jeu
- Approchez-vous de l'établi : un prompt 3D apparaît (`E - Utiliser l'établi`).
- Ouvrez le menu et naviguez entre les recettes. Appuyez sur **E** pour lancer la fabrication.
- Le serveur vérifie et retire automatiquement les ressources puis vous remet l'objet fabriqué à la fin.
