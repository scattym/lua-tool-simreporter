--------------------------------------------------------------------------------
--脚本说明
--本脚本包含系统功能相关操作函数
--------------------------------------------------------------------------------
function sys_util_init(context)
  print("sys_util_init\r\n"); 
  context.sys_ports_access_mode_type = {};
  context.sys_ports_access_mode_type.user_normal_mode = 0;
  context.sys_ports_access_mode_type.user_update_mode = 1;
  context.sys_ports_access_mode_type.full_develop_mode = 63;
  
  context.cnmp_type = {};
  context.cnmp_type.gw = 2;
  context.cnmp_type.gsm = 13;
  context.cnmp_type.wcdma = 14;  
  
  context.sys_info = {};  
end;

function sys_util_process_after_init(context)
  local mode, forced = sys_util_get_sys_ports_access_mode(context);
  if (not context.full_access_mode and not forced and (mode ~= context.sys_ports_access_mode_type.user_normal_mode)) then
    --disable AT, DIAG, MODEM ports which then cannot be accessed by external MCU
    sys_util_set_sys_ports_access_mode(context, context.sys_ports_access_mode_type.user_normal_mode);
  end;
  if (not context.force_gw_cnma) then
    sys_util_set_cnmp_type(context, context.cnmp_type.wcdma);
  else
    sys_util_set_cnmp_type(context, context.cnmp_type.gw);
  end;
  --get system IMEI
  sys_util_get_imei(context);
  --set time zone
  --[[
  local time_zone = sys_util_get_time_zone(context);
  print("time_zone=", time_zone, "\r\n");
  if (not time_zone) then
    --adjust time_zone
	sys_util_set_time_zone(context, context.time_zone_mul_4);
  end;
  --]]
end;

