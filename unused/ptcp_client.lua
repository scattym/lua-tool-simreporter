--require "chipsim"
--require "network"
--local socket = require("simsocket")
local logger = require("logging")
local aeslib = require("aes")
local big_int = require("BigInt")
local util = require("util")

local _M = {}

local CLIENT_TO_APP_HANDLE = {}
logger.create_logger("ptcp_client", 0)

local CLOSE_NETWORK_AFTER_TRANSFER = true

function check_and_enable_network(app_handle)
    logger.log("ptcp_client", 0, "check_network_dorm_function, app_handle: " , app_handle);
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
    logger.log("ptcp_client", 0, "network status = ", status);
    local safety_counter = 0;
    while (status ~= network_state.up) do
        if (status ~= network_state.resuming and status ~= network_state.coming_up) then
            logger.log("ptcp_client", 0, "Trying to bring network up");
            network.dorm(app_handle, false);
        else
            logger.log("ptcp_client", 0, "Network is already trying to come up");
        end;
        vmsleep(1000);
        status = network.status(app_handle)
        logger.log("ptcp_client", 0, "network status = ", status);
        if( safety_counter > 10 ) then
            logger.log("ptcp_client", 30, "Unable to bring network up after 10 attempts for app handle ", app_handle);
            return false;
        end;
        safety_counter = safety_counter + 1;
    end;
    logger.log("ptcp_client", 0, "Network state is up: ", status);
    return true;
end;

function set_network_dormant(app_handle, dormant_flag)
    logger.log("ptcp_client", 0, "Setting network dormant to: ", dormant_flag, " for app_handle: ", app_handle)
    network.dorm(app_handle, dormant_flag)
    thread.sleep(1000);
end;

function get_network_status(app_handle)
    local status = network.status(app_handle)
    logger.log("ptcp_client", 0, "Network status for app_handle: ", app_handle, " is ", status)
    return status
end

function config_network_common_parameters()
    logger.log("ptcp_client", 0, "config_network_common_parameters");
    --The same with AT+CTCPKA
    result = network.set_tcp_ka_param(5, 1);--keep alive parameter, max 5 times, check every 1 minute if socket is idle.
    logger.log("ptcp_client", 0, "network.set_tcp_ka_param()=", result);
    --The same with AT+CIPCCFG
    result = network.set_tcp_retran_param(10, 10000);--maximum 10 retransmit times, minimum interval is 10 seconds.
    logger.log("ptcp_client", 0, "network.set_tcp_retran_param()=", result);
    --The same with AT+CIPDNSSET
    result = network.set_dns_timeout_param(0, 30000, 5);--network retry open times = 0(maximum is 3), network open timeout is 30 seconds, maximum DNS query times is 5
    logger.log("ptcp_client", 0, "network.set_dns_timeout_param()=", result);
end;

local open_network = function(client_id)
    --Following is a sample of changing some common parameters, it is not required.
    --config_network_common_parameters();
    logger.log("ptcp_client", 0, "opening network for client id " .. client_id);
    thread.enter_cs(5)
    -- local cid = 1;--0=>use setting of AT+CSOCKSETPN. 1-16=>use self defined cid
    local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
    local app_handle = network.open(client_id, timeout);--!!! If the PDP for cid is already opened by other app, this will return a reference to the same PDP context.
    -- set_network_dormant(app_handle, false);
    if (not app_handle) then
        logger.log("ptcp_client", 30, "failed to open network for client id " .. tostring(client_id));
    else
        logger.log("ptcp_client", 0, "network.open(), app_handle=", app_handle);
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
        logger.log("ptcp_client", 0, "Using already created app_handle: ", CLIENT_TO_APP_HANDLE[client_id], " for client: ", client_id);
        app_handle = CLIENT_TO_APP_HANDLE[client_id]
    else
        logger.log("ptcp_client", 0, "No current app handle for client id: ", client_id);
    end
    thread.leave_cs(5)
    return app_handle
end

local client_id_to_app_handle = function(client_id, create_if_not_exists)
    local app_handle

    app_handle = get_current_app_handle_maybe(client_id)
    logger.log("ptcp_client", 0, "App hande returned from get_current_app_handle_maybe: ", app_handle)
    if app_handle == nil then
        if create_if_not_exists then
            logger.log("ptcp_client", 0, "Trying to create an app handle for client id: ", client_id)
            app_handle = open_network(client_id);
            logger.log("ptcp_client", 0, "open network resulting app handle is: ", app_handle);
        else
            logger.log("ptcp_client", 0, "Not trying to create as create_if_not_exists is: ", create_if_not_exists)
        end
    else
        logger.log("ptcp_client", 0, "App handle for client id: ", client_id, " found and is: ", app_handle)
    end
    return app_handle

