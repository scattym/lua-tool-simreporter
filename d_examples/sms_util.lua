--------------------------------------------------------------------------------
--脚本说明
--本脚本包含短信设置和发送相关操作函数
--------------------------------------------------------------------------------
--[[
FUNCTION sms_util_init
DESCRIPTION
  This function is used to initialize sms module
PARAMETERS
  csca: the CSCA number
RETURN VALUE
  None
]]
function sms_util_init(context) 
  print("sms_util_init\r\n"); 
  --local csca = context.csca;  
  context.sms = {};  
  
  if (not simcard_util_is_pin_ready(context)) then
    return;
  end;
  
  sio_send(context, "AT+CSCS=\"IRA\"\r\n");
  sio_recv(context, 5000);
  --init csca  
  --[[
  local try_read_times = 10;
  if (not csca) then
    try_read_times = nil;
  end;
  local sms_csca = sms_util_read_csca(context, try_read_times);
  print("Original sms_csca=", sms_csca, "\r\n");
  if ((not sms_csca or (string.len(sms_csca) == 0)) and csca) then
    sms_util_set_csca(context, csca);
  end;
  --]]
  sio_send(context, "AT+CMGF=1\r\n");
  sio_recv(context, 5000);
  
  sio_send(context, "AT+CNMI=1,2\r\n");--report +CMT; 2,1=+CMTI
  sio_recv(context, 5000);
  
  sio_send(context, "AT+CSMP=17,0,0,8\r\n");
  sio_recv(context, 5000);
  sio_send(context, "AT+CSCS=\"UCS2\"\r\n");
  sio_recv(context, 5000);
  sio_send(context, "AT+CGSMS=1\r\n");
  sio_recv(context, 5000);
  context.max_sms_number_in_me_store = sms_util_switch_to_store(context, "ME");
  
  
end;

function sms_util_read_csca(context, max_try_times)
  print("sms_util_read_csca, max_try_times=", max_try_times, "\r\n");
  if (not max_try_times) then
    max_try_times = 1;
  end;
  local tried_times = 0;
  local sms_csca = nil;
  while (tried_times < max_try_times) do
    tried_times = tried_times + 1;
    while(true)do
      local rsp ,idx = sio_send_and_recv3(context, "AT+CSCA?\r\n", "\r\n+CSCA:", "\r\n+CME ERROR: SIM busy", "\r\nERROR\r\n");
	  if (rsp and (idx == 1)) then
	    sms_csca = str_util_parse_sio_report_parameter(rsp,"\r\n+CSCA:",1,",","\r\n",true);
	    if (not sms_csca or (string.len(sms_csca) == 0)) then
	      sms_csca = str_util_parse_sio_report_parameter(rsp,"\r\n+CSCA:",1,",",",",true);
	    end;
	    break;
	  end;
	  vmsleep(500);
    end;
	if (sms_csca and (string.len(sms_csca) > 0)) then
	  break;
	end;
	vmsleep(2000);
  end;
  print("result of sms_util_read_csca=", sms_csca, "\r\n");
  return sms_csca;
end;

function sms_util_set_csca(context, csca)
  if (not csca) then
    return;
  end;
  local cmd = string.format("AT+CSCA=\"%s\"\r\n",csca);
  while (true) do
    local rsp, idx = sio_send_and_recv3(context, cmd, "\r\nOK\r\n", "\r\n+CME ERROR: SIM busy", "\r\nERROR\r\n");
	if (idx and idx == 1) then
	  break;
	end;
	vmsleep(100);
  end;
end;
--[[
FUNCTION switch_to_sm_sms_store
DESCRIPTION
  This function is used to switch current SMS storage to SIM
PARAMETERS
  store:
    "SM","ME"
RETURN VALUE
  None
]]
function sms_util_switch_to_store(context, store)
  local max_sms_number_in_store = 0;
  while (true) do
    local rsp, idx = sio_send_and_recv3(context, "AT+CPMS=\""..store.."\",\""..store.."\",\""..store.."\"\r\n", "\r\nOK\r\n", "\r\n+CME ERROR: SIM busy", "\r\nERROR\r\n");
	if (idx and idx == 1) then
	  max_sms_number_in_store = str_util_parse_sio_report_parameter(rsp,"\r\n+CPMS:",2,",",",",false);
	  if (max_sms_number_in_store) then
	    print("got max_sms_number_in_store=", max_sms_number_in_store, "\r\n");	  
	    max_sms_number_in_store = tonumber(max_sms_number_in_store);
	  else
	    max_sms_number_in_store = 20;
	  end;
	  break;
	end;
	vmsleep(100);
  end;
  return max_sms_number_in_store;
end;

function sms_util_get_new_ref(context)
  local rsp, exp_num = sio_send_and_recv2(context, "AT+CMGENREF\r\n", "\r\n+CMGENREF:", "\r\nERROR\r\n", 5000);
  if (exp_num and (exp_num == 1)) then
    local new_msg_ref = str_util_parse_sio_report_parameter(rsp,"\r\n+CMGENREF:",1,",","\r\n",false);
	if (new_msg_ref) then
	  new_msg_ref = tonumber(new_msg_ref);
	end;
	return new_msg_ref;
  else
    return nil;
  end;
end;

