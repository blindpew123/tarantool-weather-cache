local log = require('log')


local function err_handler(message)
    return { message = message, trace = debug.traceback() }
end


local function put_storage_forecast_internal(args)


    local key  = args[1]
    local bucket_id = args[2]
    local forecast = args[3]
    box.space.forecast:insert({key, bucket_id, forecast})

end

local function get_storage_forecast_internal(args)


    local latitude  = args[1]
    local longitude = args[2]


    local key = latitude.."_"..longitude
    local forecast = box.space.forecast:get(key)

    if forecast ~= nil then
        return forecast.forecast
    else
        return forecast
    end
end


local function put_storage_forecast(latitude, longitude, bucket_id, forecast)
    log.info("put")
    local key = latitude.."_"..longitude
    local ok, res =  xpcall(put_storage_forecast_internal, err_handler, {key, bucket_id, forecast})
    log.info(res)
end

local function get_storage_forecast(latitude, longitude)
    log.info(latitude)
    local ok, res =  xpcall(get_storage_forecast_internal, err_handler, {latitude, longitude})
    log.info(res)
    return res
end

return {
    get_storage_forecast = get_storage_forecast,
    put_storage_forecast = put_storage_forecast,
}
