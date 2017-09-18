
at_abs = require "at_abs"
at = require "at_commands"
logging = require("logging")
local _M = {}

logger.create_logger("network_setup", 20)

local operator_to_network_setup = function(sim_operator)
    local network_table = {}
    local match_table = {}
    network_table["telstra"] = ',"IP","telstra.internet","0.0.0.0",0,0'
    network_table["optus"] = ',"IP","yesinternet","0.0.0.0",0,0'
    network_table["voda"] = ',"IP","live.vodafone.com","0.0.0.0",0,0'
    network_table["dtac"] = ',"IP","www.dtac.co.th","0.0.0.0",0,0'

    local fallback = ',"IP","internet","0.0.0.0",0,0'

    logger.log("network_setup", 0, "In*****************************")
    for operator, network_string in pairs(network_table) do
        logger.log("network_setup", 0, "operator: ", operator)
        if string.match(sim_operator:lower(), operator:lower()) then
            logger.log("network_setup", 0, "Found match for ", sim_operator)
            return network_string
        end
    end
    logger.log("network_setup", 30, "Operator not found, returning fall back parameters")
    return fallback
end


local set_operator_if_incorrect = function(sim_operator)
    local board_operator = at_abs.get_operator();
    if string.match(sim_operator, "Telstra") then
        if board_operator and board_operator["operator"] then
            logger.log("network_setup", 0, "Board operator is ", board_operator["operator"]);
            if board_operator["operator"] == "50501" or string.match(board_operator["operator"],"Telstra") then
                logger.log("network_setup", 0, "Operator of Telstra already selected")
            else
                logger.log("network_setup", 30, "Setting telstra internet connectivity");
                --at.set_cops("0,2,50501");
                --at.set_cgsockcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0");
                --at.set_cgdcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0");
            end
        end
    end
    if string.match(sim_operator,"OPTUS") then
        if board_operator and board_operator["operator"] then
            logger.log("network_setup", 0, "Board operator is ", board_operator["operator"]);
            if board_operator["operator"] == "50502" or string.match(board_operator["operator"],"OPTUS") or string.match(board_operator["operator"],"Optus") then
                logger.log("network_setup", 0, "Operator of Optus already selected")
            else
                logger.log("network_setup", 0, "Setting optus operator and internet connectivity");
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
    logger.log("network_setup", 0, "APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower)
    local network_string = operator_to_network_setup(sim_operator)
    logger.log("network_setup", 0, "APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, ", network string: ", network_string)
    if string.match(apn, network_string) then
        logger.log("network_setup", 0, "Data APN already set to ", network_string, " for operator ", sim_operator);
    else
        logger.log("network_setup", 20, "Setting data APN to ", network_string);
        for i = 1,16 do
            at.set_cgdcont(i .. network_string);
        end;
    end
end;

local set_gsockcont_if_incorrect = function(sim_operator)
    local apn = at_abs.get_sock_apn();
    local sim_lower = string.lower(sim_operator);
    logger.log("network_setup", 0, "APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower)
    local network_string = operator_to_network_setup(sim_operator)
    logger.log("network_setup", 0, "APN: ", apn, " sim op: ", sim_operator, " sim_op_lower: ", sim_lower, ", network string: ", network_string)
    if string.match(apn, network_string) then
        logger.log("network_setup", 0, "Socket APN already set to ", network_string, " for operator ", sim_operator);
    else
        logger.log("network_setup", 20, "Setting socket APN to ", network_string);
        for i = 1,16 do
            at.set_cgsockcont(i .. network_string);
        end;
    end

end;

local set_network_from_sms_operator = function()
    local sim_operator = at_abs.get_sim_operator();
    logger.log("network_setup", 0, "sim operator is ", tostring(sim_operator));
    -- set_operator_if_incorrect(sim_operator);
    set_gdcont_if_incorrect(sim_operator);
    set_gsockcont_if_incorrect(sim_operator);
end
_M.set_network_from_sms_operator = set_network_from_sms_operator

return _M
