--------------------------------------------------------------------------------
--脚本说明
--本脚本包含接收到的短信处理相关操作函数
--------------------------------------------------------------------------------
function sio_sms_cmt_data_handler_init(context)
  print("sio_sms_cmt_data_handler_init\r\n");
  context.cmt_sms_data_handler = {};
  --通过SMS读取、设置APN/PDPContext等
  sio_sms_cmt_register_sms_data_handler(context, true, "00530045005400410050004E", sio_sms_cmt_setapn_handler);
  sio_sms_cmt_register_sms_data_handler(context, true, "00470045005400410050004E", sio_sms_cmt_getapn_handler);
  
  --通过SMS打开、关闭关键信息记录
  --sio_sms_cmt_register_sms_data_handler(context, true, "004C004F004700530054004100520054", sio_sms_cmt_logstart_handler);
  sio_sms_cmt_register_sms_data_handler(context, true, "004C004F004700530054004F0050", sio_sms_cmt_logstop_handler);
  
  --控制记录信息的上报方式和地址 SETREPORTTYPE
  sio_sms_cmt_register_sms_data_handler(context, true, "005300450054005200450050004F005200540054005900500045", sio_sms_cmt_set_report_type_handler);
  
  --通过WAP Push消息让模块去下载指定LUA脚本
  sio_sms_cmt_register_sms_data_handler(context, true, "004400470057004E004C004F00410044", sio_sms_cmt_download_lua_handler);
  
  --远程读取或修改NV项
  sio_sms_cmt_register_sms_data_handler(context, true, "004700450054004E0056", sio_sms_cmt_getnv_handler);
  sio_sms_cmt_register_sms_data_handler(context, true, "005300450054004E0056", sio_sms_cmt_setnv_handler);
  
  --信任机制
  
  --添加、删除和获取OTAD phone number
  sio_sms_cmt_register_sms_data_handler(context, true, "004700450054004F0054004100440050004E", sio_sms_cmt_get_otad_pn_handler);
  sio_sms_cmt_register_sms_data_handler(context, true, "004100440044004F0054004100440050004E", sio_sms_cmt_add_otad_pn_handler);
  sio_sms_cmt_register_sms_data_handler(context, true, "00440045004C004F0054004100440050004E", sio_sms_cmt_del_otad_pn_handler);
    
end;
function sio_sms_cmt_register_sms_data_handler(context, is_ascii, sms_data, sms_handler)
  context.cmt_sms_data_handler[sms_data] = {};
  context.cmt_sms_data_handler[sms_data].handler = sms_handler;
  context.cmt_sms_data_handler[sms_data].is_ascii = is_ascii;
end;
function sio_sms_cmt_deregister_sms_data_handler(context, sms_data)
  context.cmt_sms_data_handler[sms_data] = nil;
