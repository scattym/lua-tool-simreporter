

local _M = {}

local json = require("json")

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
    return return_str;
end;

local function encode_strings(table)
    for key, value in pairs(table) do
        if type(value) == "table" then
            encode_strings(value)
        elseif type(value) == "string" then
            table[key] = value:gsub("\r\n", "|"):gsub("\n", "|")
        end
    end
end

local encapsulate_data = function(imei, table_data)
    table_data["imei"] = imei
    encode_strings(table_data)
    return json.encode(table_data)
end;

_M.encapsulate_data = encapsulate_data

return _M