--------------------------------------------------------------------------
--[[
FUNCTION send_sms_with_ascii_string
DESCRIPTION
  This function is used to send a sms with ascii string
PARAMETERS
  
RETURN VALUE
  None
]]
function send_sms_with_ascii_string(context, dest_no, content, delimiter, max_retry)
  local rsp = nil;
  local exp_num = -1;
  local cmd = nil;
  local array = {};
  local array_item_idx = 1;

  if ((not content) or (string.len(content) == 0)) then
    print("empty sms content, just send it\r\n");
    return send_sms_with_ascii_string_array(context, dest_no, {}, max_retry);
  end;
  local idx = 1;
  idx = string.absfind(content, delimiter, idx);
  while (idx) do
    local item = "";
    --print("idx=", idx, "\r\n");
    if (idx > 1) then
      item = string.sub(content, 1, idx-1);
    elseif (idx == 1) then
      item = "";
    end;
    --print("item=", item,"\r\n");
    array[array_item_idx] = item;
    array_item_idx = array_item_idx + 1;
    if ((idx + string.len(delimiter) - 1) == string.len(content)) then
      content = "";
      break;
    end;
    --print("----content=", content, "\r\n");
    content = string.sub(content, idx + string.len(delimiter), string.len(content));
    --print("content=", content, "\r\n");
    idx = string.absfind(content, delimiter, idx);
    --vmsleep(3000);
  end;
  if (content and (string.len(content) > 0)) then
    --print("item=", content,"\r\n");
    array[array_item_idx] = content;
    array_item_idx = array_item_idx + 1;
    content = "";
  end;
  --print("dest_no=", dest_no, "\r\n");
  --for idx, cmd in pairs(array) do
      --print("cmd=", cmd, "\r\n");
  --end;
  return send_sms_with_ascii_string_array(context, dest_no, array, max_retry);
end;
--[[
FUNCTION send_sms_with_ascii_string_array
DESCRIPTION
  This function is used to send a sms with ascii string array
PARAMETERS
  
RETURN VALUE
  None
]]
function send_sms_with_ascii_string_array(context, dest_no, content, max_retry)
  print("send_sms_with_ascii_string_array\r\n");
  local final_content = "";
  if (content) then
    local line_idx = 0;		
    for idx, sms_line in pairs(content) do
      line_idx = line_idx + 1;
	  sms_line = str_util_convert_ascii_to_ucs2_text(sms_line, false);
	  if (line_idx == 1) then
		final_content = sms_line;
	  else
		final_content = final_content.."000D000A"..sms_line;
      end;
    end;
  end;    
  return send_sms_with_ucs2_string(context, dest_no, final_content, max_retry);
end;
--[[
FUNCTION send_sms_with_ucs2_string
DESCRIPTION
  This function is used to send a sms with ucs2(big endian) string array
PARAMETERS
  
RETURN VALUE
  None
]]
function send_sms_with_ucs2_string(context, dest_no, content, max_retry)
  local msg_ref = nil;
  local msg_seq = nil;
  local msg_total = nil;
  local len_each_packet = 60 * 4;
  
  dest_no = sys_util_get_ph_no_with_country_code(context, dest_no);
  if (string.len(content) > len_each_packet) then
    msg_ref = sms_util_get_new_ref(context);
	msg_total = (string.len(content) + len_each_packet - 1) / len_each_packet;
	msg_seq = 1;
  end;
  while (content) do
    local sms_data_to_send;
    if (string.len(content) > len_each_packet) then
	  sms_data_to_send = string.sub(content, 1, len_each_packet);
	  content = string.sub(content, len_each_packet+1, -1);
      print("++++++++ sms_data_to_send = ", sms_data_to_send, "\r\n");
      print("++++++++ content = ", content, "\r\n");
	else
	  sms_data_to_send = content;
	  content = nil;
	end;
	if (sms_data_to_send) then
	  if (not send_single_sms_with_ucs2_string(context, dest_no, sms_data_to_send, msg_ref, msg_seq, msg_total, max_retry)) then
	    print("++++++++ return false = ", dest_no, "\r\n");
        return false;
	  end;
      
      print("++++++++ dest_no = ", dest_no, "\r\n");
	end;
	if (msg_seq) then
	  msg_seq = msg_seq + 1;
	end;
  end;
  return true;
end;
--[[
FUNCTION send_single_sms_with_ucs2_string
DESCRIPTION
  This function is used to send a sms with ucs2(big endian) string array
PARAMETERS
  
RETURN VALUE
  None
]]
function send_single_sms_with_ucs2_string(context, dest_no, content, msg_ref, msg_seq, msg_total, max_retry)
  local rsp = nil;
  local exp_num = -1;
  local cmd = nil;
  local retry_count = 0;  
  if (not max_retry) then
    max_retry = 0;
  end;
  print("send_sms_with_ucs2_string, max_retry=", max_retry, "\r\n");
  dest_no = str_util_convert_ascii_to_ucs2_text(dest_no, false);
  while (true) do
    if (msg_ref and msg_seq and msg_total) then
	  cmd = string.format("AT+CMGSEX=\"%s\", %d, %d, %d, %d\r\n", dest_no, 128, msg_ref, msg_seq, msg_total);
	else
	  cmd = string.format("AT+CMGSEX=\"%s\"\r\n", dest_no);
	end;
	context.current_is_at_mode = false;
    rsp, exp_num  = sio_send_and_recv3(context, cmd,">", "ERROR", "+CMS ERROR",5000);
    if (exp_num == 1) then
	  local final_content = content;
	  --print("final_content=", final_content, "\r\n");
	  rsp, exp_num = sio_send_and_recv3(context, final_content.."\26","\r\nOK\r\n","\r\n+CMGSEX:", "\r\n+CMS ERROR", 60000);
	  context.current_is_at_mode = true;
      if (rsp and ((exp_num == 1) or (exp_num == 2))) then
        return true;
      end;
      if (max_retry and (retry_count < max_retry)) then
        retry_count = retry_count + 1;
      else
        return false;
      end;
    else
	  context.current_is_at_mode = true;
      if (max_retry and (retry_count < max_retry)) then
        retry_count = retry_count + 1;
      else
        return false;
      end;
    end;
  end;
  return false;
end;