function simcard_util_init(context)
  print("simcard_util_init\r\n");
  context.simcard_state_type = {};
  context.simcard_state_type.ready = 1;
  context.simcard_state_type.busy = 2;
  context.simcard_state_type.sim_failure = 3;
  
  context.simcard_state = nil;
end;
--[[
FUNCTION wait_for_pin_ready
DESCRIPTION
  This function is used to wait for pin ready report
PARAMETERS
  None
RETURN VALUE
  None
]]
function simcard_util_wait_for_pin_ready(context)
  local rsp = nil;
  while (not rsp) do
    rsp, idx = sio_send_and_recv3(context, "AT+CPIN?\r\n","\r\n+CPIN: READY\r\n","\r\n+CPIN: SIM busy\r\n","\r\n+CME ERROR: SIM failure\r\n", 60000);
	if (rsp) then
	  if (string.absfind(rsp, "\r\n+CPIN: READY\r\n")) then
	    context.simcard_state = context.simcard_state_type.ready;
		break;
	  elseif (string.absfind(rsp, "\r\n+CME ERROR: SIM failure\r\n")) then
	    context.simcard_state = context.simcard_state_type.sim_failure;
		break;
	  end;
	end;
  end;
  print(rsp);
end;

function simcard_util_is_pin_ready(context)
  if (context.simcard_state) then
    return (context.simcard_state == context.simcard_state_type.ready);
  end;
  return false;
end;