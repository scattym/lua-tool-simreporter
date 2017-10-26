--------------------------------------------------------------------------------
--脚本说明
--本脚本包含系统内部AT命令处理辅助操作函数
--------------------------------------------------------------------------------
--[[
  This file contains the sio utilities which can be used to send or receive data to or from SIO.
]]

function sio_util_init(context)
  print("sio_util_init\r\n");
end;

function sio_util_add_unhandled_sio_string(context, unhandled_sio_string)
end;

function sio_util_process_unhandled_sio_string(context)
end;

--[[
FUNCTION sio_recv_contain
DESCRIPTION
  This function is used to receive an expected result on SIO
PARAMETERS
  expect_result: the expected result
  timeout: the timeout value for receiving
RETURN VALUE
  the received string
]]
function sio_recv_contain(context, expect_result, timeout)
  local find_rst = nil;
  local rsp = nil;
  local start_count = os.clock();
  --print("start_count = ", start_count);
  while (not find_rst) do    
    rsp = sio_recv(context, 1000); 
    --print(rsp);   
    if (rsp) then
      find_rst = string.absfind(rsp,expect_result);
	  if (not find_rst) then
	    --sio_util_add_unhandled_sio_string(context, rsp);
	  end;
    else  
      local cur_count = os.clock();
      --print("cur_count = ", cur_count);
      if (timeout and (timeout > 0)) then
        if (((cur_count - start_count)*1000) > timeout) then
          --print("time out for receiving expect result");
          break;
        end;
      end;
    end;
  end
  return rsp;
end

--[[
FUNCTION sio_recv_contain2
DESCRIPTION
  This function is used to receive one of the two expected results on SIO
PARAMETERS
  expect_result1: the 1st expected result
  expect_result2: the 2nd expected result
  timeout: the timeout value for receiving
RETURN VALUE
  the received string
  the received result index
]]
function sio_recv_contain2(context, expect_result1, expect_result2, timeout)
  local find_rst = nil;
  local rsp = nil;
  local rst_num = -1;
  local start_count = os.clock();
  --print("start_count = ", start_count, "\r\n");
  --print("sio_recv_contain2",expect_result1, expect_result2, "\r\n");
  while (not find_rst) do
    rsp = sio_recv(context, 1000);    
    if (rsp) then
      --print("recv2,rsp="..rsp);
      find_rst = string.absfind(rsp,expect_result1);
      --print(rsp, "find_rst=",find_rst, expect_result1, "\r\n");
      if (not find_rst) then
        find_rst = string.absfind(rsp,expect_result2);
        --print("find_rst(2)=",find_rst, expect_result2, "\r\n");
        if (find_rst) then
          rst_num = 2;
		else
	      --sio_util_add_unhandled_sio_string(context, rsp);
        end;
      else
        rst_num = 1;
      end;
    else
	  local cur_count = os.clock();
      --print("cur_count = ", cur_count, "\r\n");
      if (timeout and (timeout > 0)) then
        if (((cur_count - start_count)*1000) > timeout) then
          --print("time out for receiving expect result", "\r\n");
          break;
        end;
      end;
    end
    --print("sio_recv_contain2", rsp, rst_num, "\r\n");
  end
  return rsp , rst_num;
end

--[[
FUNCTION sio_recv_contain3
DESCRIPTION
  This function is used to receive one of the three expected results on SIO
PARAMETERS
  expect_result1: the 1st expected result
  expect_result2: the 2nd expected result
  expect_result3: the 3rd expected result
  timeout: the timeout value for receiving
RETURN VALUE
  the received string
  the received result index
]]
function sio_recv_contain3(context, expect_result1, expect_result2, expect_result3, timeout)
  local find_rst = nil;
  local rsp = nil;
  local rst_num = -1;
  local start_count = os.clock();
  --print("start_count = ", start_count);
  while (not find_rst) do
    rsp = sio_recv(context, 1000);    
    if (rsp) then
      --print(rsp);
      find_rst = string.absfind(rsp,expect_result1);
      --print(rsp, "find_rst=",find_rst, expect_result1);
      if (not find_rst) then
        find_rst = string.absfind(rsp,expect_result2);
        --print("find_rst(2)=",find_rst, expect_result2);
        if (not find_rst) then
          find_rst = string.absfind(rsp,expect_result3);
          if (find_rst) then
            rst_num = 3;
		  else
		    --sio_util_add_unhandled_sio_string(context, rsp);
          end;
        else
          rst_num = 2;
        end;
      else
        rst_num = 1;
      end;
    else
      local cur_count = os.clock();
      --print("cur_count = ", cur_count);
      if (timeout and (timeout > 0)) then
        if (((cur_count - start_count)*1000) > timeout) then
          --print("time out for receiving expect result");
          break;
        end;
      end;
    end
    --print("sio_recv_contain2", rsp, rst_num);
  end
  return rsp , rst_num;
