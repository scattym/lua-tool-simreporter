
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

-- gsplit: iterate over substrings in a string separated by a pattern
--
-- Parameters:
-- text (string)    - the string to iterate over
-- pattern (string) - the separator pattern
-- plain (boolean)  - if true (or truthy), pattern is interpreted as a plain
--                    string, not a Lua pattern
--
-- Returns: iterator
--
-- Usage:
-- for substr in gsplit(text, pattern, plain) do
--   doSomething(substr)
-- end
local function gsplit(text, pattern, plain)
  local splitStart, length = 1, #text
  return function ()
    if splitStart then
      local sepStart, sepEnd = string.find(text, pattern, splitStart, plain)
      local ret
      if not sepStart then
        ret = string.sub(text, splitStart)
        splitStart = nil
      elseif sepEnd < sepStart then
        -- Empty separator!
        ret = string.sub(text, splitStart, sepStart)
        if sepStart < length then
          splitStart = sepStart + 1
        else
          splitStart = nil
        end
      else
        ret = sepStart > splitStart and string.sub(text, splitStart, sepStart - 1) or ''
        splitStart = sepEnd + 1
      end
      return ret
    end
  end
end

-- split: split a string into substrings separated by a pattern.
--
-- Parameters:
-- text (string)    - the string to iterate over
-- pattern (string) - the separator pattern
-- plain (boolean)  - if true (or truthy), pattern is interpreted as a plain
--                    string, not a Lua pattern
--
-- Returns: table (a sequence table containing the substrings)
local function safe_split(text, pattern, plain)
  local ret = {}
  for match in gsplit(text, pattern, plain) do
    table.insert(ret, match)
  end
  return ret
end

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
    local line_array = split(response, "\r\n");
    for num = 1,#line_array do
        logger.log("util", 0, "Processing line ", tostring(line_array[num]));
        if not line_array[num] then
            logger.log("util", 30, "Did not get a line to parse. Line is nil.")
        else
            if string.match(line_array[num], key) then
                logger.log("util", 0, "Found key: ", key, " in line: ", line_array[num])
                --local key_value_arr = split(line_array[num], key_val_sep)
                local key, value = line_array[num]:match('([^' .. key_val_sep .. ']*)' .. key_val_sep .. '(.*)')
                if key and value then
                    -- local field_array = safe_split(key_value_arr[2], field_sep, true)
                    local field_array = safe_split(value, field_sep, true)
                    if field_array == nil then
                        logger.log("util", 30, "Unable to split key/value pair. Field array is nil");
                    elseif #field_array ~= #field_name_array then
                        logger.log(
                            "util",
                            30,
                            "Field array size does not match. Expecting: ",
                            tostring(#field_name_array),
                            " but got: ",
                            tostring(#field_array),
                            ", line: ",
                            line_array[num],
                            ", looking for: ",
                            key
                        )
                    else
                        for field_name_iter = 1, #field_name_array do
                            return_table[field_name_array[field_name_iter]] = trim(field_array[field_name_iter]);
                        end
                    end
                else
                    logger.log("util", 30, "Unable to split key/value pair for line", line_array[num]);
                end
            else
                logger.log("util", 20, "Key: ", key, " not in line: ", line_array[num]);
            end
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
    if type(data) == "string" then
        return (data:gsub(".", function (x)
            return ("%02x"):format(x:byte()) end)
        )
    else
	    local hexBytes = ""

        for i,byte in ipairs(data) do
            if type(byte) == "string" then
                hexBytes = hexBytes .. string.format("%02X", string.byte(byte))
            else
                hexBytes = hexBytes .. string.format("%02X", byte)
            end

        end

        return hexBytes
    end
end
_M.tohex = tohex

local function fromhex(data)
    return (data:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end
_M.fromhex = fromhex


return _M
