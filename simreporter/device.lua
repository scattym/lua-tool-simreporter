
local at = require "at_commands"
local _M = {}
local get_device_info_table = function()
    cell_table = {}
    cell_table["cpsi"] = at.get_cpsi();
    cell_table["cell_info"] = at.get_cell_info();
    cell_table["cbc"] = at.get_cbc();
    cell_table["cclk"] = at.get_cclk();
    cell_table["cgsn"] = at.get_cgsn();
    cell_table["cgmi"] = at.get_cgmi();
    cell_table["cgmm"] = at.get_cgmm();
    cell_table["cgmr"] = at.get_cgmr();
    cell_table["cops"] = at.get_cops();
    cell_table["ciccid"] = at.get_ciccid();
    cell_table["cspn"] = at.get_cspn();
    cell_table["cimi"] = at.get_cimi();
    cell_table["osclock"] = os.clock();
    return cell_table;
end;
_M.get_device_info_table = get_device_info_table

return _M;