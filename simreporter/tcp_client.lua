--require "chipsim"
--require "network"
--local socket = require("simsocket")
local logger = require("logging")
local aeslib = require("aes")

local _M = {}

local CLIENT_TO_APP_HANDLE = {}
logger.create_logger("tcp_client", 30)

function check_and_enable_network(app_handle)
    logger.log("tcp_client", 0, "check_network_dorm_function, app_handle: " , app_handle);
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
    logger.log("tcp_client", 0, "network status = ", status);
    local safety_counter = 0;
    while (status ~= network_state.up) do
        if (status ~= network_state.resuming and status ~= network_state.coming_up) then
            logger.log("tcp_client", 0, "Trying to bring network up");
            network.dorm(app_handle, false);
        else
            logger.log("tcp_client", 0, "Network is already trying to come up");
        end;
        vmsleep(1000);
        status = network.status(app_handle)
        logger.log("tcp_client", 0, "network status = ", status);
        if( safety_counter > 10 ) then
            return false;
        end;
        safety_counter = safety_counter + 1;
    end;
    logger.log("tcp_client", 0, "Network state is up: ", status);
    return true;
end;

function set_network_dormant(app_handle)
    logger.log("tcp_client", 0, "Setting network dormant")
    network.dorm(app_handle, false);
end;

function config_network_common_parameters()
    logger.log("tcp_client", 0, "config_network_common_parameters");
    --The same with AT+CTCPKA
    result = network.set_tcp_ka_param(5, 1);--keep alive parameter, max 5 times, check every 1 minute if socket is idle.
    logger.log("tcp_client", 0, "network.set_tcp_ka_param()=", result);
    --The same with AT+CIPCCFG
    result = network.set_tcp_retran_param(10, 10000);--maximum 10 retransmit times, minimum interval is 10 seconds.
    logger.log("tcp_client", 0, "network.set_tcp_retran_param()=", result);
    --The same with AT+CIPDNSSET
    result = network.set_dns_timeout_param(0, 30000, 5);--network retry open times = 0(maximum is 3), network open timeout is 30 seconds, maximum DNS query times is 5
    logger.log("tcp_client", 0, "network.set_dns_timeout_param()=", result);
end;

local make_http_post = function(host, url, data, headers)
    logger.log("tcp_client", 0, "Host is ", tostring(host));
    logger.log("tcp_client", 0, "URL is ", tostring(url));
    logger.log("tcp_client", 0, "data is ", tostring(data));
    local http_req = "";
    http_req = http_req .. "POST " .. tostring(url) .. " ";
    http_req = http_req .. "HTTP/1.1\r\nHost: ";
    http_req = http_req .. tostring(host);
    http_req = http_req .. "\r\n";
    http_req = http_req .. "User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\n";
    http_req = http_req .. "Authorization: bc733796ca38178dbee79f68ba4271e97fe170d4\r\n";
    http_req = http_req .. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\n";
    http_req = http_req .. "Accept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\n";
    for key, value in pairs(headers) do
        http_req = http_req .. key .. ": " .. value .. "\r\n"
    end
    http_req = http_req .. "Content-Type: application/octet-stream\r\n";
    http_req = http_req .. "Connection: close\r\n";
    http_req = http_req .. "Content-Length: " .. string.len(tostring(data)) .. "\r\n";
    http_req = http_req .. "\r\n";
    http_req = http_req .. tostring(data);

    return http_req;
end

local open_network = function(client_id)
    --Following is a sample of changing some common parameters, it is not required.
    --config_network_common_parameters();
    logger.log("tcp_client", 0, "opening network for client id " .. client_id);
    thread.enter_cs(5)
    -- local cid = 1;--0=>use setting of AT+CSOCKSETPN. 1-16=>use self defined cid
    local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
    local app_handle = network.open(client_id, timeout);--!!! If the PDP for cid is already opened by other app, this will return a reference to the same PDP context.
    if (not app_handle) then
        logger.log("tcp_client", 30, "failed to open network for client id " .. tostring(client_id));
        return;
    end;
    logger.log("tcp_client", 0, "network.open(), app_handle=", app_handle);
        CLIENT_TO_APP_HANDLE[client_id] = app_handle;
    thread.leave_cs(5)
    return app_handle;
end;
_M.open_network = open_network;

