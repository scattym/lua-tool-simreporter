
local _M = {}

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
    print("response string is ", tostring(response), "\r\n")
    -- +CSPN: "YES OPTUS",1
    -- +CSPN: "Telstra",2
    -- Normalise ": " to ":"
    if response == nil then
        print("Reponse string is nil. Not parsing\r\n");
        return return_table;
    end;
    line_array = split(response, "\r\n");
    for num = 1,#line_array do
        print("Processing line ", tostring(line_array[num]), "\r\n");
        if string.match(line_array[num], key) then
            print("Found key: ", key, " in line: ", line_array[num], "\r\n")
            local key_value_arr = split(line_array[num], key_val_sep)
            if #key_value_arr == 2 then
                local field_array = split(key_value_arr[2], field_sep)
                if field_array == nil then
                    print ("Unable to split key/value pair. Field array is nil\r\n");
                elseif #field_array ~= #field_name_array then
                    print("Field array size does not match. Expecting: ", tostring(#field_name_array), " but got: ", tostring(#field_array), "\r\n");
                else
                    for field_name_iter = 1, #field_name_array do
                        return_table[field_name_array[field_name_iter]] = trim(field_array[field_name_iter]);
                    end
                end
            else
                print("Unable to split key/value pair. Size is ", #key_value_arr, "\r\n");
            end
        else
            print("Key: ", key, " not in line: ", line_array[num], "\r\n");
        end
    end
    return return_table;
end
_M.response_to_array = response_to_array

local print_simple_table = function(name, input)
    print("Table: ", name, "\r\n");
    for key, value in pairs(input) do
      print(key, " => ", value, "\r\n");
    end
end
_M.print_simple_table = print_simple_table


return _M
