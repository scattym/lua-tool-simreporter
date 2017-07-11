
local _M = {}

local run_command = function(cmd)
    local echo_off = "ATE0\r\n"
    local echo_on = "ATE1\r\n"
    sio.send(echo_off)
    --receive response with 5000 ms time out
    rsp = sio.recv(5000)
    print(rsp)

    --clear sio recv cache
    sio.clear()
    sio.send(cmd .. "\r\n")
    --receive response with 5000 ms time out
    return_string = sio.recv(5000)
    print(rsp)

    sio.send(echo_on)
    --receive response with 5000 ms time out
    rsp = sio.recv(5000)
    print(rsp)

    return return_string;
end;

local get_device_info = function()
    response = run_command("ATI")
    return response;
end;

_M.get_device_info = get_device_info

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

local get_cbc = function()
    response = run_command("AT+CBC");
    return response;
end;
_M.get_cbc = get_cbc

local get_cclk = function()
    response = run_command("AT+CCLK?");
    return response;
end;
_M.get_cclk = get_cclk


local get_cgsn = function()
    response = run_command("AT+CGSN");
    return response;
end;
_M.get_cgsn = get_cgsn

local get_cgmi = function()
    response = run_command("AT+CGMI");
    return response;
end;
_M.get_cgmi = get_cgmi

local get_cgmm = function()
    response = run_command("AT+CGMM");
    return response;
end;
_M.get_cgmm = get_cgmm

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

return _M