local client_id_to_app_handle = function(client_id, create_if_not_exists)
    local app_handle
    if CLIENT_TO_APP_HANDLE[client_id] then
        thread.enter_cs(5)
        logger.log("tcp_client", 0, "Using already created app_handle: ", CLIENT_TO_APP_HANDLE[client_id], " for client: ", client_id);
        app_handle = CLIENT_TO_APP_HANDLE[client_id];
        thread.leave_cs(5)
    elseif create_if_not_exists then
        local app_handle = open_network(client_id);
        logger.log("tcp_client", 0, "Tried to create new app_handle: ", app_handle);
    else
        logger.log("tcp_client", 0, "No app handle to return for client: ", client_id);
    end;
    return app_handle

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
    local response = ""

    logger.log("tcp_client", 0, "Client id is: ", client_id);
    --local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    local app_handle = client_id_to_app_handle(client_id, true);
    logger.log("tcp_client", 0, "App handle is: ", app_handle);
    if( not app_handle ) then
        logger.log("tcp_client", 30, "No app handle. Send failed")
        return false;
    end;

    local network_is_up = check_and_enable_network(app_handle);
    if( not network_is_up ) then
        logger.log("tcp_client", 30, "Network is not up. Send failed.");
        return false;
    end;

    local local_ip_addr = network.local_ip(app_handle);
    logger.log("tcp_client", 0, "local ip address is ", local_ip_addr);

    local mtu_value = network.mtu(app_handle);
    logger.log("tcp_client", 0, "MTU is ", mtu_value, " bytes");

    --[[



  If the client_id parameter is the same as the network.open(), the network.resolve() will use the same PDP activated using network.open(), 



  or else the network.resolve() will activate new PDP context by itself.



  ]]
    
    logger.log("tcp_client", 0, "resolving DNS address...\r\n");
    local ip_address = network.resolve(host, cid);
    logger.log("tcp_client", 0, "The IP address for ", host, " is ", ip_address);



    SOCK_TCP = 0;
    SOCK_UDP = 1;

    SOCK_WRITE_EVENT = 1
    SOCK_READ_EVENT = 2
    SOCK_CLOSE_EVENT = 4
    SOCK_ACCEPT_EVENT = 8

    local socket_fd = socket.create(app_handle, SOCK_TCP);

    if (not socket_fd or socket_fd < 1) then
        logger.log("tcp_client", 30, "failed to create socket. socket_fd is ", tostring(socket_fd));
    elseif (ip_address) then
        --enable keep alive
        socket.keepalive(socket_fd, true);--this depends on network.set_tcp_ka_param() to set KEEP ALIVE interval and maximum check times.
        logger.log("tcp_client", 0, "socket_fd=", socket_fd);
        logger.log("tcp_client", 0, "connecting server...");
        local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
        local connect_result, socket_released = socket.connect(socket_fd, ip_address, port, timeout);
        --[[

    

     the socket_released indicates whether the socket handle has been released when failing to connect to the server.

    

     If socket_released is true, the socket.close() function needs not be called further. or else

    

     the socket.close() function still needs to be called to release the socket handle.

    

     ]]
        logger.log("tcp_client", 0, "socket.connect = [result=", connect_result, ",socket_released=", socket_released, "]\r\n");
        if (not connect_result) then
            logger.log("tcp_client", 30, "failed to connect server");
        else
            logger.log("tcp_client", 0, "connect server succeeded");
            socket.select(socket_fd, SOCK_CLOSE_EVENT);--care for close event
            -- local http_req = "POST /process_update HTTP/1.1\r\nHost: www.scattym.com\r\nUser-Agent: Mozilla/5.0 (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\nKeep-Alive: 115\r\nConnection: keep-alive\r\n\r\n";
            logger.log("tcp_client", 0, "socket.send..., len=", string.len(data));
            local timeout = 30000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds
            local err_code, sent_len = socket.send(socket_fd, data, timeout);
            logger.log("tcp_client", 0, "socket.send ", err_code, ", ", sent_len);
            local http_resp = ""
            if (err_code and (err_code == SOCK_RST_OK)) then
                logger.log("tcp_client", 0, "socket.recv()...");
                local timeout = 15000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds

                while( err_code ~= SOCK_CLOSE_EVENT ) do
                    err_code, fragment = socket.recv(socket_fd, timeout);
                    logger.log("tcp_client", 0, "socket.recv(), err_code=", err_code);
                    if( fragment ) then
                        logger.log("tcp_client", 0, "Fragment is ", fragment)
                        response = response .. fragment
                    end
                end
                logger.log("tcp_client", 0, "c(", client_id , "):Error code is now: ", err_code)
                if ( response ) then
                    result = true;
                end;
            end;
        end;
        logger.log("tcp_client", 0, "closing socket...");
        if (not socket_released and not socket.close(socket_fd)) then
            logger.log("tcp_client", 30, "failed to close socket");
        else
            logger.log("tcp_client", 0, "close socket succeeded");
        end;
    end;
    collectgarbage();
    return result, response;
end
_M.send_data = send_data;

