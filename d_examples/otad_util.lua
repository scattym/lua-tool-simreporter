--------------------------------------------------------------------------------
--脚本说明
--本脚本包含OTAD测试项目处理相关操作函数
--------------------------------------------------------------------------------
--[[
FUNCTION otad_util_otad_timer_timer_handler_proc
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
function otad_util_otad_timer_timer_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("otad_util_otad_timer_timer_handler_proc(in)\r\n");
  if (evt ~= context.evt.timer) then
    return;
  end;
  if (evt_p1 ~= context.timer_ids.otad_timer) then
    return;
  end;  
  
  --保存电压大小
  otad_util_voltage_info(context);
  
  --memory
  otad_util_memory_info(context);
  
  --温度
  otad_util_temperature_info(context);
  
  --cell
  otad_util_cell_info(context);
  
  print("otad_util_otad_timer_timer_handler_proc(out)\r\n");
end;

--网络信息保存
function otad_util_process_network_info(context, csq, cnsmod, creg, cgreg)
	print("otad_util_process_network_info (in)\r\n"); 
	local networkinfo = "CREG="..creg.." CGREG="..cgreg.." CSQ="..csq;
	otad_util_network_reg_info(context, networkinfo);
	print("otad_util_process_network_info (1) -->> ", networkinfo, "\r\n"); 
	if(cnsmod) then	    
	    local cnsmodinfo = "CNSMOD="..cnsmod;
		print("otad_util_process_network_info (2) -->> ", cnsmodinfo, "\r\n"); 
		otad_util_cnsmod_info(context, cnsmodinfo);
	end;
	print("otad_util_process_network_info (out)\r\n"); 
end;

function otad_util_init(context)
  print("otad_util_init\r\n");  
  --
  otad.init();
  
  otad.switchinfo();
  
  context.otad_log_filepath = "C:\\";
  context.otad_log_filename = "otad_logfile.txt";
  
end;
--------------------------------------------------------------------------------
function otad_util_deinit(context)
  print("otad_util_deinit\r\n");  
  --
  otad.deinit();
end;

---------------------------------------------------------------------------------
--异常重启
function otad_util_reboot_info(context)
  print("otad_util_reboot_info\r\n");  
  --
  --#define OTAD_ABNO_REBOOT_INFO    (0x00000001)       /*abnormal rebboot information*/
  if(context.current_log_info_state)then
  otad.keyinfo(1, "sunyuanzhi", 10);
  print("otad_util_reboot_info ==\r\n");
  end;
end;

--------------------------------------------------------------------------------
--温度信息
function otad_util_temperature_info(context)
  print("otad_util_temperature_info(in)\r\n");  
  --#define OTAD_TEMPERATURE_INFO     (0x00000002)       /*temperature information*/
  if(context.current_log_info_state)then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CADC=1\r\n","\r\n+CADC:","\r\nERROR\r\n", 2000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CADC:";
	local temperature_content = "temperature:";
    local temperature = str_util_parse_sio_report_parameter(rsp, rpt, 1, "," , "\r\n" , false);

    if (temperature) then 
	  temperature_content = temperature_content..temperature;
	  otad.keyinfo(2, temperature_content, string.len(temperature_content));
	  print("temperature_content = ", temperature_content, "-->> len = ", string.len(temperature_content), "\r\n");
    end;
  end;
  print("otad_util_temperature_info(out)\r\n");  
end;

--------------------------------------------------------------------------------
--网络注册
function otad_util_network_reg_info(context, networkinfo)
  print("otad_util_network_reg_info\r\n");  
  --#define OTAD_NETWORK_REG_INFO   (0x00000004)       /*network registration information*/
  if(context.current_log_info_state and networkinfo)then
  otad.keyinfo(4, networkinfo, string.len(networkinfo));
  end;
end;
--------------------------------------------------------------------------------
--小区 AT+CCINFO
function otad_util_cell_info(context)
  print("otad_util_cell_info\r\n");  
  --#define OTAD_CELL_INFO   			(0x00000008)       /*cell information*/
  if(context.current_log_info_state)then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CCINFO\r\n","\r\n+CCINFO:","\r\nERROR\r\n", 2000);
    
	if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    
    if(rsp)then
      otad.keyinfo(8, rsp, string.len(rsp));
    end;
  end;  
end;

--------------------------------------------------------------------------------
--cnsmod
function otad_util_cnsmod_info(context, cnsmodinfo)
  print("otad_util_cnsmod_info\r\n");  
  --#define OTAD_NSMOD_INFO   		(0x00000010)       /*cnsmod information*/
  if(context.current_log_info_state and cnsmodinfo)then
  otad.keyinfo(16, cnsmodinfo, string.len(cnsmodinfo));
  end;
end;

--------------------------------------------------------------------------------
--call
function otad_util_call_info(context, callinfo)
  print("otad_util_call_info\r\n");  
  --#define OTAD_CALL_INFO   		        (0x00000020)       /*call information*/
  if(context.current_log_info_state and callinfo)then
  otad.keyinfo(32, callinfo, string.len(callinfo));
  end;
end;
--------------------------------------------------------------------------------
--ps_opt
function otad_util_ps_opt_info(context, psinfo)
  print("otad_util_ps_opt_info\r\n");  
  --#define OTAD_PS_OPT_INFO   		(0x00000040)       /*PS operation information*/
  if(context.current_log_info_state and psinfo)then
  otad.keyinfo(64, psinfo, string.len(psinfo));
  end;
end;

--------------------------------------------------------------------------------
--ip
function otad_util_ip_info(context)
  print("otad_util_ip_info\r\n");  
  --#define OTAD_IP_INFO   			(0x00000080)       /*ip information*/
  if(context.current_log_info_state)then
  otad.keyinfo(128, "sunyuanzhi", 10);
  end;
end;

--------------------------------------------------------------------------------
--sim
function otad_util_sim_opt_info(context)
  print("otad_util_sim_opt_info\r\n");  
  --#define OTAD_SIM_OPT_INFO   		(0x00000100)       /*sim operation information*/
  if(context.current_log_info_state)then
  otad.keyinfo(256, "sunyuanzhi", 10);
  end;
end;

--------------------------------------------------------------------------------
--memory
function otad_util_memory_info(context)
  print("otad_util_memory_info(in)\r\n");  
  --#define OTAD_MEMORY_INFO   		(0x00000200)       /*memory information*/
  if(context.current_log_info_state)then
    local disk_info = fs_util_get_memory_info(context);
	local diskc_size = "disk c: ";

	local availablesize = disk_info.diskc_total_size - disk_info.diskc_used_size;
	diskc_size = diskc_size..availablesize;
	
    otad.keyinfo(512, diskc_size, string.len(diskc_size));  
    print("otad_util_memory_info = ", diskc_size, "-->>", string.len(diskc_size), "\r\n");
  end;
  
  print("otad_util_memory_info(out)\r\n");  
end;

--------------------------------------------------------------------------------
--rf
function otad_util_rf_info(context)
  print("otad_util_rf_info\r\n");  
  --#define OTAD_RF_INFO   			(0x00000400)       /*RF information*/
  if(context.current_log_info_state)then
  otad.keyinfo(1024, "sunyuanzhi", 10);
  end;
end;

--------------------------------------------------------------------------------
--voltage
function otad_util_voltage_info(context)
  print("otad_util_voltage_info(in)\r\n");
  --#define OTAD_VOLTAGE_INFO   		(0x00000800)       /*voltage information*/
  if(context.current_log_info_state)then
    local rsp, exp_num = sio_send_and_recv2(context, "AT+CBC\r\n","\r\n+CBC:","\r\nERROR\r\n", 2000);
    if ((exp_num ~= 1) or (not rsp)) then
      return nil;
    end;
    local rpt = "\r\n+CBC:";
	local voltage = "voltage: ";
    local vol = str_util_parse_sio_report_parameter(rsp,rpt,3,",","\r\n",false);
    if (vol) then 
	  voltage = voltage..vol;
	  otad.keyinfo(2048, voltage, string.len(voltage));
	  print("voltage = ", voltage, "-->> len = ", string.len(voltage), "\r\n");
    end;
  end;
  
  print("otad_util_voltage_info(in)\r\n");
end;


--------------------------------------------------------------------------------
--network
function otad_util_network_srch_info(context, sechinfo)
  print("otad_util_network_srch_info\r\n");  
  --#define OTAD_NETWORK_SRCH_INFO (0x00001000)       /*network search information*/
  if(context.current_log_info_state and sechinfo)then
    otad.keyinfo(4096, sechinfo, string.len(sechinfo));
  end;
end;

--------------------------------------------------------------------------------
--start up
function otad_util_start_up_info(context)
  print("otad_util_start_up_info(in)\r\n");  
  --#define OTAD_STARTUP_INFO 		(0x00002000)       /*startup information*/  
  local start_up_time = "Power on already "..os.clock().."s\r\n";    
  
  if(context.current_log_info_state)then
    otad.keyinfo(8192, start_up_time, string.len(start_up_time));
  end;
  print("start_up_time = ", start_up_time, "\r\n", "otad_util_start_up_info(out)\r\n");  
end;

--------------------------------------------------------------------------------
--[[得到log文件内容或是文件名
log_index log索引：和上面的一样。
contenttype 1：文件内容，2：表示文件名称

return 表示结果
--]]
function otad_util_get_file(context, log_index, contenttype)
  local filename;
  --异常重启
  if(log_index == 1) then
    filename = "C://otad_reboot.dat"
  end;
  --温度信息
  if(log_index == 2) then
    filename = "C://otad_temp.dat"
  end;
  --网络注册
  if(log_index == 4) then
    filename = "C://otad_netreg.dat"
  end;
  --小区
  if(log_index == 8) then
    filename = "C://otad_cell.dat"
  end;
  --cnsmod
  if(log_index == 16) then
    filename = "C://otad_cnsmod.dat"
  end;  
  --call
  if(log_index == 32) then
    filename = "C://otad_call.dat"
  end;
  --ps_opt
  if(log_index == 64) then
    filename = "C://otad_psopt.dat"
  end;
  --ip
  if(log_index == 128) then
    filename = "C://otad_ip.dat"
  end;  
  --sim
  if(log_index == 256) then
    filename = "C://otad_simopt.dat"
  end;  
  --memory
  if(log_index == 512) then
    filename = "C://otad_mem.dat"
  end;
  --rf
  if(log_index == 1024) then
    filename = "C://otad_rf.dat"
  end;
  --voltage
  if(log_index == 2048) then
    filename = "C://otad_volt.dat"
  end;
  --network
  if(log_index == 4096) then
    filename = "C://otad_netsearch.dat"
  end;  
  --start up
  if(log_index == 8192) then
    filename = "C://otad_startup.dat"
  end;
  if(contenttype == 1) then 
    return otad_util_get_file_context(filename);
  else
    return filename;
  end;
end;

function otad_util_get_file_context(filename)
  local file = io.open(filename,"r");
  if (not file) then
    print("otad_util_get_file_context -- open error -->> ",filename, "\r\n")
    return nil;
  end;
  local cnt = file:read("*a");
  file:close();
  return cnt;
end;

function otad_util_save_log_context(file_path, file_name, file_content)
  local filename = file_path..file_name;
  print("otad_util_save_log_context -->> filename = ", filename, "\r\n");
  if((not filename) or (not file_content)) then
    return false;
  end;
  file = io.open(filename,"w");
  assert(file)
  file:trunc();
  file:write(file_content);
  file:close();
  return true;
end;

function otad_util_logfile_length(context)
  local filename = context.otad_log_filepath..context.otad_log_filename;
  print("otad_util_logfile_length() -->> filename = ", filename, "\r\n");
  if (not filename) then
    return 0;
  else
    local len = os.filelength(filename);
    print("otad_util_logfile_length() -->> len = ", len, "\r\n");
	if (len < 0) then
	  len = 0;
	end;
	return len;
  end;
end;