local logging = require("logging")
local aes = require("aes")
local _M = {}


--supported port for atctl.setport(...)
_M.ATCTL_UART_PORT  = 1
_M.ATCTL_MODEM_PORT = 2
_M.ATCTL_USBAT_PORT = 3
_M.ATCTL_UART2_PORT = 4
--  -1 is used to release the port
_M.ATCTL_INVALID_PORT = -1

_M.SIO_EVENT = 29
_M.AT_CTL_EVENT = 30

local CMD_CALLBACKS = {}

local logger = logging.create("at_commands", 30)


local run_command = function(cmd)
    logger(0, "Running command: ", cmd, "<<")
    logger(0, "Thread entering critical section");
    aes.add_entropy(tostring(os.clock))
    thread.enter_cs(1);
    logger(0, "Thread in critical section");
    local echo_off = "ATE0\r\n"
    local echo_on = "ATE1\r\n"
    sio.send(echo_off)
    --receive response with 5000 ms time out
    rsp = sio.recv(5000)

    --clear sio recv cache
    sio.clear()
    --logger(0, cmd .. "\r\n")
    sio.send(cmd .. "\r\n")
    --receive response with 5000 ms time out
    return_string = sio.recv(5000)
    logger(0, rsp)

    sio.send(echo_off)
    --receive response with 5000 ms time out
    rsp = sio.recv(5000)
    thread.leave_cs(1);
    aes.add_entropy(tostring(os.clock)..return_string)
    --aes.add_entropy(return_string)

    logger(0, "Thread out of critical section");

    return return_string;
end;
_M.run_command = run_command

-- Manufacturer: SIMCOM INCORPORATED
-- Model: SIMCOM_SIM5320A
-- Revision: SIM5320A_V1.5
-- IMEI: 012813008945935
-- +GCAP: +CGSM,+DS,+ES
local get_device_info = function()
    response = run_command("ATI")
    return response;
end;

_M.get_device_info = get_device_info

-- +CCINFO:[SCELL],UARFCN:4436,MCC:505,MNC:001,LAC:338,ID:14302219,PSC:214,SSC:0,RSCP:88,ECIO:8.0,RXLev:-88dbm,TXPWR:0
-- +CCINFO:[NCell1],UARFCN:4436,PSC:230,SSC:0,RSCP:97,ECIO:15.5,RXLev:-97dbm
local get_cell_info = function()
    response = run_command("AT+CCINFO");
    return response;
end;

_M.get_cell_info = get_cell_info

-- AT+CPSI?
-- +CPSI: WCDMA,Online,505-01,0x0152,14302219,WCDMA 850,214,4436,0,12.5,83,23,36,500
local get_cpsi = function()
    response = run_command("AT+CPSI?");
    return response;
end;
_M.get_cpsi = get_cpsi

-- at+cops?
-- +COPS: 1,0,"Telstra Mobile",2
local get_cops = function()
    response = run_command("AT+COPS?");
    return response;
end;
_M.get_cops = get_cops

-- +CBC: 0,94,4.145V
local get_cbc = function()
    response = run_command("AT+CBC");
    return response;
end;
_M.get_cbc = get_cbc

--+CCLK: "80/01/11,23:48:23+32"
local get_cclk = function()
    response = run_command("AT+CCLK?");
    return response;
end;
_M.get_cclk = get_cclk


-- 012813008945935
local get_cgsn = function()
    response = run_command("AT+CGSN");
    return response;
end;
_M.get_cgsn = get_cgsn

-- SIMCOM INCORPORATED
local get_cgmi = function()
    response = run_command("AT+CGMI");
    return response;
end;
_M.get_cgmi = get_cgmi

-- SIMCOM_SIM5320A
local get_cgmm = function()
    response = run_command("AT+CGMM");
    return response;
end;
_M.get_cgmm = get_cgmm

-- +CGMR: 1575B14SIM5320A
local get_cgmr = function()
    response = run_command("AT+CGMR");
    return response;
end;
_M.get_cgmr = get_cgmr

-- +CSPN: "YES OPTUS",1
local get_cspn = function()
    response = run_command("AT+CSPN?");
    return response;
end;
_M.get_cspn = get_cspn

-- +ICCID: 8961025816454955613F
local get_ciccid = function()
    response = run_command("AT+CICCID");
    return response;
end;
_M.get_ciccid = get_ciccid

-- AT+CIMI
-- 505025806420285
local get_cimi = function()
    response = run_command("AT+CIMI");
    return response;
end;
_M.get_cimi = get_cimi

-- AT+CGSOCKCONT=1,"IP","yesinternet","0.0.0.0",0,0
local set_cgsockcont = function(data)
    response = run_command("AT+CGSOCKCONT=" .. data);
    return response;
end;
_M.set_cgsockcont = set_cgsockcont

-- AT+CGDCONT=1,"IP","yesinternet","0.0.0.0",0,0
local set_cgdcont = function(data)
    response = run_command("AT+CGDCONT=" .. data);
    return response;
end;
_M.set_cgdcont = set_cgdcont

