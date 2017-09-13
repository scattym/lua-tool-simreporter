--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 12/9/17
-- Time: 5:21 PM
-- To change this template use File | Settings | File Templates.
--

local _M = {}

local client_id = 3;
printdir(1)
print("In basic threads. Trying to load libraries.\r\n")

local tcp = require("tcp_client")

local get_firmware_version = function()
    print("Trying to retrieve firmware version\r\n");
    while (true) do
        local open_net_result = tcp.open_network(client_id);
        print("Open network response is: ", open_net_result, "\r\n");
        local result = tcp.http_open_send_close(client_id, "services.do.scattym.com", 65535, "/get_firmware_version", "");
        print("Result is ", result, "\r\n")
        tcp.close_network(client_id);
    end
    collectgarbage();
end

_M.get_firmware_version = get_firmware_version

return _M