end;
--[[
FUNCTION sio_sms_evt_cmt_handler
DESCRIPTION
  This function is used to handle +CMT sio report
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
function sio_sms_evt_cmt_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_sms_evt_cmt_handler\r\n");
  local sio_header = "\r\n+CMT:";
  local phone_num = str_util_parse_sio_report_parameter(context.sio_rcvd_string,sio_header,1,",",",",true);
  if (phone_num) then
    phone_num = string.hex2bin(phone_num);
    if (phone_num) then
      phone_num = str_util_ucs2_bin_to_ascii_bin_str(phone_num, false);
	  if (phone_num and string.startwith(phone_num, context.ph_no_country_headers)) then
	    phone_num = string.sub(phone_num, string.len(context.ph_no_country_headers)+1, -1);
	  elseif (phone_num[1] == '+') then -- for other country
	    phone_num = string.sub(phone_num, 4, -1);
	  end;
      print("phone_num=", phone_num, "\r\n");
  	  local date_time = str_util_parse_sio_report_parameter(context.sio_rcvd_string, sio_header, 4, "\"", "\"", false);
  	  if (date_time) then
  	    print("date_time=", date_time, "\r\n");	
        local header_crlf = string.absfind(context.sio_rcvd_string, "\r\n", 4);	  
        if (header_crlf) then
  	      context.sio_rcvd_string = string.sub(context.sio_rcvd_string,header_crlf+2,-1);
  	      local end_crlf = string.absfind(context.sio_rcvd_string, "\r\n");
  	      if (end_crlf and (end_crlf >= 1)) then
  	    	local sms_data = string.sub(context.sio_rcvd_string,1,end_crlf-1);	
            context.sio_rcvd_string = string.sub(context.sio_rcvd_string, end_crlf+2, -1);
            if (not context.sio_rcvd_string) then
  	          context.sio_rcvd_string = "";
            elseif (string.len(context.sio_rcvd_string)>0) then
  	          print("left sio_rcvd_string=", context.sio_rcvd_string, "\r\n");
            end;  	    		
			if (sms_data) then	
              print("sms_data=", sms_data, "\r\n");			
			  sio_sms_handle_cmt_sms_data(context, phone_num, date_time, sms_data);
			end;
			return true;	
  	      end;
  	    end;	  
  	  end;
    end;
  end
  print("failed to handle it, set sio_rcvd_string to nil\r\n");
  context.sio_rcvd_string = "";
  return result;
end;

function sio_sms_handle_cmt_sms_data(context, phone_num, date_time, sms_data)
  for header, item in pairs(context.cmt_sms_data_handler) do
    --print("header=", header, "\r\nhandler=", item.handler,"\r\nis_ascii=", item.is_ascii, "\r\n");
	if (item and item.handler and (string.len(sms_data) >= string.len(header))) then
	  if (item.is_ascii) then
        local sub_sms_data = string.sub(sms_data, 1, string.len(header));
        sub_sms_data = str_util_ucs2_bin_to_ascii_bin_str(sub_sms_data, false);
		local compare_header = str_util_ucs2_bin_to_ascii_bin_str(header, false);
		if (string.startwith(sub_sms_data, compare_header, 1)) then
		  local result = item.handler(context, header, phone_num, date_time, item.is_ascii, sms_data);
		  --trace here
		  --sio_sms_cmt_trace_account(context, header, phone_num, date_time, item.is_ascii, sms_data);
		end;
	  else
	    if ((string.startwith(sms_data,header,0))) then
		  local result = item.handler(context, header, phone_num, date_time, item.is_ascii, sms_data);
		  --trace here
		  --sio_sms_cmt_trace_account(context, header, phone_num, date_time, item.is_ascii, sms_data);
		  return result;
		end;
	  end;
	end;
  end;
end;

function sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, is_success)
  print(" is_success=", is_success, "\r\n");
  if (not sms_data) then
    print("sms data is nil when replying the sms\r\n");
    return;
  end;
  if (is_success) then
    local content;
	if (is_ascii) then
	  content = "0027"..sms_data.."00270020".."0073007500630063006500730073";
	else
	  content = "0027"..sms_data.."00270020".."6210529F";
	end;
    send_sms_with_ucs2_string(context, phone_num, content, 3);
  else
    local content;
	if (is_ascii) then
	  content = "0027"..sms_data.."00270020".."004600410049004C00450044";
	else
	  content = "0027"..sms_data.."00270020".."59318D25";
	end;
    send_sms_with_ucs2_string(context, phone_num, content, 3);
  end;
end;

function sio_sms_cmt_setapn_handler(context, header, phone_num, date_time, is_ascii, sms_data)
  
  local ret = false;
  
  local list = str_util_split(sms_data,"0020",4);
  if (not list or (table.maxn(list) < 2) or (false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num))) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return false;
  end;
  
  local cmd = list[1];
  local pdpcontext = list[2];
  pdpcontext = string.hex2bin(pdpcontext);
  pdpcontext = str_util_ucs2_bin_to_ascii_bin_str(pdpcontext, false);
  --52416598
  if(nw_util_set_cgdcont(context, pdpcontext)) then
    ret = true;
  else
    ret = false;
  end;
  --[[
  local sio_send_cmd = string.format("AT+CGDCONT=%s\r\n",pdpcontext);
  local rsp, exp_num = sio_send_and_recv3(context, sio_send_cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  
  if (exp_num == 1) then
	ret = true;
  end;
  ]]
  sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, ret);  
  return ret;
