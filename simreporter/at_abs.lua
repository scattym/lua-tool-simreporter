local _M = {}

local at = require "at_commands"
local util = require "util"

local get_sim_operator = function()
    local cspn = at.get_cspn()
    print("cspn return string is " .. tostring(cspn))
    -- +CSPN: "YES OPTUS",1
    -- +CSPN: "Telstra",2
    line_array = util.split(cspn, "\r\n")
    for num = 1,#line_array do
        print("Processing line" .. tostring(line_array[num]))
        if string.match(line_array[num], "CSPN") then
            key_value_arr = util.split(line_array[num], ": ")
            if #key_value_arr == 2 then
                return key_value_arr[2]
            end
        end
    end
    return ""
end

_M.get_sim_operator = get_sim_operator


return _M