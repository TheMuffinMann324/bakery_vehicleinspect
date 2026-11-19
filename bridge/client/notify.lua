-- Notifications (client). Swap this for your own notify resource if you like.
-- kind: 'inform' | 'success' | 'error'

function Notify(text, kind)
    kind = kind or 'inform'
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(text, kind)
    elseif GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', text, kind == 'inform' and 'primary' or kind)
    elseif GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', text)
    else
        lib.notify({ description = text, type = kind })
    end
end