end;

--[[
error code definition
SOCK_RST_SOCK_FAILED and SOCK_RST_NETWORK_FAILED are fatal errors,
when they happen, the socket cannot be used to transfer data further.
]]
local open_connection = function(host, port)

    SOCK_RST_OK = 0
    SOCK_RST_TIMEOUT = 1
    SOCK_RST_BUSY = 2
    SOCK_RST_PARAMETER_WRONG = 3
    SOCK_RST_SOCK_FAILED = 4
    SOCK_RST_NETWORK_FAILED = 5

    logger.log("ptcp_client", 0, "Client id is: ", thread.index());
    --local app_handle = CLIENT_TO_APP_HANDLE[client_id];
    local app_handle = client_id_to_app_handle(thread.index(), true);
    logger.log("ptcp_client", 0, "App handle is: ", app_handle);
    if( not app_handle ) then
        logger.log("ptcp_client", 30, "No app handle. Send failed")
        return false;
    end;

    local network_is_up = check_and_enable_network(app_handle);
    if( not network_is_up ) then
        logger.log("ptcp_client", 30, "Network is not up. Send failed.");
        return false;
    end;

    local local_ip_addr = network.local_ip(app_handle);
    logger.log("ptcp_client", 0, "local ip address is ", local_ip_addr);

    local mtu_value = network.mtu(app_handle);
    logger.log("ptcp_client", 0, "MTU is ", mtu_value, " bytes");

    --[[

  If the client_id parameter is the same as the network.open(), the network.resolve() will use the same PDP activated using network.open(), 
  or else the network.resolve() will activate new PDP context by itself.

  ]]
    
    logger.log("ptcp_client", 0, "resolving DNS address...\r\n");
    local ip_address = network.resolve(host, cid);
    logger.log("ptcp_client", 0, "The IP address for ", host, " is ", ip_address);



    SOCK_TCP = 0;
    SOCK_UDP = 1;

    SOCK_WRITE_EVENT = 1
    SOCK_READ_EVENT = 2
    SOCK_CLOSE_EVENT = 4
    SOCK_ACCEPT_EVENT = 8

    local socket_fd = socket.create(app_handle, SOCK_TCP);

    if (not socket_fd or socket_fd < 1) then
        logger.log("ptcp_client", 30, "failed to create socket for app handle: ", app_handle, " socket_fd is ", tostring(socket_fd));
    elseif (ip_address) then
        --enable keep alive
        socket.keepalive(socket_fd, true);--this depends on network.set_tcp_ka_param() to set KEEP ALIVE interval and maximum check times.
        logger.log("ptcp_client", 0, "socket_fd=", socket_fd);
        logger.log("ptcp_client", 0, "connecting server...");
        local timeout = 30000;--  '<= 0' means wait for ever; '> 0' is the timeout milliseconds
        local connect_result, socket_released = socket.connect(socket_fd, ip_address, port, timeout);
        --[[

     the socket_released indicates whether the socket handle has been released when failing to connect to the server.
     If socket_released is true, the socket.close() function needs not be called further. or else
     the socket.close() function still needs to be called to release the socket handle.

     ]]
        logger.log("ptcp_client", 0, "socket.connect = [result=", connect_result, ",socket_released=", socket_released, "]\r\n");
        if (not connect_result) then
            logger.log("ptcp_client", 30, "failed to connect server");
        else
            logger.log("ptcp_client", 0, "connect server succeeded");
            return socket_fd
        end
    end
    return false
end
_M.open_connection = open_connection

local close_network = function(client_id)
    local app_handle = client_id_to_app_handle(client_id, false)
    local result
    local status
    if app_handle then
        set_network_dormant(app_handle, true);
        status = network.status(app_handle);
        logger.log("ptcp_client", 0, "network status before close is ", tostring(status));
        if CLOSE_NETWORK_AFTER_TRANSFER then
            logger.log("ptcp_client", 0, "closing network for app_handle: ", app_handle);
            result = network.close(app_handle);
            logger.log("ptcp_client", 0, "network.close(), result=", result);
            thread.enter_cs(5)
            CLIENT_TO_APP_HANDLE[client_id] = nil
            thread.leave_cs(5)
        else
            logger.log("ptcp_client", 0, "Not closing network as CLOSE_NETWORK_AFTER_TRANSFER set to: ", CLOSE_NETWORK_AFTER_TRANSFER)
        end
        status = network.status(app_handle);
        logger.log("ptcp_client", 0, "network status after close is ", tostring(status));
    else
        logger.log("ptcp_client", 30, "No app handle for client id: ", client_id)
    end;
    -- App handle seems to be getting lost. Don't drop it for now.
    return result;
end;
_M.close_network = close_network;




return _M

