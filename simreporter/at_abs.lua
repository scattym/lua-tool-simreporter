local _M = {}

local at = require("at_commands")
local util = require("util")

    -- +CSPN: "YES OPTUS",1
    -- +CSPN: "Telstra",2

local get_cspn = function()
    cspn_fields = {"spn", "disp_mode"}
    local cspn_response = at.get_cspn();
    local spn_table = util.response_to_array(cspn_response, "+CSPN", ":", ",", cspn_fields);
    util.print_simple_table("spn_table", spn_table);
    return spn_table;
end 
_M.get_cspn = get_cspn

local get_imei = function()
    imei_fields = {"imei"}
    local ati_response = at.get_device_info();
    local device_info_table = util.response_to_array(ati_response, "IMEI", ":", ",", imei_fields);
    util.print_simple_table("device_info_table", device_info_table);
    return device_info_table["imei"];
end
_M.get_imei = get_imei

local get_sim_operator = function()
    spn_table = get_cspn()
    if spn_table["spn"] then
        return spn_table["spn"];
    end
    return "";
end
_M.get_sim_operator = get_sim_operator


-- AT+CGPSINFO
-- +CGPSINFO:3348.946584,S,15112.011722,E,150717,023133.4,90.4,0.0,0
-- AmpI/AmpQ: 443/434
-- OK
local get_location = function()
    local gpsinfo_fields = {"lat", "north_south", "long", "east_west", "date", "time", "altitude", "speed", "course"}
    local cgpsinfo_response = at.get_cgpsinfo();
    local cgpsinfo_table = util.response_to_array(cgpsinfo_response, "+CGPSINFO", ":", ",", gpsinfo_fields);
    util.print_simple_table("cgpsinfo_table", cgpsinfo_table);
    return cgpsinfo_table;
end
_M.get_location = get_location

local is_location_valid = function()
    local location = get_location();
    if location["lat"] and location["lat"] ~= "" then
        return true;
    end
    return false;
end
_M.is_location_valid = is_location_valid

--AT+COPS?
--+COPS: 0,2,"50501",2
--OK
local get_operator = function()
    local operator_fields = {"mode", "format", "operator", "access_tech"}
    local cops_response = at.get_cops()
    local operator_table = util.response_to_array(cops_response, "+COPS", ":", ",", operator_fields);
    util.print_simple_table("operator_table", operator_table);
    return operator_table;
end
_M.get_operator = get_operator

--AT+CGDCONT?
--+CGDCONT: 1,"IP","","0.0.0.0",0,0
--OK
local get_gdcont = function()
    local gdcont_fields = {"client_id", "pdp_type", "apn", "pdp_addr", "compression", "header_compression"};
    local gdcont_response = at.get_cgdcont();
    local gdcont_table = util.response_to_array(gdcont_response, "+CGDCONT: 1,", ":", ",", gdcont_fields);
    util.print_simple_table("gdcont_table", gdcont_table);
    return gdcont_table;
end;
_M.get_gdcont = get_gdcont

local get_data_apn = function()
    local gdcont_table = get_gdcont()
    if gdcont_table["apn"] then
        return gdcont_table["apn"]
    end
    return ""
end;
_M.get_data_apn = get_data_apn

--AT+CGSOCKCONT?
--+CGSOCKCONT: 1,"IP","telstra.wap","0.0.0.0",0,0
--+CGSOCKCONT: 2,"IP","","0.0.0.0",0,0
--+CGSOCKCONT: 3,"IP","","0.0.0.0",0,0
local get_gsockcont = function()
    local gsockcont_fields = {"client_id", "pdp_type", "apn", "pdp_addr", "compression", "header_compression"};
    local gsockcont_response = at.get_cgsockcont();
    local gsockcont_table = util.response_to_array(gsockcont_response, "+CGSOCKCONT: 1,", ":", ",", gsockcont_fields);
    util.print_simple_table("gsockcont_table", gsockcont_table);
    return gsockcont_table;
end;
_M.get_gsockcont = get_gsockcont

local get_sock_apn = function()
    local gsockcont_table = get_gsockcont()
    if gsockcont_table["apn"] then
        return gsockcont_table["apn"]
    end
    return ""
end
_M.get_sock_apn = get_sock_apn

return _M