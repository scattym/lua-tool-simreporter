--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 1/1/18
-- Time: 9:02 AM
-- To change this template use File | Settings | File Templates.
--

local util = require("util")
local logging = require("logging")
local json = require("json")

local logger = logging.create("cell_info", 30)

_M = {}

local function clean_fields(cell_table)
    -- loop over top level cell table which is an array of cells
    for i, entry in pairs(cell_table) do
        for key, value in pairs(entry) do
            if entry[key] and entry[key]:match(":") then
                entry[key] = entry[key]:gsub('^[^:]*:', '')
            end
            if key == "rx_level" then
                entry[key] = entry[key]:gsub('[dD][bB][mM]', '')
            end
        end
    end
end

local function primary_cell_table_to_array(cell_table)
    local return_table = {}
    for i, cell in pairs(cell_table) do
        local fields = {
            "uarfcn", "mcc", "mnc", "lac", "id", "psc", "ssc", "rscp", "ecio", "rx_level", "tx_power"
        }
        local cell_entry = {}
        for j, field in pairs(fields) do
            table.insert(cell_entry, tonumber(cell[field]))
        end
        table.insert(return_table, cell_entry)
    end
    return return_table
end

local function secondary_cell_table_to_array(cell_table)
    local return_table = {}
    for i, cell in pairs(cell_table) do
        local fields = {
            "uarfcn", "psc", "ssc", "rscp", "ecio", "rx_level"
        }
        local cell_entry = {}
        for j, field in pairs(fields) do
            table.insert(cell_entry, tonumber(cell[field]))
        end
        table.insert(return_table, cell_entry)
    end
    return return_table
end

local function cell_info_to_table(cell_info, remove_out_of_range)
    local return_table = {}
    logger(0, "Cell info string is ", tostring(cell_info))
    if cell_info == nil then
        logger(0, "Reponse string is nil. Not parsing");
        return return_table;
    end;
    local line_array = util.split(cell_info, "\r\n");
    local primary_cells = {}
    local secondary_cells = {}
    for num = 1,#line_array do
        if line_array[num]:match("SCELL") then
            local fields = {
                "type", "uarfcn", "mcc", "mnc", "lac", "id", "psc", "ssc", "rscp", "ecio", "rx_level", "tx_power"
            }
            local primary_cell = util.response_to_array(line_array[num], "+CCINFO", ":", ",", fields)
            if primary_cell then
                table.insert(primary_cells, primary_cell)
            end
        elseif line_array[num]:match("NCell") then
            local fields = {
                "type", "uarfcn", "psc", "ssc", "rscp", "ecio", "rx_level"
            }
            local secondary_cell = util.response_to_array(line_array[num], "+CCINFO", ":", ",", fields)
            if secondary_cell then
                table.insert(secondary_cells, secondary_cell)
            end
        end
    end
    clean_fields(primary_cells)
    clean_fields(secondary_cells)
    local return_table = {}
    return_table["p"] = primary_cell_table_to_array(primary_cells)
    return_table["s"] = secondary_cell_table_to_array(secondary_cells)
    print(json.encode(return_table))
    -- print(json.encode(secondary_cell_table_to_array(secondary_cells)))
    return return_table
end
_M.cell_info_to_table = cell_info_to_table

return _M