end
--[[
FUNCTION sio_send
DESCRIPTION
  This function is used to send command to SIO
PARAMETERS
  cmd: the string to be sent
RETURN VALUE
  None
]]
function sio_send(context, cmd)
  print(">>>>>>>>>>>>>>", cmd);
  sio.send(cmd);
end;
--[[
FUNCTION sio_recv
DESCRIPTION
  This function is used to receive data from SIO
PARAMETERS
  None
RETURN VALUE
  The received string
]]
function sio_recv(context, timeout)  
  local rsp = sio.recv(timeout);
  if (rsp) then
    print("<<<<<<<<<<<<<<", rsp);
  end;
  return rsp;
end;
--[[
FUNCTION sio_recv2
DESCRIPTION
  This function is used to receive data from SIO
PARAMETERS
  None
RETURN VALUE
  The received string
]]
function sio_recv2(context, timeout)  
  if (not timeout) then
    return sio_recv(context, timeout);
  end;
  local start_count = os.clock();
  while (true) do
    local cur_count = os.clock();
    local left_time = timeout - (cur_count - start_count)*1000;
	if (left_time <= 0) then
	  return nil;
	end;
    local wait_time = left_time;
	if (wait_time > 1000) then
	  wait_time = 1000;
	end;
    rsp = sio_recv(context, wait_time);
	if (rsp) then
	  return rsp;
	end;
  end;
end;
--[[
FUNCTION enable_at_echo
DESCRIPTION
  This function is used to enable or disable AT echo state
PARAMETERS
  enable: enable or disable
RETURN VALUE
  None
]]
function enable_at_echo(context, enable)
  if (enable) then
    sio_send(context, "ATE1\r\n");
    sio_recv(context, 5000);
  else
    sio_send(context, "ATE0\r\n");
    sio_recv(context, 5000);
  end;
end;

--[[
FUNCTION sio_send_and_recv
DESCRIPTION
  This function is used to send a command and try to receive an expected result from SIO
PARAMETERS
  cmd: the command to be sent
  expect_result: the expected result to be received
  timeout: the timeout value for receiving
RETURN VALUE
  The string received from SIO
]]
function sio_send_and_recv(context, cmd, expect_result, timeout)
  sio_send(context, cmd);
  local rsp = sio_recv_contain(context, expect_result, timeout);
  return rsp;
end
--[[
FUNCTION sio_send_and_recv2
DESCRIPTION
  This function is used to send a command and try to receive one of the two expected results from SIO
PARAMETERS
  cmd: the command to be sent
  expect_result1: the 1st expected result to be received
  expect_result2: the 2nd expected result to be received
  timeout: the timeout value for receiving
RETURN VALUE
  The string received from SIO
  the recived result index
]]
function sio_send_and_recv2(context, cmd, expect_result1, expect_result2, timeout)
  sio_send(context, cmd);
  local rsp, exp_num = sio_recv_contain2(context, expect_result1, expect_result2, timeout);
  --print("sio_send_and_recv2",rsp, exp_num);
  return rsp, exp_num;
end
--[[
FUNCTION sio_send_and_recv3
DESCRIPTION
  This function is used to send a command and try to receive one of the three expected results from SIO
PARAMETERS
  cmd: the command to be sent
  expect_result1: the 1st expected result to be received
  expect_result2: the 2nd expected result to be received
  expect_result3: the 3rd expected result to be received
  timeout: the timeout value for receiving
RETURN VALUE
  The string received from SIO
  the received result index
]]
function sio_send_and_recv3(context, cmd, expect_result1, expect_result2, expect_result3, timeout)
  sio_send(context, cmd);
  local rsp, exp_num = sio_recv_contain3(context, expect_result1, expect_result2, expect_result3, timeout);
  --print("sio_send_and_recv2",rsp, exp_num);
  return rsp, exp_num;
end