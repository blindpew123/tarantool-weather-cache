local cartridge = require('cartridge')
local storage = require('app.src.storage')

local function init(opts) -- luacheck: no unused args
    rawset(_G, "get_storage_forecast", storage.get_storage_forecast)
    rawset(_G, "put_storage_forecast", storage.put_storage_forecast)
    if opts.is_master then
        local forecast = box.schema.space.create('forecast', { if_not_exists = true })
        forecast:format({
            {'coordinates', 'string'},
            {'bucket_id', 'unsigned'},
            {'forecast', 'map'},
        })
        forecast:create_index('coordinates', {parts = {'coordinates'}, if_not_exists = true })
        forecast:create_index('bucket_id', {parts = {'bucket_id'}, unique = false, if_not_exists = true })

        box.schema.func.create('get_storage_forecast', { if_not_exists = true })
        box.schema.role.grant('public', 'execute', 'function', 'get_storage_forecast', { if_not_exists = true })

        box.schema.func.create('put_storage_forecast', { if_not_exists = true })
        box.schema.role.grant('public', 'execute', 'function', 'put_storage_forecast', { if_not_exists = true })
    end

    return true
end

local function stop()
    return true
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args
    --if conf_new['hello'] ~= nil and conf_new['hello']['name'] == nil then
    --    return false
    --end

    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    return true
end

return {
    role_name = 'app.roles.storage',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    dependencies = {'cartridge.roles.vshard-storage'},
}
