-- Targeting (client): ox_target or qb-target.
-- options = { label, icon (font awesome name, e.g. 'file-signature'), distance, onSelect }

function AddEntityTarget(entity, options)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(entity, {
            name = GetCurrentResourceName(),
            label = options.label,
            icon = 'fa-solid fa-' .. options.icon,
            distance = options.distance,
            onSelect = options.onSelect,
        })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                { label = options.label, icon = 'fas fa-' .. options.icon, action = options.onSelect },
            },
            distance = options.distance,
        })
    else
        print(('^3[%s] ox_target or qb-target is needed to talk to the registration clerk^0'):format(GetCurrentResourceName()))
    end
end
