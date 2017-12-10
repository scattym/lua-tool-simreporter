--require "chipsim"
--require "network"
--local socket = require("simsocket")
local logging = require("logging")
local aeslib = require("aes")
local rsa = require("rsa_lib")
local util = require("util")

local _M = {}

local CLIENT_TO_APP_HANDLE = {}
-- logger.create_logger("tcp_client", 30)
local logger = logging.create("tcp_client", 30)

local CLOSE_NETWORK_AFTER_TRANSFER = true

local DATA_HANDLER = {}

_M.SOCK_RST_OK = 0
_M.SOCK_RST_TIMEOUT = 1
_M.SOCK_RST_BUSY = 2
_M.SOCK_RST_PARAMETER_WRONG = 3
_M.SOCK_RST_SOCK_FAILED = 4
_M.SOCK_RST_NETWORK_FAILED = 5

_M.SOCK_TCP = 0;
_M.SOCK_UDP = 1;

_M.SOCK_WRITE_EVENT = 1
_M.SOCK_READ_EVENT = 2
_M.SOCK_CLOSE_EVENT = 4
_M.SOCK_ACCEPT_EVENT = 8

function check_and_enable_network(app_handle)
    logger(0, "check_network_dorm_function, app_handle: " , app_handle);
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
    logger(0, "network status = ", status);
    local safety_counter = 0;
    while (status ~= network_state.up) do
        if (status ~= network_state.resuming and status ~= network_state.coming_up) then
            logger(0, "Trying to bring network up");
            network.dorm(app_handle, false);
        else
            logger(0, "Network is already trying to come up");
        end;
        vmsleep(1000);
        status = network.status(app_handle)
        logger(0, "network status = ", status);
        if( safety_counter > 10 ) then
            logger(30, "Unable to bring network up after 10 attempts for app handle ", app_handle);
            return false;
        end;
        safety_counter = safety_counter + 1;
    end;
    logger(0, "Network state is up: ", status);
    return true;
end;

function set_network_dormant(app_handle, dormant_flag)
    logger(0, "Setting network dormant to: ", dormant_flag, " for app_handle: ", app_handle)
    network.dorm(app_handle, dormant_flag)
    thread.sleep(1000);
end;

function get_network_status(app_handle)
    local status = network.status(app_handle)
    logger(0, "Network status for app_handle: ", app_handle, " is ", status)
    return status
end

function config_network_common_parameters()
    logger(0, "config_network_common_parameters");
    --The same with AT+CTCPKA
    result = network.set_tcp_ka_param(5, 1);--keep alive parameter, max 5 times, check every 1 minute if socket is idle.
    logger(0, "network.set_tcp_ka_param()=", result);
    --The same with AT+CIPCCFG
    result = network.set_tcp_retran_param(10, 10000);--maximum 10 retransmit times, minimum interval is 10 seconds.
    logger(0, "network.set_tcp_retran_param()=", result);
    --The same with AT+CIPDNSSET
    result = network.set_dns_timeout_param(0, 30000, 5);--network retry open times = 0(maximum is 3), network open timeout is 30 seconds, maximum DNS query times is 5
    logger(0, "network.set_dns_timeout_param()=", result);
end;

