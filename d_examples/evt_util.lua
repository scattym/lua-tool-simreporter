--------------------------------------------------------------------------------
--脚本说明
--本脚本包含事件处理框架相关操作函数
--------------------------------------------------------------------------------
--[[
FUNCTION evt_util_init
DESCRIPTION
  This function is used to initiate the event handler array for the context
PARAMETERS
  context: the context of the program
RETURN VALUE
  win_context: the context of the program
]]
function evt_util_init(context)  
  print("evt_util_init\r\n");
  context.evt = {};
  context.evt.gpio   = 0;
  context.evt.uart   = 1;
  context.evt.keypad = 2;
  context.evt.usb    = 3;
  context.evt.audio  = 4;
  context.evt.sleep  = 23;
  context.evt.timer  = 28;
  context.evt.sio    = 29;
  context.evt.atctl  = 30;
  context.evt.outcmd = 31;
  context.evt.led    = 32;
  context.evt.pdp    = 33;
  context.evt.exit   = 38; -- used to exit script
  context.evt.max_system_event = 39;

  context.unhandled_sio_string = "";
  context.sio_rcvd_string = "";
  context.evt_handler = {};
  context.sio_data_handler = {};
  context.timer_evt_handler = {};

  context.evt.result = {};
  context.evt.result.LEVT_PDP_ATTACH_ACCEPT = 0;
  context.evt.result.LEVT_PDP_ATTACH_REJECT = 1;
  context.evt.result.LEVT_ACTIVATE_PDP_ACCEPT = 2;
  context.evt.result.LEVT_ACTIVATE_PDP_REJECT = 3;
    
  return context;
end;

function evt_util_process_after_init(context)
  setevtpri(context.evt.exit, 101);
end;

function evt_util_exit_script(context)
  setevt(context.evt.exit);
end;

--[[
FUNCTION evt_util_register_evt_handler
DESCRIPTION
  This function is used to register an event handler for a special event
PARAMETERS
  context: the context of the program
  evt: the event
  handler: the handler for the event
RETURN VALUE
  context: the context of the program
]]
function evt_util_register_evt_handler(context, evt, handler)
  context.evt_handler[evt] = handler;
  return context;
end;

--[[
FUNCTION evt_util_deregister_evt_handler
DESCRIPTION
  This function is used to deregister an event handler for a special event
PARAMETERS
  context: the context of the program
  evt: the event
RETURN VALUE
  context: the context of the program
]]
function evt_util_deregister_evt_handler(context, evt)
  context.evt_handler[evt] = nil;
  return context;
end;

