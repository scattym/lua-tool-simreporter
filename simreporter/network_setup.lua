
at_abs = require "at_abs"
at = require "at_commands"

local _M = {}

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
    if string.match(sim_operator, "Telstra") then
        if string.match(apn,"telstra.internet") then
            print("Data APN already set to telstra.internet for operator ", sim_operator, "\r\n");
            
        else
            print("Setting data APN to telstra.internet\r\n");
            for i = 1,16 do
                at.set_cgdcont(i .. ',"IP","telstra.internet","0.0.0.0",0,0');
            end;
        end;
    elseif string.match(sim_operator,"OPTUS") then
        if string.match(apn,"yesinternet") then
            print("Data APN already set to yesinternet for operator ", sim_operator, "\r\n");
        else
            print("Setting data APN to yesinternet\r\n");
            for i = 1,16 do
                at.set_cgdcont(i .. ',"IP","yesinternet","0.0.0.0",0,0');
            end;
        end;
    else
        if string.match(apn,"\"internet\"") then
            print("Data APN already set to internet for operator ", sim_operator, "\r\n");
        else
            print("Setting data APN to internet\r\n");
            for i = 1,16 do
                at.set_cgdcont(i .. ',"IP","internet","0.0.0.0",0,0');
            end;
        end;
    end

end;

local set_gsockcont_if_incorrect = function(sim_operator)
    local apn = at_abs.get_sock_apn();
    if string.match(sim_operator, "Telstra") then
        if string.match(apn,"telstra.internet") then
            print("Socket APN already set to telstra.internet for operator ", sim_operator, "\r\n");
            
        else
            print("Setting socket APN to telstra.internet\r\n");
            for i = 1,16 do
                at.set_cgsockcont(i .. ',"IP","telstra.internet","0.0.0.0",0,0');
            end;
        end;
    elseif string.match(sim_operator,"OPTUS") then
        if string.match(apn,"yesinternet") then
            print("Socket APN already set to yesinternet for operator ", sim_operator, "\r\n");
        else
            print("Setting socket APN to yesinternet\r\n");
            for i = 1,16 do
                at.set_cgsockcont(i .. ',"IP","yesinternet","0.0.0.0",0,0');
            end;
        end;
    else
        if string.match(apn,"internet") then
            print("Socket APN already set to internet for operator ", sim_operator, "\r\n");
        else
            print("Setting socket APN to internet\r\n");
            for i = 1,16 do
                at.set_cgsockcont(i .. ',"IP","internet","0.0.0.0",0,0');
            end;
        end;
    end

end;

local set_network_from_sms_operator = function()
    local sim_operator = at_abs.get_sim_operator();
    print("sim operator is ", tostring(sim_operator), "\r\n");
    set_operator_if_incorrect(sim_operator);
    set_gdcont_if_incorrect(sim_operator);
    set_gsockcont_if_incorrect(sim_operator);
end
_M.set_network_from_sms_operator = set_network_from_sms_operator

return _M
