--------------------------------------------------------------------------------
--脚本说明
--本脚本包含网络(network)相关操作函数
--------------------------------------------------------------------------------
function nw_util_init(context)
  print("nw_util_init\r\n");
  context.nw_info = {};
  context.nw_info.csq = nil;
  context.nw_info.nsmod = nil;    
  context.nw_info.creg = nil;
  context.nw_info.cgreg = nil;
  context.nw_query_timeout_value = 1000;
end;

function nw_util_process_after_init(context)
  print("nw_util_process_after_init\r\n");
  --nw_util_set_cgdcont(context, context.pdp_apn);
  --nw_util_set_cgsockcont(context, context.pdp_apn);
  nw_util_get_csq(context, true);
  nw_util_get_cnsmod(context, true);
  nw_util_get_creg(context, true);
  nw_util_get_cgreg(context, true);
  nw_util_start_csq_query(context);
  nw_util_start_cns_mod_query(context);
  
  otad_util_process_network_info(context, context.nw_info.csq, context.nw_info.cnsmod, context.nw_info.creg, context.nw_info.cgreg);
  
  if (simcard_util_is_pin_ready(context)) then
    vmstarttimer(context.timer_ids.nw_query_timer, context.nw_query_timeout_value, 0);
  end;
end;

function nw_util_set_cgsockcont(context, pdp_apn)
  local cmd = string.format("AT+CGSOCKCONT=1,\"IP\",\"%s\"\r\n",pdp_apn);
  local rsp, exp_num = sio_send_and_recv2(context, cmd,"\r\nOK\r\n","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    return true;
  else
    return false;
  end;
end;

function nw_util_set_cgdcont(context, pdp_apn)
  local cmd = string.format("AT+CGDCONT=1,\"IP\",\"%s\"\r\n",pdp_apn);
  local rsp, exp_num = sio_send_and_recv2(context, cmd,"\r\nOK\r\n","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    return true;
  else
    return false;
  end;
end;

function nw_util_get_creg(context, at_query)
  if (at_query) then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CREG?\r\n","\r\n+CREG:","\r\nERROR\r\n", 5000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CREG:";
    local creg = str_util_parse_sio_report_parameter(rsp,rpt,2,",","\r\n",false);
    if (creg) then 
	  creg = tonumber(creg);
	  context.nw_info.creg = creg;
    end;
  end;
  print("context.nw_info.creg=", context.nw_info.creg, "\r\n");
  return context.nw_info.creg;
end;

function nw_util_get_cgreg(context, at_query)
  if (at_query) then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CGREG?\r\n","\r\n+CGREG:","\r\nERROR\r\n", 5000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CGREG:";
    local cgreg = str_util_parse_sio_report_parameter(rsp,rpt,2,",","\r\n",false);
    if (cgreg) then 
	  cgreg = tonumber(cgreg);
	  context.nw_info.cgreg = cgreg;	  
    end;
  end;
  print("context.nw_info.cgreg=", context.nw_info.cgreg, "\r\n");
  return context.nw_info.cgreg;
end;

function nw_util_get_csq(context, at_query)
  if (at_query) then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CSQ\r\n","\r\n+CSQ:","\r\nERROR\r\n", 5000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CSQ:";
    local csq = str_util_parse_sio_report_parameter(rsp,rpt,1,",",",",false);
    if (csq) then 
	  csq = tonumber(csq);
	  context.nw_info.csq = csq;	  
    end;
  end;  
  print("context.nw_info.csq=", context.nw_info.csq, "\r\n");
  return context.nw_info.csq;
end;

function nw_util_is_creg_ok(context)
  if (not context.nw_info.creg) then
    return false;
  end;
  if ((context.nw_info.creg == 1) or (context.nw_info.creg == 5)) then
    return true;
  end;
  return false;
end;

function nw_util_get_cnsmod(context, at_query)
  if (at_query) then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CNSMOD?\r\n","\r\n+CNSMOD:","\r\nERROR\r\n", 5000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CNSMOD:";
    local cnsmod = str_util_parse_sio_report_parameter(rsp,rpt,2,",","\r\n",false);
    if (cnsmod) then
	  context.nw_info.cnsmod = tonumber(cnsmod); 	
    end;
  end;
  print("context.nw_info.cnsmod=", context.nw_info.cnsmod, "\r\n");
  return context.nw_info.cnsmod;
end;

function nw_util_start_csq_query(context)
  sio_send(context, "AT+AUTOCSQ=1,1\r\n");
end;

function nw_util_start_cns_mod_query(context)
  sio_send(context, "AT+CNSMOD=1\r\n");
end;

--[[
FUNCTION sio_nw_evt_csq_handler
DESCRIPTION
  This function is used to handle the +CSQ report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]
function sio_nw_evt_csq_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)    
  print("nw_util_csq_handler\r\n");
  local rpt = "\r\n+CSQ:";
  if (string.startwith(context.sio_rcvd_string, rpt)) then
    local csq = str_util_parse_sio_report_parameter(context.sio_rcvd_string,rpt,1,",",",",false);
	if (csq) then 
	  csq = tonumber(csq);
	  context.nw_info.csq = csq;
	  print("context.nw_info.csq=", context.nw_info.csq, "\r\n");
	end;
	local idx = string.absfind(context.sio_rcvd_string, "\r\n", string.len(rpt));
	if (idx) then
	  idx = idx + 2;
	  if (string.len(context.sio_rcvd_string) >= idx) then
	    context.sio_rcvd_string = "";
	  else
	    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, idx, -1);
	  end;
	end;
  end;   
  otad_util_process_network_info(context, context.nw_info.csq, context.nw_info.cnsmod, context.nw_info.creg, context.nw_info.cgreg);
end;

--[[
FUNCTION sio_nw_evt_cnsmod_handler
DESCRIPTION
  This function is used to handle the +CNSMOD report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]
function sio_nw_evt_cnsmod_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("ui_sys_cnsmod_handler\r\n");
  local rpt = "\r\n+CNSMOD:";
  if (string.startwith(context.sio_rcvd_string, rpt)) then
    local cnsmod = str_util_parse_sio_report_parameter(context.sio_rcvd_string,rpt,2,",","\r\n",false);
	if (cnsmod) then
	  context.nw_info.cnsmod = tonumber(cnsmod); 
	  print("context.nw_info.cnsmod=", context.nw_info.cnsmod, "\r\n");
	end;
	local idx = string.absfind(context.sio_rcvd_string, "\r\n", string.len(rpt));
	if (idx) then
	  idx = idx + 2;
	  if (string.len(rpt) >= idx) then
	    context.sio_rcvd_string = "";
	  else
	    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, idx, -1);
	  end;
	end;
  end;   
  otad_util_process_network_info(context, context.nw_info.csq, context.nw_info.cnsmod, context.nw_info.creg, context.nw_info.cgreg);
end;
--[[
FUNCTION nw_util_nw_query_timer_handler_proc
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
function nw_util_nw_query_timer_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  if (evt ~= context.evt.timer) then
    return;
  end;
  if (evt_p1 ~= context.timer_ids.nw_query_timer) then
    return;
  end;  
  if ((not context.nw_info.creg) or (context.nw_info.creg == 0)) then
    if(context.newwork_reg_ok) then
      context.newwork_reg_dt_start_time = os.time();
      context.newwork_reg_ok = false;
    end;
    
    nw_util_get_creg(context, true);
  else
    if(not context.newwork_reg_ok) then
      if(nw_util_is_creg_ok(context)) then
        context.newwork_reg_dt_end_time = os.time();
        context.newwork_reg_ok = true;
        
        local searchtime = context.newwork_reg_dt_end_time - context.newwork_reg_dt_start_time;
        local searchinfo = string.format("searchtime = %d", searchtime);
        otad_util_network_srch_info(context, searchinfo);
      end;
    end;
  end;
  if ((not context.nw_info.cgreg) or (context.nw_info.cgreg == 0)) then
    nw_util_get_cgreg(context, true);
  end;
  otad_util_process_network_info(context, context.nw_info.csq, context.nw_info.cnsmod, context.nw_info.creg, context.nw_info.cgreg);
  if ((not context.nw_info.creg) or (context.nw_info.creg == 0)--[[ or (not context.nw_info.cgreg) or (context.nw_info.cgreg == 0)]]) then
    vmstarttimer(context.timer_ids.nw_query_timer, 1000, 0);
  end;
end;