function evt_util_call_evt_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("evt_util_call_evt_handler, evt=", evt, ", evt_p1=", evt_p1, ", evt_p2=", evt_p2, ", evt_p3=", evt_p3, ", evt_clock=",evt_clock, "\r\n");
  if (not evt or not context.evt_handler[evt]) then
    return;
  end;
  return context.evt_handler[evt](context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
end;

--[[
FUNCTION evt_util_evt_handler_proc
DESCRIPTION
  This function is used to handle the new generated event
PARAMETERS
  context: the application context
  evt: the event id
  evt_p1: the 1st parameter of the event
  evt_p2: the 2nd parameter of the event
  evt_p3: the 3rd parameter of the event
  evt_clock: the clock of the event occured
RETURN VALUE
  None
]]
function evt_util_evt_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  for event, handler in pairs(context.evt_handler) do
    if (event == evt) then
	  if (handler) then
	    return handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
	  else
	    return false;
	  end;
	end;
  end;
end;

--[[
FUNCTION evt_util_register_sio_data_handler
DESCRIPTION
  This function is used to register an SIO report handler for a special header
PARAMETERS
  context: the context of the program
  sio_header: the sio report header
  handler: the handler for the sio report header
RETURN VALUE
  context: the context of the program
]]
function evt_util_register_sio_data_handler(context,sio_header, handler)
  context.sio_data_handler[sio_header] = handler;
  return context;
end;

--[[
FUNCTION evt_util_deregister_sio_data_handler
DESCRIPTION
  This function is used to deregister an SIO report handler for a special header
PARAMETERS
  context: the context of the program
  sio_header: the sio report header
RETURN VALUE
  context: the context of the program
]]
function evt_util_deregister_sio_data_handler(win_context,sio_header)
  win_context.sio_data_handler[sio_header] = nil;
  return win_context;
end;

--[[
FUNCTION evt_util_sio_data_handler_proc
DESCRIPTION
  This function is used to handle the sio report data
PARAMETERS
  context: the application context
  evt: the event id
  evt_p1: the 1st parameter of the event
  evt_p2: the 2nd parameter of the event
  evt_p3: the 3rd parameter of the event
  evt_clock: the clock of the event occured
RETURN VALUE
  None
]]
function evt_util_sio_data_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("evt_util_sio_data_handler_proc(in), context=", context, "\r\n");
  sio_util_process_unhandled_sio_string(context);
  local sio_data = sio_recv(context, 0);
  if (sio_data) then
    context.sio_rcvd_string = context.sio_rcvd_string..sio_data;
  end;
  while (context.sio_rcvd_string and (string.len(context.sio_rcvd_string) > 0)) do
    local found_handler = false;
    if (context and context.sio_data_handler) then
      for sio_header, handler in pairs(context.sio_data_handler) do
        if (string.startwith(context.sio_rcvd_string,sio_header)) then
	      if (handler) then
	        handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
			found_handler = true;
			break;
	      end;
	    end;
      end;
	  if (not found_handler) then
	    print("no handler, so discard sio_string: ", context.sio_rcvd_string, "\r\n");
	    context.sio_rcvd_string = "";
	  end;
    end;
  end;
  return true;
end;

--[[
FUNCTION evt_util_register_timer_id_evt_handler
DESCRIPTION
  This function is used to register an event handler for a special event
PARAMETERS
  context: the context of the program
  evt: the event
  handler: the handler for the event
RETURN VALUE
  context: the context of the program
]]
function evt_util_register_timer_id_evt_handler(context, timer_id, handler)
  context.timer_evt_handler[timer_id] = handler;
  return context;
end;

--[[
FUNCTION evt_util_deregister_timer_id_evt_handler
DESCRIPTION
  This function is used to deregister an event handler for a special event
PARAMETERS
  context: the context of the program
  evt: the event
RETURN VALUE
  context: the context of the program
]]
function evt_util_deregister_evt_handler(context, timer_id)
  context.timer_evt_handler[timer_id] = nil;
  return context;
end;

--[[
FUNCTION evt_util_timer_evt_handler_proc
DESCRIPTION
  This function is used to handle the timer event
PARAMETERS
  context: the application context
  evt: the event id
  evt_p1: the 1st parameter of the event
  evt_p2: the 2nd parameter of the event
  evt_p3: the 3rd parameter of the event
  evt_clock: the clock of the event occured
RETURN VALUE
  None
]]
function evt_util_timer_evt_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("evt_util_timer_evt_handler_proc, context=", context, "\r\n");
  if (evt ~= context.evt.timer) then
    return;
  end;
  if (context.timer_evt_handler[evt_p1] and context.timer_evt_handler[evt_p1]) then
    context.timer_evt_handler[evt_p1](context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
  end;
  --[[if (evt_p1 == context.timer_ids.nw_query_timer) then
    nw_util_nw_query_timer_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
  elseif (evt_p1 == context.timer_ids.battery_query_timer) then
    nw_util_battery_query_timer_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock);
  end;]]
end;


--[[
FUNCTION evt_util_pdp_evt_handler_proc
DESCRIPTION
  This function is used to handle the pdp report data
PARAMETERS
  context: the application context
  evt: the event id
  evt_p1: the 1st parameter of the event
  evt_p2: the 2nd parameter of the event
  evt_p3: the 3rd parameter of the event
  evt_clock: the clock of the event occured
RETURN VALUE
  None
]]
function evt_util_pdp_evt_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  local pdpInfo;
  if(evt_p1 == context.evt.result.LEVT_PDP_ATTACH_ACCEPT) then
    pdpInfo = "ATTACH_ACCEPT";
    otad_util_ps_opt_info(context, pdpInfo);
  elseif(evt_p1 == context.evt.result.LEVT_PDP_ATTACH_REJECT) then
    pdpInfo = "ATTACH_REJECT -> " + evt_p2;
    otad_util_ps_opt_info(context, pdpInfo);    
  elseif(evt_p1 == context.evt.result.LEVT_ACTIVATE_PDP_ACCEPT) then
    pdpInfo = "ACTIVATE_PDP_ACCEPT";
    otad_util_ps_opt_info(context, pdpInfo);
  else
    pdpInfo = "ACTIVATE_PDP_REJECT";
    otad_util_ps_opt_info(context, pdpInfo);
  end;   
end;