-- AT+COPS=?
-- +COPS: (2,"YES OPTUS","OPTUS","50502",7),(1,"Optus AU","Optus","50502",2),(1,"Optus AU","Optus","50502",0),(3,"Telstra Mobile","Telstra","50501",7),(3,"vodafone AU","voda AU","50503",0),(3,"vodafone AU","voda AU","50503",2),(3,"vodafone AU","voda AU","50503",7),,(0,1,2,3,4,5),(0,1,2)
-- AT+COPS=0,2,50502
local set_cops = function(data)
    response = run_command("AT+COPS=" .. data);
    return response;
end;
_M.set_cops = set_cops

-- AT+CGPSINFO
-- +CGPSINFO:3348.946584,S,15112.011722,E,150717,023133.4,90.4,0.0,0
-- AmpI/AmpQ: 443/434
-- OK
local get_cgpsinfo = function()
    response = run_command("AT+CGPSINFO");
    return response;
end;
_M.get_cgpsinfo = get_cgpsinfo

--AT+CGDCONT?
--+CGDCONT: 1,"IP","","0.0.0.0",0,0
--OK
local get_cgdcont = function()
    response = run_command("AT+CGDCONT?");
    return response;
end;
_M.get_cgdcont = get_cgdcont


--AT+CGSOCKCONT?
--+CGSOCKCONT: 1,"IP","telstra.wap","0.0.0.0",0,0
--+CGSOCKCONT: 2,"IP","","0.0.0.0",0,0
--+CGSOCKCONT: 3,"IP","","0.0.0.0",0,0
local get_cgsockcont = function()
    response = run_command("AT+CGSOCKCONT?");
    return response;
end;
_M.get_cgsockcont = get_cgsockcont



local get_pwr_on_check = function()
    response = run_command("AT+CPWRONCHK?");
    return response;
end;
_M.get_pwr_on_check = get_pwr_on_check


local change_dir = function(directory)
    response = run_command("AT+FSCD=c:/"..directory);
    return response;
end;
_M.change_dir = change_dir

local reset = function()
    response = run_command("AT+CRESET");
    return response;
end;
_M.reset = reset

-- AT+CMGF=1
local set_cmgf = function(value)
    local response = run_command("AT+CMGF="..value);
    return response;
end
_M.set_cmgf = set_cmgf

-- AT+IPR2=9600
local set_baud_rate = function(uart_num, baud_rate)
    local extra = ""
    if uart_num == "2" or uart_num == 2 then
        extra = "2"
    end
    local response = run_command("AT+IPR" .. extra .. "=" .. tostring(baud_rate))
    return response;
end;
_M.set_baud_rate = set_baud_rate

local register_command = function(command, callback, async)
    if not async or async < 0 or async > 1 then
        logger(30, "Invalid async option. Setting to 0.")
        async = 0
    end
    atctl.atcadd(command, async)
    CMD_CALLBACKS[command] = callback
end
_M.register_command = register_command

local wait_at_command_thread = function(uart_callback)
    -- atctl.setport(_M.ATCTL_UART_PORT)
    -- atctl.send("Please input any AT command.\r\n");

    thread.setevtowner(_M.AT_CTL_EVENT, _M.AT_CTL_EVENT)

    -- thread.addevtfilter(100, true, _M.AT_CTL_EVENT)
    while true do

        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(9999999)
        if(evt == _M.AT_CTL_EVENT) then
            -- thread.clearevts()
            logger(30, "Got an atctl event")

            local cmd_port, cmd_name, cmd_op, cmd_line, cmd_status = atctl.atcget()
            if cmd_name then
                if CMD_CALLBACKS[cmd_name] then
                    CMD_CALLBACKS[cmd_name](cmd_port, cmd_name, cmd_op, cmd_line, cmd_status)
                else
                    logger(30, "No function handler for command: ", cmd_name)
                end
            else
                logger(10, "No command received. Could be uart.")

            end
        else
            logger(30, "Got an event we are not listening for. Event: ", evt)
        end
        collectgarbage()
    end
end
_M.wait_at_command_thread = wait_at_command_thread



local wait_uart_data = function(callback_func)
    logger(0, "Start of uart wait thread")
    local response = _M.set_baud_rate(2, 9600)
    logger(30, "Set baud rate response was: " .. response)
    -- sio.exclrpt(1); -- would set all URC to be via lua script
    atctl.setport(-1)
    atctl.setport(_M.ATCTL_UART2_PORT)
    while true do
        local data = atctl.recv(10000000)
        if not data then
            logger(0, "Event timeout.")
        else
            logger(30, "Data received: " .. data)
            local count_at_length = 0
            while count_at_length < 4 do
                local next_data = atctl.recv(100)

                if next_data and #next_data > 0 then
                    logger(30, "Adding data: ", next_data, " to payload:  ", data)
                    count_at_length = 0
                    data = data .. next_data
                else
                    logger(30, "No data received. Incrementing count at length. Payload is: ", data)
                    count_at_length = count_at_length + 1
                end
            end
            if data and #data > 0 then
                if callback_func then
                    logger(30, "payload received, sending to cb function: ", data)
                    callback_func(data)
                else
                    logger(30, "Receivd payload but no callback function set")
                end
            else
                logger(30, "No payload received on this atctl event")
            end
        end
        collectgarbage()
    end
end
_M.wait_uart_data = wait_uart_data


local enable_time_updates = function()
    response = run_command("AT+CTZU=1");
    return response;
end;
_M.enable_time_updates = enable_time_updates

return _M
