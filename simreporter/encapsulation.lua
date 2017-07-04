

local _M = {}

local add_field = function(data, key, value, type)
    local return_str = data
    if( return_str ~= "" ) then
        return_str = return_str .. ","
    end
    return_str = return_str .. '"' .. key .. '" : '

    local value_str = tostring(value);
    if( type == "raw") then
        return_str = return_str .. value_str
    else
        return_str = string.format("%s\"%s\"", return_str, value_str:gsub("\r\n", "|"):gsub('"', '\\"'))
    end;

    print("return string is:")
    print(return_str)
    print("\r\n")
    return return_str;
end;

local encapsulate_data = function(device_info, table_data, iteration, count)
    local data = ""
    data = add_field(data, "version", "1", "raw")
    data = add_field(data, "device_info", device_info, "string")
    for key, value in pairs(table_data) do
        data = add_field(data, key, value, "string")
    end;
    data = add_field(data, "packet_number", iteration, "raw")
    data = add_field(data, "packet_count", count, "raw")
    return "{" .. data .. "}";
end;

_M.encapsulate_data = encapsulate_data



local encapsulate_nmea = function(device_info, key, data, iteration, count)
    local before = "{ \"version\" : 1, "
    before = before .. "\"device_info\" : \"" .. tostring(device_info) .. "\", "
    before = before .. "\"nmea_number\" : " .. tostring(iteration) .. ", "
    before = before .. "\"nmea_total\" : " .. tostring(count) .. ", "
    print("Before is " .. before .. "\r\n")
    local payload = "\"" .. key .."\" : \"" .. tostring(data) .. "\" "
    print("Payload is " .. payload .. "\r\n")
    local after = "}"
    print("After is " .. after .. "\r\n")
    return before .. payload .. after
end

_M.encapsulate_nmea = encapsulate_nmea

return _M
