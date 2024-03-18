local cartridge = require('cartridge')
local json = require('json')
local vshard = require('vshard')
local http_client = require('http.client').new()
local log = require('log')

local function get_remote_forecast(latitude, longitude)
    log.info("do request")
    local response = http_client:get('https://api.open-meteo.com/v1/forecast?latitude='..latitude..'&longitude='..longitude..'&current=temperature_2m')
    return response
end

local function get_forecast(req)
    --local cluster_config = cartridge.config_get_deepcopy()
    --local hello_section = cluster_config['hello']

    local paramPairs = split(req.query, "&")

    local latitude
    local longitude

    if (string.match(paramPairs[1], "latitude")) then
        latitude = split(paramPairs[1], "=")[2]
        longitude = split(paramPairs[2], "=")[2]
    else
        if (string.match(paramPairs[2], "latitude")) then
            latitude = split(paramPairs[2], "=")[2]
            longitude = split(paramPairs[1], "=")[2]
        end
    end

    local bucket_id = vshard.router.bucket_id_strcrc32(latitude..longitude)

    log.debug("bucketid "..bucket_id)

    local res, err = vshard.router.call(
        bucket_id, { mode = 'read'}, 'get_storage_forecast', { latitude, longitude}
    )
    if res == nil and err == nil then
        local forecast = get_remote_forecast(latitude, longitude)
        vshard.router.call(
            bucket_id, { mode = 'write' }, 'put_storage_forecast', { latitude, longitude, bucket_id, forecast }
        )
        res = forecast
    else
        if err ~= nil then
            log.error(err)
        end
    end

    return res
end

function split(str, character)
    local result = {}

    local index = 1
    for s in string.gmatch(str, "[^" .. character .. "]+") do
        result[index] = s
        index = index + 1
    end
    return result
end



return {
    get_forecast = get_forecast
}
