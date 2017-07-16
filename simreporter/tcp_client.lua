--require "chipsim"
--require "network"
--local socket = require("simsocket")

local _M = {}

local CLIENT_TO_APP_HANDLE = {}

function check_and_enable_network(app_handle)
    print("check_network_dorm_function, app_handle: " , app_handle, "\r\n");
    network_state = {};
    network_state.invalid = 0;
    network_state.down = 1;
    network_state.coming_up = 2;
    network_state.up = 4;
    network_state.going_down = 8;
    network_state.resuming = 16;
    network_state.going_null = 32;
    network_state.null = 64;
    local status = network.status(app_handle);
    print("network status = ", status, "\r\n");
    local safety_counter = 0;
    while (status ~= network_state.up) do
        if (status ~= network_state.resuming and status ~= network_state.coming_up) then
            print("Trying to bring network up\r\n");
            network.dorm(app_handle, false);
        else
            print("Network is already trying to come up\r\n");
        end;
        vmsleep(1000);
        status = network.status(app_handle)
        print("network status = ", status, "\r\n");
        if( safety_counter > 10 ) then
            return false;
        end;
        safety_counter = safety_counter + 1;
    end;
    print("Network state is up: ", status, "\r\n");
    return true;
end;

function set_network_dormant(app_handle)
    print("Setting network dormant\r\n")
    network.dorm(app_handle, false);
end;

function config_network_common_parameters()
    print("config_network_common_parameters\r\n");
    --The same with AT+CTCPKA
    result = network.set_tcp_ka_param(5, 1);--keep alive parameter, max 5 times, check every 1 minute if socket is idle.
    print("network.set_tcp_ka_param()=", result, "\r\n");
    --The same with AT+CIPCCFG
    result = network.set_tcp_retran_param(10, 10000);--maximum 10 retransmit times, minimum interval is 10 seconds.
    print("network.set_tcp_retran_param()=", result, "\r\n");
    --The same with AT+CIPDNSSET
    result = network.set_dns_timeout_param(0, 30000, 5);--network retry open times = 0(maximum is 3), network open timeout is 30 seconds, maximum DNS query times is 5
    print("network.set_dns_timeout_param()=", result, "\r\n");
end;

local make_http_post = function(host, url, data)
    print("Host is ", tostring(host), "\r\n");
    print("URL is ", tostring(url), "\r\n");
    print("data is ", tostring(data), "\r\n");
    local http_req = "";
    http_req = http_req .. "POST " .. tostring(url) .. " ";
    http_req = http_req .. "HTTP/1.1\r\nHost: ";
    http_req = http_req .. tostring(host);
    http_req = http_req .. "\r\n";
    http_req = http_req .. "User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\n";
    http_req = http_req .. "Authorization: bc733796ca38178dbee79f68ba4271e97fe170d4\r\n";
    http_req = http_req .. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\n";
    http_req = http_req .. "Accept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\n";
    http_req = http_req .. "Connection: close\r\n";
    http_req = http_req .. "Content-Length: " .. string.len(tostring(data)) .. "\r\n";
    http_req = http_req .. "\r\n";
    http_req = http_req .. tostring(data);

    return http_req;
end

local open_network = function(client_id)
    --Following is a sample of changing some common parameters, it is not required.
    --config_network_common_parameters();

    print("opening network...\r\n");
    -- local cid = 1;--0=>use setting of AT+CSOCKSETPN. 1-16=>use self defined cid
    local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
    local app_handle = network.open(client_id, timeout);--!!! If the PDP for cid is already opened by other app, this will return a reference to the same PDP context.
    if (not app_handle) then
        print("failed to open network\r\n");
        return;
    end;
    print("network.open(), app_handle=", app_handle, "\r\n");
    CLIENT_TO_APP_HANDLE[client_id] = app_handle;
    return app_handle;
end;
_M.open_network = open_network;

local client_id_to_app_handle = function(client_id)
    if CLIENT_TO_APP_HANDLE[client_id] then
        print("Using already created app_handle: ", CLIENT_TO_APP_HANDLE[client_id], "\r\n");
        return CLIENT_TO_APP_HANDLE[client_id];
    else
        local app_handle = open_network(client_id);
        print("Tried to create new app_handle: ", app_handle, "\r\n");
        if app_handle then
            CLIENT_TO_APP_HANDLE[client_id] = app_handle;
        end;
        return app_handle;
    end;
end;

