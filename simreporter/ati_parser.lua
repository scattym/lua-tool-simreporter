
local _M = {}

local get_device_info = function()
  cmd = "ATE0\r\n"
  sio.send(cmd)
  --receive response with 5000 ms time out
  rsp = sio.recv(5000)  
  print(rsp)
  
  cmd = "ATI\r\n";
  --clear sio recv cache
  sio.clear()  
  sio.send(cmd)
  local ati_string = sio.recv(5000)
  print(ati_string)
  
  cmd = "ATE1\r\n"
  sio.send(cmd)
  --receive response with 5000 ms time out
  rsp = sio.recv(5000)  
  print(rsp)
  
  return ati_string;

end;

_M.get_device_info = get_device_info

return _M