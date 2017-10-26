--------------------------------------------------------------------------------
--脚本说明
--本脚本包含彩信相关操作函数
--------------------------------------------------------------------------------
function mms_util_init(context)
  print("mms_util_init\r\n");
  context.mms_proto_type = {};
  context.mms_proto_type.wap = 0;
  context.mms_proto_type.ip = 1;  
  
  context.need_alarm_after_mms_sending = false;
  
  context.sending_mms = false;
  context.sending_mms_max_retry = 0;  
  --mms_util_set_mmsc(context, context.mmsc_url);
  --mms_util_set_proto(context, 1, context.mms_proto_ip, context.mms_proto_port);
end;

--local lmms_wap_push_msg = "\r\n+WAP_PUSH_MMS: \"15001844675\",\"RROpJGJVyjeA\",\"http://211.136.112.84/RROpJGJVyjeA\",\"09/03/17,17:14:41+32\",0,13338";
function mms_util_get_location_in_wap_push(mms_wap_push_msg)
  return str_util_parse_sio_report_parameter(mms_wap_push_msg,"\r\n+WAP_PUSH_MMS:",3,",",",",true);
end;

function mms_util_set_mmsc(context, mmsc)
  local cmd = string.format("AT+CMMSCURL=\"%s\"\r\n",mmsc);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    return true;
  else
    return false;
  end;
end;

function mms_util_set_proto(context, prot, ip, port)
  local cmd = string.format("AT+CMMSPROTO=%d,\"%s\",%d\r\n",prot, ip, port);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    return true;
  else
    return false;
  end;
end;

function mms_util_edit(context, edit)
  local cmd = string.format("AT+CMMSEDIT=%d\r\n",edit);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    return true;
  else
    return false;
  end;
end;