local close_network = function(client_id)
    local app_handle = client_id_to_app_handle(client_id, false)
    if app_handle then
        set_network_dormant(app_handle);
        logger.log("tcp_client", 0, "closing network...");
        local result = network.close(app_handle);
        logger.log("tcp_client", 0, "network.close(), result=", result);
    else
        logger.log("tcp_client", 30, "No app handle for client id: ", client_id)
    end;
    thread.enter_cs(5)
    CLIENT_TO_APP_HANDLE[client_id] = nil
    thread.leave_cs(5)
    return result;
end;
_M.close_network = close_network;

local open_send_close_tcp = function(client_id, host, port, data)

    app_handle = open_network(client_id)
    logger.log("tcp_client", 0, "App handle is ", tostring(app_handle))
    if( app_handle ) then
        result, response = send_data(app_handle, host, port, data);
        close_network(app_handle);
        collectgarbage();
        return result, response;
    else
        logger.log("tcp_client", 30, "Invalid app handle returned: ", app_handle);
    end;
    collectgarbage();
    return false, "";
end;

_M.open_send_close_tcp = open_send_close_tcp;

-- HTTP/1.0 500 INTERNAL SERVER ERROR
-- HTTP/1.0 200 OK
local parse_http_headers = function(response)
    local headers = {}
    headers["response_code"] = "000"
    for line in response:gmatch("([^\r\n]*)\r\n?") do
        logger.log("tcp_client", 0, "Line is ", line)

        local type, code, msg = line:match("([Hh][Tt][Tt][Pp]/[0-9].[0-9])%s+([0-9]*)%s+(.*)")
        if( type and code and msg ) then
            logger.log("tcp_client", 0, "Type: ", type, " code: ", code, " msg: ", msg)
            headers["response_code"] = code
        else
            for key, value in line:gmatch("(%S*):%s*(.*)") do
                logger.log("tcp_client", 0, "key is ", key, " value is ", value)
                if( key and value ) then
                    headers[key] = value
                end

            end
        end
    end
    logger.log("tcp_client", 0, "Finished parsing headers")
    collectgarbage()
    return headers
end

local function TotalLength(HeaderLength, ContentLength)
   return HeaderLength + ContentLength
end

-- Assume that Buff holds buffer to receive socket data
local parse_http_response = function (buffer)
    local payload = ""
    local _, HeaderLength = buffer:find('\r\n\r\n')
    local ContentLength = buffer:match("Content%-Length:%s(%d+)\r\n")
    if (not ContentLength or not HeaderLength) then
        logger.log("tcp_client", 30, 'Badly formed HTTP response.'..buffer)
        return {}, ""
    end
    local ExpectedLength = TotalLength(HeaderLength, ContentLength)
    if (#buffer < ExpectedLength) then
        logger.log("tcp_client", 30, "Bad content length field. Expected: ", ExpectedLength, " but got", #buffer)
        return {}, ""
    end


    logger.log("tcp_client", 0, "Preparing header buffer")
    local header_buf = buffer:sub(1, HeaderLength)
    logger.log("tcp_client", 0, "Parsing headers")
    local headers = parse_http_headers(header_buf)
    logger.log("tcp_client", 0, "Extracting payload")
    payload = buffer:sub(HeaderLength+1, HeaderLength+ContentLength)
    --logger.log("tcp_client", 0, "Payload is >", payload, "<\r\n")
    collectgarbage()
    return headers, payload
end


local http_open_send_close = function(client_id, host, port, url, data, headers, encrypt)
    if not headers then
        headers = {}
    end
    if encrypt then
        headers["encrypted"] = "true"
    end
    local payload = ""
    if encrypt and data ~= nil and data ~= "" then
        logger.log("tcp_client", 0, "About to encrypt payload");
        -- encrypt(password, data, keyLength, mode, iv)
        payload = aeslib.encrypt("password", data, aeslib.AES128, aeslib.CBCMODE)
        --payload = data
        logger.log("tcp_client", 0, "Encrypted payload is " .. tostring(payload));
    else
        payload = data
        logger.log("tcp_client", 0, "Not encrypting " .. tostring(payload));
    end

    if( not client_id ) then
        logger.log("tcp_client", 30, "Invalid client id: ", client_id);
    else
        logger.log("tcp_client", 20, "Callout to http://", host, ":", port, url)
        result, response = send_data(client_id, host, port, make_http_post(host, url, payload, headers));
        if( result and response ) then
            local headers, response_payload = parse_http_response(response);
            collectgarbage();
            return result, headers, response_payload;
        end
    end;
    collectgarbage();
    return false, "", "";
end;

_M.http_open_send_close = http_open_send_close;


return _M