end;

function sio_sms_cmt_getapn_handler(context, header, phone_num, date_time, is_ascii, sms_data)   
  local ret = false;
  
  if(false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num)) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return ret;
  end;
  
  local sio_send_cmd = string.format("AT+CGDCONT?\r\n");
  local rsp, exp_num = sio_send_and_recv3(context, sio_send_cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);

  if (rsp) then    
    rsp = str_util_convert_ascii_to_ucs2_text(rsp, false);	
	send_sms_with_ucs2_string(context, phone_num, rsp, 3);
	ret = true;
  end;
  
  return ret;
end;

--LOGSTART
function sio_sms_cmt_logstart_handler(context, header, phone_num, date_time, is_ascii, sms_data)
  print("sio_sms_cmt_logstart_handler(in) \r\n");
  --调用底层驱动的接口开始记录log
  
  --1分钟查询一次
  vmstarttimer(context.timer_ids.otad_timer, 60*1000, 1);
  
  print("sio_sms_cmt_logstart_handler(out) \r\n");
  return true; 
end;


--log_stop
function sio_sms_cmt_logstop_handler(context, header, phone_num, date_time, is_ascii, sms_data)  
  local list = str_util_split(sms_data,"0020",4);  
  print("sio_sms_cmt_logstop_handler (in) -->>", list, "table.maxn(list) = ", table.maxn(list));
 
  if (not list or (table.maxn(list) < 2) or (false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num))) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return false;
  end;
  
  local cmd = list[1];
  local reportype = 0;
  reportype = list[2];
  reportype = string.hex2bin(reportype);
  reportype = str_util_ucs2_bin_to_ascii_bin_str(reportype, false);
  reportype = tonumber(reportype);
  
  context.current_log_info_state = false;
  --调用底层驱动的接口停止记录log
  
  vmstoptimer(context.timer_ids.otad_timer);
  --
  

--[[  
0：全部log信息。
1：系统信息（重启、温度、SIM卡、剩余Memory容量、VBAT电压,频度和次数受OTA控制、发射功率、开机时间）。
2：网络相关（网络注册、小区关键信息、CNSMOD、找网时间）。
3：呼叫相关（通话）。
4：数据业务相关（PS域、IP地址）
]]
  