function mms_util_set_title(context, title)
  local cmd = string.format("AT+CMMSDOWN=\"TITLE\",%d\r\n",string.len(title));
  local rsp, exp_num = sio_send_and_recv3(context, cmd,">","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    rsp, exp_num = sio_send_and_recv2(context, title,"\r\nOK\r\n","\r\nERROR\r\n", 5000);
	if (exp_num == 1) then
      return true;
	else
	  return false;
	end;
  else
    return false;
  end;
end;

function mms_util_add_file(context, dir, filename)
  local cmd = string.format("AT+CMMSDOWN=\"FILE\",%d, \"%s\"\r\n",dir, filename);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
	return true;
  else
    return false;
  end;
end;

function mms_util_add_attachment_with_content(context, att_type, content, fname)
  if (not att_type or not content or (string.len(content) == 0) or not fname) then
    return false;
  end;
  local cmd = string.format("AT+CMMSDOWN=\"%s\",%d,\"%s\"\r\n", att_type, string.len(content), fname);
  local rsp, idx = sio_send_and_recv2(context, cmd,">", "\r\nERROR\r\n");
  if (idx ~= 1) then
    return false;
  end;
  sio_send(context, content);
  --receive OK
  rsp, idx = sio_recv_contain3(context, "\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n",5000);
  if (idx ~= 1) then
    print("Failed to down file", fname,"\r\n");
    return false;
  end;
  return true;
end;

function mms_util_add_recpipt(context, receipt)
  local cmd = string.format("AT+CMMSRECP=\"%s\"\r\n",receipt);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
	return true;
  else
    return false;
  end;
end;

function mms_util_add_cc(context, cc)
  local cmd = string.format("AT+CMMSCC=\"%s\"\r\n",cc);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
	return true;
  else
    return false;
  end;
end;

function mms_util_add_bcc(context, bcc)
  local cmd = string.format("AT+CMMSBCC=\"%s\"\r\n",bcc);
  local rsp, exp_num = sio_send_and_recv3(context, cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
	return true;
  else
    return false;
  end;
end;

function mms_util_send_mms(context, max_retry)
  local rsp, exp_num = sio_send_and_recv3(context, "AT+CMMSSEND\r\n","\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  if (exp_num == 1) then
    context.sending_mms = true;
	context.sending_mms_max_retry = max_retry;
	rsp, exp_num = sio_recv_contain2(context, "\r\n+CMMSSEND: 0\r\n", "\r\n+CMMSSEND:", 1000*60*1);
	context.sending_mms = false;
	if (context.need_alarm_after_mms_sending) then
	  alarm_util_alarm(context);
	end;
	if (exp_num == 1) then
	  return true;
	else
	  return false;
	end;
  else
    return false;
  end;
end;

function mms_util_tak_picture_when_alarm_and_no_creg(context)
  if (context.use_tf_card and not tfcard_util_usb_is_udisk_configured_now(context)) then
    if (not fs_util_loca(context, context.fs_loca_type.tfcard)) then --save to sd card
      print("failed to call fs_util_loca\r\n");
      return false;
    end;
  end; 
  local started_camera_for_mms = false;
  if (not cam_util_camera_started(context)) then
    if (cam_util_start_camera(context)) then
	  started_camera_for_mms = true;
	else
	  return false;
	end;
  else
    print("camera already opened, return error\r\n");
    return false;
  end;
  if (not cam_util_take_picture(context)) then
    return false;
  end;
  local pic_file = cam_util_save_picture(context);
  if (not pic_file) then
    return false;
  end;
  if (started_camera_for_mms) then
   cam_util_stop_camera(context);
  end;
  pic_file = str_util_replace(pic_file, "/", "\\");
  if (not pic_file) then
    return false;
  end;
  local pic_filename = pathtofilename(pic_file);
  if (not pic_filename) then
    return false;
  end;
  if (context.use_tf_card and tfcard_util_usb_is_udisk_configured_now(context)) then
    if (not fs_util_loca(context, context.fs_loca_type.flash)) then --save to ue flash
      print("failed to call fs_util_loca\r\n");
    end;
  end;
  return pic_filename;
end;

function mms_util_send_a_picture_to_multiple_mms(context, report_phone_nums, is_alarm, max_retry)
  local cgreg = nw_util_get_cgreg(context, true);
  if (not cgreg or (cgreg ~= 1)) then
    return false;
  end;
  local phone_num_count = table.maxn(report_phone_nums);
  if (phone_num_count == 0) then
    return true;
  end;
  if (is_alarm and context.use_tf_card and not tfcard_util_usb_is_udisk_configured_now(context)) then
    if (not fs_util_loca(context, context.fs_loca_type.tfcard)) then --save to sd card
      print("failed to call fs_util_loca\r\n");
      return false;
    end;
  end; 
  local started_camera_for_mms = false;
  if (not cam_util_camera_started(context)) then
    if (cam_util_start_camera(context)) then
	  started_camera_for_mms = true;
	else
	  return false;
	end;
  else
    print("camera already opened, return error\r\n");
    return false;
  end;
  if (not cam_util_take_picture(context)) then
    return false;
  end;
  local pic_file = cam_util_save_picture(context);
  if (not pic_file) then
    return false;
  end;
  if (started_camera_for_mms) then
   cam_util_stop_camera(context);
  end;
  pic_file = str_util_replace(pic_file, "/", "\\");
  if (not pic_file) then
    return false;
  end;
  local pic_filename = pathtofilename(pic_file);
  if (not pic_filename) then
    return false;
  end;
  local dir_no = fs_util_get_dir_no(context, pic_file);
  if (not dir_no) then
    return false;
  end;
  
  local success = true;
  for idx = 1, phone_num_count, 1 do
    local phone_num = report_phone_nums[idx];
	if (phone_num and (string.len(phone_num) > 0)) then
	  if (not mms_util_send_a_file_to_single_mms(context, phone_num, dir_no, pic_filename, max_retry)) then
	    success = false;
	  end;
	end;
  end;
  if (is_alarm and context.use_tf_card and tfcard_util_usb_is_udisk_configured_now(context)) then
    if (not fs_util_loca(context, context.fs_loca_type.flash)) then --save to ue flash
      print("failed to call fs_util_loca\r\n");
    end;
  end;
  if (not is_alarm) then
    os.remove(pic_file);
  end;
  return success;
end;

function mms_util_send_a_file_to_single_mms(context, report_phone_num, dir_no, att_filename, max_retry)
  print("mms_util_send_a_picture_to_single_mms, phone_num=", report_phone_num, "\r\n");
  local result = true;
  if (not max_retry) then
    max_retry = 0;
  end;  
  local cgreg = nw_util_get_cgreg(context, true);
  if (not cgreg or (cgreg ~= 1)) then
    return false;
  end;
  if (not mms_util_edit(context, 1)) then
    return false;
  end;
  if (not mms_util_set_title(context, "report pic")) then
    return false;
  end;
  if (not mms_util_add_file(context, dir_no, att_filename)) then
    return false;
  end;
  if (not mms_util_add_recpipt(context, report_phone_num)) then
    return false;
  end;
  --[[
  if (not nw_util_set_cgsockcont(context, context.mms_pdp_apn)) then
    return false;
  end;
  --]]
  local tried_times = 0;
  while (tried_times <= max_retry) do
    if (not mms_util_send_mms(context)) then
	  if (tried_times <= max_retry) then
	    print("failed to send mms, try again\r\n");		
	  else
        print("ERROR! failed to send mms\r\n");
        result = false;
		break;
	  end;
	else
	  break;
    end;
	tried_times = tried_times + 1;
  end;
  --if (not nw_util_set_cgsockcont(context, context.pdp_apn)) then
    --return false;
  --end;
  return result;
end;

--[[
FUNCTION sio_mms_evt_cmmssend_handler
DESCRIPTION
  This function is used to handle +CMMSSEND sio report
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
function sio_mms_evt_cmmssend_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  context.sending_mms = false;
  local sio_header = "\r\n+CMMSSEND:";
  local err_code = str_util_parse_sio_report_parameter(context.sio_rcvd_string,sio_header,1,",","\r\n",false); 
  
  local sio_header_end_pos = string.absfind(context.sio_rcvd_string, "\r\n", string.len(sio_header)+1);
  if (sio_header_end_pos > 0) then
    sio_header_end_pos = sio_header_end_pos + 1;
  end;
  if (string.len(context.sio_rcvd_string) > sio_header_end_pos) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, sio_header_end_pos+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
  if (err_code ~= 0) then
    if (context.sending_mms_max_retry > 0) then
	  context.sending_mms_max_retry = sending_mms_max_retry - 1;
	  mms_util_send_mms(context);
	else
	  
	end;
  end;
end;

--[[
FUNCTION sio_mms_evt_wap_push_mms_handler
DESCRIPTION
  This function is used to handle +WAP_PUSH_MMS sio report
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
function sio_mms_evt_wap_push_mms_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  context.sending_mms = false;
  local sio_header = "\r\n+WAP_PUSH_MMS:";  
  local url = mms_util_get_location_in_wap_push(context.sio_rcvd_string);
  
  local sio_header_end_pos = string.absfind(context.sio_rcvd_string, "\r\n", string.len(sio_header)+1);
  if (sio_header_end_pos > 0) then
    sio_header_end_pos = sio_header_end_pos + 1;
  end;
  if (string.len(context.sio_rcvd_string) > sio_header_end_pos) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, sio_header_end_pos+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;
function mms_util_unit_test_after_all_configured(context)
  sio_sms_cmt_mms_handler(context, "", "15021309668", "", "004D004D0053002000310035003000320031003300300039003600360038")
end;