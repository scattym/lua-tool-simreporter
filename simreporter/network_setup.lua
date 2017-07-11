
at_abs = require "at_abs"
at = require "at_commands"

local _M = {}

local set_network_from_sms_operator = function()
    local operator = at_abs.get_sim_operator()
    print("operator is " .. tostring(operator))
    if string.match(operator, "Telstra") then
        print("Setting telstra internet connectivity")
        at.set_cgsockcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0")
        at.set_cgdcont("1,\"IP\",\"telstra.internet\",\"0.0.0.0\",0,0")
    end
    if string.match(operator,"OPTUS") then
        print("Setting optus internet connectivity")
        at.set_cgsockcont("1,\"IP\",\"yesinternet\",\"0.0.0.0\",0,0")
        at.set_cgdcont("1,\"IP\",\"yesinternet\",\"0.0.0.0\",0,0")
    end
end
_M.set_network_from_sms_operator = set_network_from_sms_operator

return _M
