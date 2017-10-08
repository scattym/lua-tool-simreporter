
local _M = {}
logger = require("logging")

local str_split = function(string, inSplitPattern, outResults )
    if not outResults then
        outResults = { }
    end
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
    while theSplitStart do
        table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
        theStart = theSplitEnd + 1
        theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
    end
    table.insert( outResults, string.sub( self, theStart ) )
    return outResults
end
_M.str_split = str_split

local split = function(source, delimiters)
    local elements = {}
    local pattern = '([^'..delimiters..']+)'
    string.gsub(source, pattern, function(value) elements[#elements + 1] =     value;  end);
    return elements
end
_M.split = split

local split_str = function(source, split_string)
    local elements = {}
    local pattern = '(^'..delimiters..')'
    string.gsub(source, pattern, function(value) elements[#elements + 1] =     value;  end);
    return elements
end
_M.split_str = split_str

-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
local trim = function(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end
_M.trim = trim

local response_to_array = function(response, key, key_val_sep, field_sep, field_name_array)
    local return_table = {}
    logger.log("util", 0, "response string is ", tostring(response))
    -- +CSPN: "YES OPTUS",1
    -- +CSPN: "Telstra",2
    -- Normalise ": " to ":"
    if response == nil then
        logger.log("util", 0, "Reponse string is nil. Not parsing");
        return return_table;
    end;
    line_array = split(response, "\r\n");
    for num = 1,#line_array do
        logger.log("util", 0, "Processing line ", tostring(line_array[num]));
        if string.match(line_array[num], key) then
            logger.log("util", 0, "Found key: ", key, " in line: ", line_array[num])
            local key_value_arr = split(line_array[num], key_val_sep)
            if #key_value_arr == 2 then
                local field_array = split(key_value_arr[2], field_sep)
                if field_array == nil then
                    logger.log("util", 30, "Unable to split key/value pair. Field array is nil");
                elseif #field_array ~= #field_name_array then
                    logger.log("util", 30, "Field array size does not match. Expecting: ", tostring(#field_name_array), " but got: ", tostring(#field_array));
                else
                    for field_name_iter = 1, #field_name_array do
                        return_table[field_name_array[field_name_iter]] = trim(field_array[field_name_iter]);
                    end
                end
            else
                logger.log("util", 30, "Unable to split key/value pair. Size is ", #key_value_arr);
            end
        else
            logger.log("util", 20, "Key: ", key, " not in line: ", line_array[num]);
        end
    end
    return return_table;
end
_M.response_to_array = response_to_array

local print_simple_table = function(name, input)
    logger.log("util", 20, "Table: ", name);
    for key, value in pairs(input) do
      logger.log("util", 20, key, " => ", value);
    end
end
_M.print_simple_table = print_simple_table

local tohex = function(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end
_M.tohex = tohex


return _M