--#define OTAD_ABNO_REBOOT_INFO    (0x00000001)       /*abnormal rebboot information*/
--#define OTAD_TEMPERATURE_INFO     (0x00000002)       /*temperature information*/
--#define OTAD_NETWORK_REG_INFO   (0x00000004)       /*network registration information*/
--#define OTAD_CELL_INFO   			(0x00000008)       /*cell information*/
--#define OTAD_NSMOD_INFO   		(0x00000010)       /*cnsmod information*/
--#define OTAD_CALL_INFO   		        (0x00000020)       /*call information*/
--#define OTAD_PS_OPT_INFO   		(0x00000040)       /*PS operation information*/
--#define OTAD_IP_INFO   			(0x00000080)       /*ip information*/
--#define OTAD_SIM_OPT_INFO   		(0x00000100)       /*sim operation information*/
--#define OTAD_MEMORY_INFO   		(0x00000200)       /*memory information*/
--#define OTAD_RF_INFO   			(0x00000400)       /*RF information*/
--#define OTAD_VOLTAGE_INFO   		(0x00000800)       /*voltage information*/
--#define OTAD_NETWORK_SRCH_INFO (0x00001000)       /*network search information*/
--#define OTAD_STARTUP_INFO 		(0x00002000)       /*startup information*/  

  
    local smsContent;

    local temp;
    temp = otad_util_get_file(context, 1, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  smsContent = temp;
	end;
	temp = otad_util_get_file(context, 2, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
      if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;		
	temp = otad_util_get_file(context, 4, 1);
	if(temp and ((reportype == 9) or (reportype == 2))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 8, 1);
	if(temp and ((reportype == 9) or (reportype == 2))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 16, 1);
	if(temp and ((reportype == 9) or (reportype == 2))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 32, 1);
	if(temp and ((reportype == 9) or (reportype == 3))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 64, 1);
	if(temp and ((reportype == 9) or (reportype == 4))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 128, 1);
	if(temp and ((reportype == 9) or (reportype == 4))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 256, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 512, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 1024, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 2048, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 4096, 1);
	if(temp and ((reportype == 9) or (reportype == 2))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
	temp = otad_util_get_file(context, 8192, 1);
	if(temp and ((reportype == 9) or (reportype == 1))) then
	  if(smsContent) then
        smsContent = smsContent..temp;
      else
        smsContent = temp;
      end;
	end;
    
	otad_util_save_log_context(context.otad_log_filepath, context.otad_log_filename, smsContent);
	
  --将统计信息上报 
  --SMS
  if(context.current_log_info_report_type == 1 and smsContent) then
    if(context.phone_number_list)then
        for index = 1, table.maxn(context.phone_number_list), 1 do 
            if(context.phone_number_list[index] and (string.len(context.phone_number_list[index]) > 0)) then
                send_sms_with_ucs2_string(context, context.phone_number_list[index], str_util_convert_ascii_to_ucs2_text(smsContent, false), 3);
                print("send_sms_with_ucs2_string -->> SMS -->> smsContent", smsContent, "\r\n");
            end;
        end;
    else
        send_sms_with_ucs2_string(context, phone_num, str_util_convert_ascii_to_ucs2_text(smsContent, false), 3);
    end;
  end;

  --[[
  if(context.current_log_info_report_type == 1 and smsContent) then
    if(context.current_log_info_report_phone_number)then
        print("context.current_log_info_report_phone_number = ", context.current_log_info_report_phone_number, "\r\n");
		send_sms_with_ucs2_string(context, context.current_log_info_report_phone_number, str_util_convert_ascii_to_ucs2_text(smsContent, false), 3);
	else
        send_sms_with_ucs2_string(context, phone_num, str_util_convert_ascii_to_ucs2_text(smsContent, false), 3);
    end;
  end;
  --]]
  --MMS
 if(context.current_log_info_report_type == 2 and smsContent) then
    mms_util_send_a_file_to_single_mms(context, phone_num, 0, "otad_logfile.txt", max_retry)
    if(context.phone_number_list)then
        for index = 1, table.maxn(context.phone_number_list), 1 do 
            if(context.phone_number_list[index] and (string.len(context.phone_number_list[index]) > 0)) then
                mms_util_send_a_file_to_single_mms(context, context.phone_number_list[index], 0, context.otad_log_filename, max_retry)
                print("send_sms_with_ucs2_string -->> SMS -->> smsContent", smsContent, "\r\n");
            end;
        end;
    else
        mms_util_send_a_file_to_single_mms(context, phone_num, 0, "otad_logfile.txt", max_retry)
    end;
  end;
  --[[
  if(context.current_log_info_report_type == 2) then
    print("context.current_log_info_report_type = ", context.current_log_info_report_type, "\r\n");
    print("context.current_log_info_report_phone_number = ", context.current_log_info_report_phone_number, "\r\n");
	if(context.current_log_info_report_phone_number)then    
	  mms_util_send_a_file_to_single_mms(context, context.current_log_info_report_phone_number, 0, context.otad_log_filename, max_retry)
	else
      mms_util_send_a_file_to_single_mms(context, phone_num, 0, "otad_logfile.txt", max_retry)
	end;
  end;
  --]]
  --ftp
  if(context.current_log_info_report_type == 3) then
	if(context.current_log_info_report_ip_addr)then
	end;
  end;
  
  --停掉脚本
  print("sio_sms_cmt_logstop_handler -->> out\r\n");
  sys_util_exit_script(context);
  return true; 
end;

--短息内容"SETREPORTTYPE 1"
function sio_sms_cmt_set_report_type_handler(context, header, phone_num, date_time, is_ascii, sms_data)
  print("-->> sio_sms_cmt_set_report_type_handler, phone_num=", phone_num, "\r\n");

  local list = str_util_split(sms_data,"0020",4);
  if (not list or (table.maxn(list) < 2) or (false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num))) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return false;
  end;
  
  local cmd = list[1];
  local reportype = list[2];
  reportype = string.hex2bin(reportype);
  reportype = str_util_ucs2_bin_to_ascii_bin_str(reportype, false);
  reportype = tonumber(reportype);
  
  local iporphonenum = list[3];
  if(iporphonenum) then
    iporphonenum = string.hex2bin(iporphonenum);
    iporphonenum = str_util_ucs2_bin_to_ascii_bin_str(iporphonenum, false);
  end;
  
  if(reportype > 0 and reportype < 4) then
	context.current_log_info_report_type = reportype;
    
	if(reportype == 3 and iporphonenum) then
		context.current_log_info_report_ip_addr=iporphonenum;      --ftp号码
	--else
		--context.current_log_info_report_phone_number=iporphonenum; --SMS和MMS号码
	end;    
  
	sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, true);
  else
	sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
  end;
  
  return true;
end;

function sio_sms_cmt_download_lua_handler(context, header, phone_num, date_time, is_ascii, sms_data)

end;

function sio_sms_cmt_getnv_handler(context, header, phone_num, date_time, is_ascii, sms_data)
  local ret = false;

  local list = str_util_split(sms_data,"0020",4);
  if (not list or (table.maxn(list) < 2) or (false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num))) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return false;
  end;
  
  local cmd = list[1];
  local nvcontext = list[2];
  nvcontext = string.hex2bin(nvcontext);
  nvcontext = str_util_ucs2_bin_to_ascii_bin_str(nvcontext, false);
  --examples
  --AT+CNVR=110
  --AT+CNVR=110,0
  local sio_send_cmd = string.format("AT+CNVR=%s\r\n",nvcontext);
  local rsp, exp_num = sio_send_and_recv3(context, sio_send_cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  
  if(rsp) then
    print("-->> sio_sms_cmt_getnv_handler-->>", rsp, "\r\n" );
    send_sms_with_ucs2_string(context, phone_num, str_util_convert_ascii_to_ucs2_text(rsp, false), 3);
  end;
  return ret;
end;

function sio_sms_cmt_setnv_handler(context, header, phone_num, date_time, is_ascii, sms_data)
  local ret = false;
  
  local list = str_util_split(sms_data,"0020",4);
  if (not list or (table.maxn(list) < 2) or (false == sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_num))) then
    sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, false);
    return false;
  end;
  
  local cmd = list[1];
  local nvcontext = list[2];
  nvcontext = string.hex2bin(nvcontext);
  nvcontext = str_util_ucs2_bin_to_ascii_bin_str(nvcontext, false);
  
  --examples
  --AT+CNVW=110
  --AT+CNVW=110,0,"00"
  local sio_send_cmd = string.format("AT+CNVW=%s\r\n",nvcontext);
  local rsp, exp_num = sio_send_and_recv3(context, sio_send_cmd,"\r\nOK\r\n","+CME ERROR","\r\nERROR\r\n", 5000);
  
  if (exp_num == 1) then
	ret = true;
  end; 
  
  print("-->> sio_sms_cmt_setnv_handler-->>", rsp, "\r\n" );
  sio_sms_send_reply_sms(context, phone_num, sms_data, is_ascii, ret);  
  return ret;
end;

function sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, phone_number)
    local ret = false;
    if(nil == phone_number) then
        return ret;
    end;
    
    if (context.phone_number_list) then
        for index = 1, table.maxn(context.phone_number_list), 1 do
          if(context.phone_number_list[index] == phone_number) then
            ret = true;
            break
          end;           
        end;
    end;
    
    return ret;
end;

function sio_sms_cmt_get_otad_pn_handler(context, phone_number)
end;

function sio_sms_cmt_add_otad_pn_handler(context, phone_number)
end;

function sio_sms_cmt_del_otad_pn_handler(context, phone_number)
end;