function sys_util_reboot(context)
  local rsp, idx = sio_send_and_recv2(context, "AT+CRESET\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx == 1) then
    return true;
  else
    return false;
  end;
end;

function sys_util_exit_script(context)
  evt_util_exit_script(context);
end;

function sys_util_restart_script(context)
  os.restartscript();
end;

function sys_util_set_cnmp_type(context, mode)
  local rsp, idx = sio_send_and_recv2(context, "AT+CNMP="..mode.."\r\n", "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx == 1) then
    return true;
  else
    return false;
  end;
end;

function sys_util_set_sys_ports_access_mode(context, mode)
  print("sys_util_set_sys_ports_access_mode, mode=", mode, "\r\n");
  os.setportmode(mode);
end;

function sys_util_get_sys_ports_access_mode(context)
  return os.getportmode();
end;

function sys_util_get_imei(context)
  if (not context.sys_info.imei) then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+SIMEI?\r\n","\r\n+SIMEI:","\r\nERROR\r\n", 5000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+SIMEI:";
    local imei = str_util_parse_sio_report_parameter(rsp,rpt,1,",","\r\n",false);
    if (imei) then 
	  context.sys_info.imei = imei;	  
    end;
  end;
  print("imei=", context.sys_info.imei, "\r\n");
  return context.sys_info.imei;
end;

function sys_util_get_time_zone(context)
  print("sys_util_get_time_zone\r\n");
  local time_zone;
  local rsp = nil;
  while (true) do
    rsp, idx = sio_send_and_recv2(context, "AT+CCLK?\r\n", "\r\n+CCLK:", "\r\nERROR\r\n", 5000);
    if (idx == 1) then
      break;
    end;
  end;
  pos = string.absfind(rsp, ":");
  if (not pos) then
    print("sys_util_get_time_zone failed 15\r\n");
    return nil;
  end;
  pos = string.absfind(rsp, ":", pos+1);
  if (not pos) then
    print("sys_util_get_time_zone failed 16\r\n");
    return nil;
  end;
  pos_end = string.absfind(rsp, "\"\r\n", pos+1);
  if (not pos_end) then
    print("sys_util_get_time_zone failed 17\r\n");
    return nil;
  end;
  rsp  = string.sub(rsp, pos+1, pos_end-1);
  if (not rsp) then
    print("sys_util_get_time_zone failed 18\r\n");
    return nil;
  end;
  --print("rsp=", rsp, "\r\n");
  local negative = false;
  pos = string.absfind(rsp, "+");
  if (not pos) then
    pos = string.absfind(rsp, "-");
	if (pos) then
	  negative = true;
	end;
  end;
  if (pos) then
    rsp = string.sub(rsp, pos+1, -1);
	if (rsp and (string.len(rsp) > 0)) then
	  time_zone = rsp;
	end;
  end;
  print("string time_zone = ", time_zone, "\r\n");
  if (time_zone and (string.len(time_zone) > 0)) then
    time_zone = tonumber(time_zone);
	if (negative) then
	  time_zone = 0-time_zone;
	end;
  else
    time_zone = nil;
  end;
  return time_zone;
end;

function sys_util_set_time_zone(context, time_zone)
  print("sys_util_set_time_zone, time_zone=", time_zone, "\r\n");
  local sign_time_zone = "+";
  if (time_zone > 0) then
    sign_time_zone = "+";
  elseif (time_zone < 0) then
    sign_time_zone = "-";
  end;
  
  local dt = os.date("*t", time_value);
  local year = dt.year;
  if (year >= 2000) then
    year = year - 2000;
  else
    year = 11;--default 2011
  end;
  local cmd_str;
  cmd_str = string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d%s%d\"\r\n", year, dt.month, dt.day, dt.hour, dt.min, dt.sec, sign_time_zone, math.abs(time_zone));
  print("cmd_str=", cmd_str, "\r\n");
  rsp, idx = sio_send_and_recv2(context, cmd_str, "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx ~= 1) then
    return false;
  end;
  return true;
end;

function sys_util_set_sys_time(context, tmp_year, tmp_month, tmp_day, tmp_hour, tmp_minute, tmp_second, time_zone)
  print("sys_util_set_sys_time\r\n");
  if (not tmp_year or not tmp_month or not tmp_day or not tmp_hour or not tmp_minute or not tmp_second) then
    print("time parameters have nil value\r\n");
	return false;
  end;
  if (not time_zone) then
    time_zone = sys_util_get_time_zone(context);--context.time_zone_mul_4;
  else
    time_zone = time_zone * 4;
  end;
  if (not time_zone) then
    time_zone = context.time_zone_mul_4;
  end;
  local time_adjust = (time_zone/4)*3600;
  local time_value = os.time({year=tmp_year,month=tmp_month,day=tmp_day,hour=tmp_hour,min=tmp_minute,sec=tmp_second}) ;
  if (not time_value) then
    return false;
  end;
  --time_value = time_value + time_adjust;
  dt = os.date("*t", time_value);
  local sign_time_zone = "+";
  if (time_zone > 0) then
    sign_time_zone = "+";
  elseif (time_zone < 0) then
    sign_time_zone = "-";
  end;
  local year = dt.year;
  if (year >= 2000) then
    year = year - 2000;
  else
    year = 11;
  end;
  
  local cmd_str;
  cmd_str = string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d%s%d\"\r\n", year, dt.month, dt.day, dt.hour, dt.min, dt.sec, sign_time_zone, math.abs(time_zone));
  rsp, idx = sio_send_and_recv2(context, cmd_str, "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx ~= 1) then
    return false;
  end;
  return true;
end;

function sys_util_adjust_sys_time(context, seconds_diff)
  print("sys_util_adjust_sys_time, seconds_diff=", seconds_diff, "\r\n");
  if (not seconds_diff) then
    print("sys_util_adjust_sys_time returns for seconds_diff is nil\r\n");
	return false;
  end;
  local time_value = os.time() + seconds_diff;
  local time_zone = sys_util_get_time_zone(context);--context.time_zone_mul_4;
  if (not time_zone) then
	time_zone = context.time_zone_mul_4;
  end;  
  local time_adjust = (time_zone/4)*3600;
  time_value = time_value + time_adjust;
  dt = os.date("*t", time_value);
  local sign_time_zone = "+";
  if (time_zone > 0) then
    sign_time_zone = "+";
  elseif (time_zone < 0) then
    sign_time_zone = "-";
  end;
  local year = dt.year;
  if (year >= 2000) then
    year = year - 2000;
  else
    year = 11;
  end;
  local cmd_str;
  cmd_str = string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d%s%02d\"\r\n", year, dt.month, dt.day, dt.hour, dt.min, dt.sec, sign_time_zone, math.abs(time_zone));
  rsp, idx = sio_send_and_recv2(context, cmd_str, "\r\nOK\r\n", "\r\nERROR\r\n", 5000);
  if (idx ~= 1) then
    return false;
  end;
  return true;
end;

function sys_util_get_ph_no_with_country_code(context, phone_no)
  if (not phone_no or (string.len(phone_no) == 0)) then
    return phone_no;
  end;
  if (not context.disable_add_country_code_ph_no) then
    if (phone_no and (string.len(phone_no) > 0) and ((phone_no[1] ~= '+')) and context.ph_no_country_headers) then
	  phone_no = context.ph_no_country_headers..phone_no;
	end;
  end;
  return phone_no;
end;

function sys_util_unit_test(context)
  print("sys_util_unit_test\r\n");
  local time_zone = sys_util_get_time_zone(context);
  print("time_zone = ", time_zone, "\r\n");
  
  if (not time_zone) then
    --adjust time_zone
	sys_util_set_time_zone(context, context.time_zone_mul_4);
  end;
  vmsleep(5000);
end;