--[[



error code definition



SOCK_RST_SOCK_FAILED and SOCK_RST_NETWORK_FAILED are fatal errors, 



when they happen, the socket cannot be used to transfer data further.



]]
local send_data = function(client_id, host, port, data)

    SOCK_RST_OK = 0
    SOCK_RST_TIMEOUT = 1
    SOCK_RST_BUSY = 2
    SOCK_RST_PARAMETER_WRONG = 3
    SOCK_RST_SOCK_FAILED = 4
    SOCK_RST_NETWORK_FAILED = 5
    local result = false;

    print ("Client id is: ", client_id, "\r\n");
    --local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    local app_handle = client_id_to_app_handle(client_id);
    print("App handle is: ", app_handle, "\r\n");
    if( not app_handle ) then
        print("No app handle. Send failed\r\n")
        return false;
    end;

    local network_is_up = check_and_enable_network(app_handle);
    if( not network_is_up ) then
        print("Network is not up. Send failed.\r\n");
        return false;
    end;

    local local_ip_addr = network.local_ip(app_handle);
    print("local ip address is ", local_ip_addr, "\r\n");

    local mtu_value = network.mtu(app_handle);
    print("MTU is ", mtu_value, " bytes\r\n");

    --[[



  If the client_id parameter is the same as the network.open(), the network.resolve() will use the same PDP activated using network.open(), 



  or else the network.resolve() will activate new PDP context by itself.



  ]]
    
    print("resolving DNS address...\r\n");
    local ip_address = network.resolve(host, cid);
    print("The IP address for ", host, " is ", ip_address, "\r\n");



    SOCK_TCP = 0;
    SOCK_UDP = 1;

    SOCK_WRITE_EVENT = 1
    SOCK_READ_EVENT = 2
    SOCK_CLOSE_EVENT = 4
    SOCK_ACCEPT_EVENT = 8

    local socket_fd = socket.create(app_handle, SOCK_TCP);
    if (not socket_fd or socket_fd < 1) then
        print("failed to create socket\r\n");
    elseif (ip_address) then
        --enable keep alive
        socket.keepalive(socket_fd, true);--this depends on network.set_tcp_ka_param() to set KEEP ALIVE interval and maximum check times.
        print("socket_fd=", socket_fd, "\r\n");
        print("connecting server...\r\n");
        local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
        local connect_result, socket_released = socket.connect(socket_fd, ip_address, port, timeout);
        --[[

    

     the socket_released indicates whether the socket handle has been released when failing to connect to the server.

    

     If socket_released is true, the socket.close() function needs not be called further. or else

    

     the socket.close() function still needs to be called to release the socket handle.

    

     ]]
        print("socket.connect = [result=", connect_result, ",socket_released=", socket_released, "]\r\n");
        if (not connect_result) then
            print("failed to connect server\r\n");
        else
            print("connect server succeeded\r\n");
            socket.select(socket_fd, SOCK_CLOSE_EVENT);--care for close event
            -- local http_req = "POST /process_update HTTP/1.1\r\nHost: www.scattym.com\r\nUser-Agent: Mozilla/5.0 (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\nKeep-Alive: 115\r\nConnection: keep-alive\r\n\r\n";
            print("socket.send..., len=", string.len(data), "\r\n");
            local timeout = 30000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds
            local err_code, sent_len = socket.send(socket_fd, data, timeout);
            print("socket.send ", err_code, ", ", sent_len, "\r\n");
            if (err_code and (err_code == SOCK_RST_OK)) then
                print("socket.recv()...\r\n");
                local timeout = 15000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds

                local err_code, http_rsp = socket.recv(socket_fd, timeout);
                print("socket.recv(), err_code=", err_code, "\r\n");
                if ((err_code == SOCK_RST_OK) and http_rsp) then
                    result = true;
                    if (printdir()) then
                        os.printstr(http_rsp);--this can print string larger than 1024 bytes, and also it can print string including '\0'.
                    end;
                    print("\r\n");
                else
                    print("failed to call socket.recv\r\n");
                end;
                print("\r\n");
            end;
        end;
        print("closing socket...\r\n");
        if (not socket_released and not socket.close(socket_fd)) then
            print("failed to close socket\r\n");
        else
            print("close socket succeeded\r\n");
        end;
    end;
    collectgarbage();
    return result;
end
_M.send_data = send_data;

local close_network = function(client_id)
    local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    if app_handle then
        set_network_dormant(app_handle);
        print("closing network...\r\n");
        local result = network.close(app_handle);
        print("network.close(), result=", result, "\r\n");
    else
        print("No app handle for client id: ", client_id, "\r\n")
    end;
    CLIENT_TO_APP_HANDLE[client_id] = nil
    return result;
end;
_M.close_network = close_network;

local open_send_close_tcp = function(client_id, host, port, data)

    app_handle = open_network(client_id)
    print("App handle is ", tostring(app_handle), "\r\n")
    if( app_handle ) then
        result = send_data(app_handle, host, port, data);
        close_network(app_handle);
        collectgarbage();
        return result;
    else
        print("Invalid app handle returned: ", app_handle, "\r\n");
    end;
    collectgarbage();
    return false;
end;

_M.open_send_close_tcp = open_send_close_tcp;

local http_open_send_close = function(client_id, host, port, url, data)

    if( client_id ) then
        result = send_data(client_id, host, port, make_http_post(host, url, data));
        collectgarbage();
        return result;
    else
        print("Invalid client id: ", client_id, "\r\n");
    end;
    collectgarbage();
    return false;
end;

_M.http_open_send_close = http_open_send_close;


return _M




