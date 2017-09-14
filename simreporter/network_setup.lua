
at_abs = require "at_abs"
at = require "at_commands"
local _M = {}


local operator_to_network_setup = function(sim_operator)
    local network_table = {}
    local match_table = {}
    network_table["telstra"] = ',"IP","telstra.internet","0.0.0.0",0,0'
    network_table["optus"] = ',"IP","yesinternet","0.0.0.0",0,0'
    network_table["voda"] = ',"IP","live.vodafone.com","0.0.0.0",0,0'
    network_table["dtac"] = ',"IP","www.dtac.co.th","0.0.0.0",0,0'

    local fallback = ',"IP","internet","0.0.0.0",0,0'

    print("In*****************************\r\n")
    for operator, network_string in pairs(network_table) do
        print("operator: ", operator, "\r\n")
        if string.match(sim_operator:lower(), operator:lower()) then
            print("Found match for ", sim_operator, "\r\n")
            return network_string
        end
    end
    print("Operator not found, returning fall back parameters\r\n")
    return fallback
end


local set_operator_if_incorrect = function(sim_operator)
    local board_operator = at_abs.get_operator();
    if string.match(sim_operator, "Telstra") then
        if board_operator and board_operator["operator"] then
            print("Board operator is ", board_operator["operator"], "\r\n");
            if board_operator["operator"] == "50501" or string.match(board_operator["operator"],"Telstra") then
                print("Operator of Telstra already selected\r\n")
            else
                print("Setting telstra internet connectivity\r\n");
                --at.set_cops("0,2,50501");
                --at.set_cgsockcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0");
                --at.set_cgdcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0");
            end
        end
    end
    if string.match(sim_operator,"OPTUS") then
        if board_operator and board_operator["operator"] then
            print("Board operator is ", board_operator["operator"], "\r\n");
            if board_operator["operator"] == "50502" or string.match(board_operator["operator"],"OPTUS") or string.match(board_operator["operator"],"Optus") then
                print("Operator of Optus already selected\r\n")
            else
                print("Setting optus operator and internet connectivity\r\n");
                --at.set_cops("0,2,50502");
                --at.set_cgsockcont("1,\"IP\",\"yesinternet\",\"0.0.0.0\",0,0");
                --at.set_cgdcont("1,\"IP\",\"yesinternet\",\"0.0.0.0\",0,0");
            end
        end
    end
end;

local set_gdcont_if_incorrect = function(sim_operator)
    local apn = at_abs.get_data_apn();
    local sim_lower = string.lower(sim_operator);
    print("APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, "\r\n")
    local network_string = operator_to_network_setup(sim_operator)
    print("APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, ", network string: ", network_string, "\r\n")
    if string.match(apn, network_string) then
        print("Data APN already set to ", network_string, " for operator ", sim_operator, "\r\n");
    else
        print("Setting data APN to ", network_string, "\r\n");
        for i = 1,16 do
            at.set_cgdcont(i .. network_string);
        end;
    end
end;

local set_gsockcont_if_incorrect = function(sim_operator)
    local apn = at_abs.get_sock_apn();
    local sim_lower = string.lower(sim_operator);
    print("APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, "\r\n")
    local network_string = operator_to_network_setup(sim_operator)
    print("APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, ", network string: ", network_string, "\r\n")
    if string.match(apn, network_string) then
        print("Socket APN already set to ", network_string, " for operator ", sim_operator, "\r\n");
    else
        print("Setting socker APN to ", network_string, "\r\n");
        for i = 1,16 do
            at.set_cgsockcont(i .. network_string);
        end;
    end

end;

local set_network_from_sms_operator = function()
    local sim_operator = at_abs.get_sim_operator();
    print("sim operator is ", tostring(sim_operator), "\r\n");
    -- set_operator_if_incorrect(sim_operator);
    set_gdcont_if_incorrect(sim_operator);
    set_gsockcont_if_incorrect(sim_operator);
end
_M.set_network_from_sms_operator = set_network_from_sms_operator

return _M
