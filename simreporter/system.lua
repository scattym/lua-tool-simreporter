local _M = {}
local logging = require("logging")
local logger = logging.create("system", 30)


local quarantined_as_string = function()
    local file = io.open("c:/quarantined","r")
    if( not file ) then
        logger(10, "No file, so not quarantined\r\n")
        return false
    end

    local return_str = ""
    while true do
        local line = file:read("*l")
        if line == nil then
            logger(0, "Reached end of file\r\n")
            break
        end
        logger(10, "line is ", line, "<\r\n")
        return_str = return_str .. "|" .. line
    end
    return return_str

end
_M.quarantined_as_string = quarantined_as_string

local get_current_memory = function()
    return tostring(getcurmem());
end
_M.get_current_memory = get_current_memory

local get_peak_memory = function()
    return tostring(getpeakmem());
end
_M.get_peak_memory = get_peak_memory


local get_max_memory = function()
    if getmaxmem ~= nil then
        return tostring(getmaxmem());
    end
    return 0
end
_M.get_max_memory = get_max_memory

local get_uptime = function()
    return tostring(os.clock());
end
_M.get_uptime = get_uptime



return _M