local make_http_post = function(host, url, data, headers)
    logger(0, "Host is ", tostring(host));
    logger(0, "URL is ", tostring(url));
    logger(0, "data is ", tostring(data));
    local http_req = "";
    local data_length = 0
    if data ~= nil then
        data_length = tostring(#data)
    end
    http_req = http_req .. "POST " .. tostring(url) .. " ";
    http_req = http_req .. "HTTP/1.1\r\nHost: ";
    http_req = http_req .. tostring(host);
    http_req = http_req .. "\r\n";
    http_req = http_req .. "User-Agent: SimCom/1.0\r\n" -- (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\n";
    http_req = http_req .. "Authorization: bc733796ca38178dbee79f68ba4271e97fe170d4\r\n";
    http_req = http_req .. "Accept: text/html\r\n" -- ,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\n";
    -- http_req = http_req .. "Accept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\n";
    for key, value in pairs(headers) do
        http_req = http_req .. key .. ": " .. value .. "\r\n"
    end
    http_req = http_req .. "Content-Type: application/octet-stream\r\n";
    http_req = http_req .. "Connection: close\r\n";
    http_req = http_req .. "Content-Length: " .. data_length .. "\r\n";
    http_req = http_req .. "\r\n";
    http_req = http_req .. tostring(data);

    return http_req;
end

local make_http_post_headers = function(host, url, length, headers)
    logger(0, "Host is ", tostring(host));
    logger(0, "URL is ", tostring(url));
    logger(0, "data is ", tostring(data));
    local http_req = "";
    http_req = http_req .. "POST " .. tostring(url) .. " ";
    http_req = http_req .. "HTTP/1.1\r\nHost: ";
    http_req = http_req .. tostring(host);
    http_req = http_req .. "\r\n";
    http_req = http_req .. "User-Agent: SimCom/1.0\r\n" -- (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\n";
    http_req = http_req .. "Authorization: bc733796ca38178dbee79f68ba4271e97fe170d4\r\n";
    http_req = http_req .. "Accept: text/html\r\n" --,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\n";
    --http_req = http_req .. "Accept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\n";
    for key, value in pairs(headers) do
        http_req = http_req .. key .. ": " .. value .. "\r\n"
    end
    http_req = http_req .. "Content-Type: application/octet-stream\r\n";
    http_req = http_req .. "Connection: close\r\n";
    http_req = http_req .. "Content-Length: " .. length .. "\r\n";
    http_req = http_req .. "\r\n";

    return http_req;
end

local open_network = function(client_id)
    --Following is a sample of changing some common parameters, it is not required.
    --config_network_common_parameters();
    logger(0, "opening network for client id " .. client_id);
    thread.enter_cs(5)
    -- local cid = 1;--0=>use setting of AT+CSOCKSETPN. 1-16=>use self defined cid
    local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
    local app_handle = network.open(client_id, timeout);--!!! If the PDP for cid is already opened by other app, this will return a reference to the same PDP context.
    -- set_network_dormant(app_handle, false);
    if (not app_handle) then
        logger(30, "failed to open network for client id " .. tostring(client_id));
    else
        logger(0, "network.open(), app_handle=", app_handle);
        CLIENT_TO_APP_HANDLE[client_id] = app_handle;
    end
    thread.leave_cs(5)
    return app_handle;
end;
_M.open_network = open_network;

local function get_current_app_handle_maybe(client_id)
    local app_handle
    thread.enter_cs(5)
    if CLIENT_TO_APP_HANDLE[client_id] then
        logger(0, "Using already created app_handle: ", CLIENT_TO_APP_HANDLE[client_id], " for client: ", client_id);
        app_handle = CLIENT_TO_APP_HANDLE[client_id]
    else
        logger(0, "No current app handle for client id: ", client_id);
    end
    thread.leave_cs(5)
    return app_handle
end

local client_id_to_app_handle = function(client_id, create_if_not_exists)
    local app_handle

    app_handle = get_current_app_handle_maybe(client_id)
    logger(0, "App hande returned from get_current_app_handle_maybe: ", app_handle)
    if app_handle == nil then
        if create_if_not_exists then
            logger(0, "Trying to create an app handle for client id: ", client_id)
            app_handle = open_network(client_id);
            logger(0, "open network resulting app handle is: ", app_handle);
        else
            logger(0, "Not trying to create as create_if_not_exists is: ", create_if_not_exists)
        end
    else
        logger(0, "App handle for client id: ", client_id, " found and is: ", app_handle)
    end
    return app_handle

end;

local send_all = function(socket_fd, data, timeout)
    local try_count = 0
    local sent = 0
    local err_code = 0
    while sent < #data do
        local sent_len
        local bytes_to_send = #data-sent
        if bytes_to_send > 1300 then
            bytes_to_send = 1300
        end
        local end_byte = sent + bytes_to_send
        logger(0, "Bytes to send is ", bytes_to_send, " end byte is ", end_byte, " bytes sent so far is ", sent, " err_code is ", err_code, " data length is ", #data, " data length minus sent ", #data-sent)
        err_code, sent_len = socket.send(socket_fd, data:sub(sent+1, end_byte), timeout);
        sent = sent + sent_len
        logger(0, "Bytes sent so far is ", sent, " err_code is ", err_code)
        if err_code ~= 0 then
            return err_code, sent_len
        end
        thread.sleep(100)
    end
    return err_code, sent
end

local connect_host = function(client_id, host, port)

    SOCK_RST_OK = 0
    SOCK_RST_TIMEOUT = 1
    SOCK_RST_BUSY = 2
    SOCK_RST_PARAMETER_WRONG = 3
    SOCK_RST_SOCK_FAILED = 4
    SOCK_RST_NETWORK_FAILED = 5
    local result = false;
    local response = ""

    logger(0, "Client id is: ", client_id);
    --local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    local app_handle = client_id_to_app_handle(client_id, true);
    logger(0, "App handle is: ", app_handle);
    if( not app_handle ) then
        logger(30, "No app handle. Send failed")
        return false;
    end;

    local network_is_up = check_and_enable_network(app_handle);
    if( not network_is_up ) then
        logger(30, "Network is not up. Send failed.");
        return false;
    end;

    local local_ip_addr = network.local_ip(app_handle);
    logger(0, "local ip address is ", local_ip_addr);

    local mtu_value = network.mtu(app_handle);
    logger(0, "MTU is ", mtu_value, " bytes");

    --[[

  If the client_id parameter is the same as the network.open(), the network.resolve() will use the same PDP activated using network.open(),
  or else the network.resolve() will activate new PDP context by itself.

  ]]

    logger(0, "resolving DNS address...\r\n");
    local ip_address = network.resolve(host, cid);
    logger(0, "The IP address for ", host, " is ", ip_address);



    SOCK_TCP = 0;
    SOCK_UDP = 1;

    SOCK_WRITE_EVENT = 1
    SOCK_READ_EVENT = 2
    SOCK_CLOSE_EVENT = 4
    SOCK_ACCEPT_EVENT = 8

    local socket_fd = socket.create(app_handle, SOCK_TCP);

    if (not socket_fd or socket_fd < 1) then
        logger(30, "failed to create socket for app handle: ", app_handle, " socket_fd is ", tostring(socket_fd));
    elseif (ip_address) then
        --enable keep alive
        socket.keepalive(socket_fd, true);--this depends on network.set_tcp_ka_param() to set KEEP ALIVE interval and maximum check times.
        logger(0, "socket_fd=", socket_fd);
        logger(0, "connecting server...");
        local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
        local connect_result, socket_released = socket.connect(socket_fd, ip_address, port, timeout);
        --[[

         the socket_released indicates whether the socket handle has been released when failing to connect to the server.
         If socket_released is true, the socket.close() function needs not be called further. or else
         the socket.close() function still needs to be called to release the socket handle.

         ]]
        logger(0, "socket.connect = [result=", connect_result, ",socket_released=", socket_released, "]\r\n");
        if (not connect_result) then
            logger(30, "failed to connect server");
            if (not socket_released and not socket.close(socket_fd)) then
                logger(30, "failed to close socket");
            else
                logger(0, "close socket succeeded");
            end;
            result = false
            socket_fd = -1
        else
            result = true
        end
    end;

    return result, socket_fd;
end
_M.connect_host = connect_host


local READ_EVENT_HANDLER = {}
local set_read_event_handler = function(socket, handler)
    READ_EVENT_HANDLER[socket] = handler
end

local wait_read_events = function(timeout)
    local remote_closed = false;
    logger(0, "wait_read_event, sockfd=", sockfd, ", timeout=", timeout, "\r\n");
    local start_tick = os.clock();
    while (true) do
        local cur_tick = os.clock();
        timeout = timeout - (cur_tick - start_tick)*1000;
        if (timeout < 0) then
            timeout = 0;
        end;
        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(timeout);
        if (evt and evt >= 0) then
            logger(0, "waited evt: ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
        end;
        if (evt and evt == SOCKET_EVENT) then
            local sock_or_net_event = evt_p1;--0=>network event, usually ("LOST NETWORK"); 1=>socket event.
            local evt_sockfd = evt_p2;
            local event_mask = evt_p3;
            for socket, handler in pairs(READ_EVENT_HANDLER) do
                if ((sock_or_net_event == 1) and (evt_sockfd == socket) and (bit.band(event_mask,SOCK_CLOSE_EVENT) ~= 0)) then
                    --socket closed by remote side
                    remote_closed = true;
                    logger(0, "waited event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
                    if (not socket.close(socket_fd)) then
                        logger(30, "1: failed to close socket");
                    else
                        logger(0, "1: close socket succeeded");
                    end;
                    return false, remote_closed;
                elseif ((sock_or_net_event == 1) and (evt_sockfd == sockfd) and (bit.band(event_mask,SOCK_READ_EVENT) ~= 0)) then
                    logger(0, "waited READ event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
                    local err_code, fragment = socket.recv(socket_fd, timeout)
                    if( fragment ) then
                        logger(0, "Fragment is ", fragment)
                        handler(fragment)
                    end
                    if( err_code == SOCK_CLOSE_EVENT ) then
                        if (not socket.close(socket_fd)) then
                            logger(30, "2: failed to close socket");
                        else
                            logger(0, "2: close socket succeeded");
                        end;
                    end

                end;

            end

        end;
    end;
end;
_M.wait_read_events = wait_read_events

local wait_read_event = function(sockfd, timeout)
    thread.setevtowner(22,22)
    thread.setevtowner(40,40)

    local SOCKET_EVENT = 22
    local SOCK_WRITE_EVENT = 1
    local SOCK_READ_EVENT = 2
    local SOCK_CLOSE_EVENT = 4
    local remote_closed = false;
    logger(0, "wait_read_event, sockfd=", sockfd, ", timeout=", timeout, "\r\n");
    local start_tick = os.clock();
    while (true) do
        local cur_tick = os.clock();
        timeout = timeout - (cur_tick - start_tick)*1000;
        if (timeout < 0) then
            timeout = 0;
        end;
        socket.select(sockfd, SOCK_CLOSE_EVENT);--care for read event, IMPORTANT!!! this will let socket notify READ event.
        socket.select(sockfd, SOCK_READ_EVENT);--care for read event, IMPORTANT!!! this will let socket notify READ event.
        socket.deselect(sockfd, SOCK_WRITE_EVENT);--care for read event, IMPORTANT!!! this will let socket notify READ event.

        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(timeout);
        if (evt and evt >= 0) then
            logger(30, "waited evt: ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
        end;
        if (evt and evt == SOCKET_EVENT) then
            logger(0, "Event is a socket event\r\n")
            local sock_or_net_event = evt_p1;--0=>network event, usually ("LOST NETWORK"); 1=>socket event.
            local evt_sockfd = evt_p2;
            local event_mask = evt_p3;
            if ((sock_or_net_event == 1) and (evt_sockfd == sockfd) and (bit.band(event_mask,SOCK_CLOSE_EVENT) ~= 0)) then
                --socket closed by remote side
                logger(30, "Socket closed by remote side\r\n")
                logger(0, "waited event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
                return true, false, true;
            elseif ((sock_or_net_event == 1) and (evt_sockfd == sockfd) and (bit.band(event_mask,SOCK_READ_EVENT) ~= 0)) then
                logger(0, "waited READ event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
                return true, false, false;
            else
                logger(0, "Not socket read or close event\r\n")
            end;
        elseif evt and evt == 40 and evt_p1 and evt_p1 == sockfd then
            return false, true, false
        end;
        local cur_tick = os.clock();
        if ((cur_tick - start_tick)*1000 >= timeout) then
            break;
        end;
    end;
    return false, false, remote_closed;
end;
_M.wait_read_event = wait_read_event

local send = function(sockfd, data)
    return true
end

--[[
error code definition
SOCK_RST_SOCK_FAILED and SOCK_RST_NETWORK_FAILED are fatal errors,
when they happen, the socket cannot be used to transfer data further.
]]
local send_data = function(client_id, host, port, ...)

    SOCK_RST_OK = 0
    SOCK_RST_TIMEOUT = 1
    SOCK_RST_BUSY = 2
    SOCK_RST_PARAMETER_WRONG = 3
    SOCK_RST_SOCK_FAILED = 4
    SOCK_RST_NETWORK_FAILED = 5
    local result = false;
    local response = ""

    logger(0, "Client id is: ", client_id);
    --local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    local app_handle = client_id_to_app_handle(client_id, true);
    logger(0, "App handle is: ", app_handle);
    if( not app_handle ) then
        logger(30, "No app handle. Send failed")
        return false;
    end;

    local network_is_up = check_and_enable_network(app_handle);
    if( not network_is_up ) then
        logger(30, "Network is not up. Send failed.");
        return false;
    end;

    local local_ip_addr = network.local_ip(app_handle);
    logger(0, "local ip address is ", local_ip_addr);

    local mtu_value = network.mtu(app_handle);
    logger(0, "MTU is ", mtu_value, " bytes");

    --[[

  If the client_id parameter is the same as the network.open(), the network.resolve() will use the same PDP activated using network.open(), 
  or else the network.resolve() will activate new PDP context by itself.

  ]]
    
    logger(0, "resolving DNS address...\r\n");
    local ip_address = network.resolve(host, cid);
    logger(0, "The IP address for ", host, " is ", ip_address);



    SOCK_TCP = 0;
    SOCK_UDP = 1;

    SOCK_WRITE_EVENT = 1
    SOCK_READ_EVENT = 2
    SOCK_CLOSE_EVENT = 4
    SOCK_ACCEPT_EVENT = 8

    local socket_fd = socket.create(app_handle, SOCK_TCP);

    if (not socket_fd or socket_fd < 1) then
        logger(30, "failed to create socket for app handle: ", app_handle, " socket_fd is ", tostring(socket_fd));
    elseif (ip_address) then
        --enable keep alive
        socket.keepalive(socket_fd, true);--this depends on network.set_tcp_ka_param() to set KEEP ALIVE interval and maximum check times.
        logger(0, "socket_fd=", socket_fd);
        logger(0, "connecting server...");
        local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
        local connect_result, socket_released = socket.connect(socket_fd, ip_address, port, timeout);
        --[[

     the socket_released indicates whether the socket handle has been released when failing to connect to the server.
     If socket_released is true, the socket.close() function needs not be called further. or else
     the socket.close() function still needs to be called to release the socket handle.

     ]]
        logger(0, "socket.connect = [result=", connect_result, ",socket_released=", socket_released, "]\r\n");
        if (not connect_result) then
            logger(30, "failed to connect server");
        else
            logger(0, "connect server succeeded");
            socket.select(socket_fd, SOCK_CLOSE_EVENT);--care for close event
            -- local http_req = "POST /process_update HTTP/1.1\r\nHost: www.scattym.com\r\nUser-Agent: Mozilla/5.0 (Windows NT 5.1; rv:2.0) Gecko/20100101 Firefox/4.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: zh-cn,zh;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nAccept-Charset: GB2312,utf-8;q=0.7,*;q=0.7\r\nKeep-Alive: 115\r\nConnection: keep-alive\r\n\r\n";
            local timeout = 30000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds
            local total_length = 0
            local total_sent_length = 0
            local err_code = 0
            for i, value in ipairs(arg) do
                if value ~= nil and value ~= "" then
                    total_length = total_length + #value
                    local sent_len = 0
                    err_code, sent_len = socket.send(socket_fd, value, timeout);
                    total_sent_length = total_sent_length + sent_len
                end
            end
            if total_sent_length < total_length then
                logger(30, "Not all data sent. err_code:", err_code, ", sent_len:", total_sent_length, ", data length:", #total_length);
            end
            logger(0, "socket.send ", err_code, ", ", total_sent_length);
            local http_resp = ""
            if (err_code and (err_code == SOCK_RST_OK)) then
                logger(0, "socket.recv()...");
                local timeout = 15000;--  '< 0' means wait for ever; '0' means not wait; '> 0' is the timeout milliseconds

                while( err_code == 0 ) do -- ~= SOCK_CLOSE_EVENT ) do
                    logger(0, "Error code is ", err_code)
                    local fragment = ""
                    err_code, fragment = socket.recv(socket_fd, timeout);
                    logger(0, "socket.recv(), err_code=", err_code);
                    if( fragment ) then
                        logger(0, "Fragment is ", fragment)
                        response = response .. fragment
                    end
                end
                logger(0, "c(", client_id , "):Error code is now: ", err_code)
                if ( response ) then
                    result = true;
                end
            else
                logger(30, "Error code is not as expected. err_code: ", err_code, " expecting: ", SOCK_RST_OK)
            end;
        end;
        logger(0, "closing socket...");
        if (not socket_released and not socket.close(socket_fd)) then
            logger(30, "failed to close socket");
        else
            logger(0, "close socket succeeded");
        end;
    end;
    collectgarbage();
    return result, response;
end
_M.send_data = send_data;

local close_network = function(client_id)
    local app_handle = client_id_to_app_handle(client_id, false)
    local result
    local status
    if app_handle then
        set_network_dormant(app_handle, true);
        status = network.status(app_handle);
        logger(0, "network status before close is ", tostring(status));
        if CLOSE_NETWORK_AFTER_TRANSFER then
            logger(0, "closing network for app_handle: ", app_handle);
            result = network.close(app_handle);
            logger(0, "network.close(), result=", result);
            thread.enter_cs(5)
            CLIENT_TO_APP_HANDLE[client_id] = nil
            thread.leave_cs(5)
        else
            logger(0, "Not closing network as CLOSE_NETWORK_AFTER_TRANSFER set to: ", CLOSE_NETWORK_AFTER_TRANSFER)
        end
        status = network.status(app_handle);
        logger(0, "network status after close is ", tostring(status));
    else
        logger(30, "No app handle for client id: ", client_id)
    end;
    -- App handle seems to be getting lost. Don't drop it for now.
    return result;
end;
_M.close_network = close_network;

local open_send_close_tcp = function(client_id, host, port, data)

    app_handle = open_network(client_id)
    logger(0, "App handle is ", tostring(app_handle))
    if( app_handle ) then
        result, response = send_data(app_handle, host, port, data);
        close_network(app_handle);
        collectgarbage();
        return result, response;
    else
        logger(30, "Invalid app handle returned: ", app_handle);
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
    if not response then
        logger(30, "Did not get a header string to parse. Response is nil.")
    else
        for line in response:gmatch("([^\r\n]*)\r\n?") do
            logger(0, "Line is ", line)

            local type, code, msg = line:match("([Hh][Tt][Tt][Pp]/[0-9].[0-9])%s+([0-9]*)%s+(.*)")
            if( type and code and msg ) then
                logger(0, "Type: ", type, " code: ", code, " msg: ", msg)
                headers["response_code"] = code
            else
                for key, value in line:gmatch("(%S*):%s*(.*)") do
                    logger(0, "key is ", key, " value is ", value)
                    if( key and value ) then
                        headers[key] = value
                    end

                end
            end
        end
    end
    logger(0, "Finished parsing headers")
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
        logger(30, 'Badly formed HTTP response.'..buffer)
        return {}, ""
    end
    local ExpectedLength = TotalLength(HeaderLength, ContentLength)
    if (#buffer < ExpectedLength) then
        logger(30, "Bad content length field. Expected: ", ExpectedLength, " but got", #buffer)
        return {}, ""
    end


    logger(0, "Preparing header buffer")
    local header_buf = buffer:sub(1, HeaderLength)
    logger(0, "Parsing headers")
    local headers = parse_http_headers(header_buf)
    logger(0, "Extracting payload")
    payload = buffer:sub(HeaderLength+1, HeaderLength+ContentLength)
    --logger(0, "Payload is >", payload, "<\r\n")
    collectgarbage()
    return headers, payload
end


local http_open_send_close = function(client_id, host, port, url, data, headers, encrypt)
    if data == nil then
        data = ""
    end
    if not headers then
        headers = {}
    end
    if type(encrypt) == "boolean" and encrypt == true then
        headers["encrypted"] = "true"
    end
    if type(encrypt) == "table" and encrypt["key"] ~= nil and encrypt["enc_key"] ~= nil then
        headers["iv"] = rsa.num_to_hex(encrypt["iv"])
        headers["sk"] = rsa.num_to_hex(encrypt["enc_key"])
        headers["encrypted"] = "true"
    end

    local payload = ""
    if encrypt ~= false and data ~= nil and data ~= "" then

        logger(0, "About to encrypt payload: ", data);
        collectgarbage()
        payload = aeslib.encrypt("password", data, aeslib.AES128, aeslib.CBCMODE)
        logger(0, "Encrypted payload is ", util.tohex(payload));
        logger(10, "Encrypted payload length is ", #payload);
        collectgarbage()

    else

        payload = data
        logger(0, "Not encrypting ", tostring(payload));

    end
    local payload_length = 0
    if payload ~= nil then
        payload_length = #payload
    end

    if( not client_id ) then
        logger(30, "Invalid client id: ", client_id);
    else
        logger(20, "Callout to http://", host, ":", port, url)
        logger(20, "Length is ", payload_length)
        local http_preamble = make_http_post_headers(host, url, payload_length, headers)
        local result, response = send_data(client_id, host, port, http_preamble, payload)
        logger(10, "Response is ", response)
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
