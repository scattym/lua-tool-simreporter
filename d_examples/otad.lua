--------------------------------------------------------------------------------
--脚本说明
--本脚本执行VS-MSC3401D视频电话及控制功能:
--1. 详细需求请参考<<附件1 MSC3412D委托开发需求规格书-Rev110321.pdf>>
--------------------------------------------------------------------------------
dofile("C:\\sio_util.lua")
dofile("C:\\evt_util.lua")
dofile("C:\\sms_util.lua")
dofile("C:\\str_util.lua")
dofile("C:\\nw_util.lua")
dofile("C:\\fs_util.lua")
dofile("C:\\sys_util.lua")
dofile("C:\\mms_util.lua")
dofile("C:\\conf_util.lua")
dofile("C:\\htp_util.lua")
dofile("C:\\log_util.lua")
dofile("C:\\simcard_util.lua")
dofile("C:\\sio_sms_evt_handler.lua")
dofile("C:\\otad_util.lua")
dofile("C:\\test_util.lua")
dofile("C:\\phone.lua")

function lua_register_event_handler(context)
  evt_util_register_evt_handler(context, context.evt.sio, evt_util_sio_data_handler_proc);
  evt_util_register_evt_handler(context, context.evt.timer, evt_util_timer_evt_handler_proc);
  evt_util_register_evt_handler(context, context.evt.pdp, evt_util_pdp_evt_handler_proc);
  
  -------------------------------------------------------------------------------------
  evt_util_register_sio_data_handler(context, "\r\n+CMT:", sio_sms_evt_cmt_handler);
 
  evt_util_register_sio_data_handler(context, "\r\n+CSQ:", sio_nw_evt_csq_handler);
  evt_util_register_sio_data_handler(context, "\r\n+CNSMOD:", sio_nw_evt_cnsmod_handler);
  
  --处理电话方面的上报事件 CS
  evt_util_register_sio_data_handler(context, "\r\nVOICE CALL:BEGIN\r\n", sio_phone_evt_voice_call_begin_handler);
  evt_util_register_sio_data_handler(context, "\r\nNO CARRIER\r\n", sio_phone_evt_no_carrier_handler);
  
  evt_util_register_sio_data_handler(context, "\r\nRING\r\n", sio_phone_evt_ring_handler);  
  evt_util_register_sio_data_handler(context, "\r\nVOICE CALL: END:", sio_phone_evt_voice_call_end_handler);  
  evt_util_register_sio_data_handler(context, "\r\nMISSED_CALL:", sio_phone_evt_voice_call_missed_handler);
  
  --处理电话方面的上报事件 CS
  
  --处理视频电话
  evt_util_register_sio_data_handler(context, "\r\nVPSETUP\r\n", sio_vp_evt_vpsetup_handler);
  evt_util_register_sio_data_handler(context, "\r\nVPRINGBACK\r\n", sio_vp_evt_vpringback_handler);
  evt_util_register_sio_data_handler(context, "\r\nVPCONNECTED\r\n", sio_vp_evt_vpconnected_handler);
  evt_util_register_sio_data_handler(context, "\r\nVPEND", sio_vp_evt_vpend_handler);
  evt_util_register_sio_data_handler(context, "\r\nMISSED_VIDEO_CALL:", sio_vp_evt_missed_video_call_handler);
  evt_util_register_sio_data_handler(context, "\r\nVPINCOM", sio_vp_evt_vpincom_handler);
  
  
  
  -------------------------------------------------------------------------------------
  evt_util_register_timer_id_evt_handler(context, context.timer_ids.nw_query_timer, nw_util_nw_query_timer_handler_proc);
  evt_util_register_timer_id_evt_handler(context, context.timer_ids.otad_timer, otad_util_otad_timer_timer_handler_proc);
  
end;

function operator_info_init(context)
  --[[
  ----china mobile
  context.csca = "+8613800210500";
  context.pdp_apn = "cmnet";
  context.mms_pdp_apn = "cmwap";
  context.mmsc_url = "mmsc.monternet.com";
  context.mms_proto_ip = "10.0.0.172";
  context.mms_proto_port = 80;
  ----]]
  --[[
  --unicom, default
  context.csca = "+8613010314500";
  --context.csca = "+8613010112500";
  context.pdp_apn = "3gnet";
  context.mms_pdp_apn = "uniwap";--"3gwap";
  context.mmsc_url = "mmsc.myuni.com.cn";
  context.mms_proto_ip = "10.0.0.172";
  context.mms_proto_port = 80;
  ----]]
  
  context.time_zone_mul_4 = 8 * 4;--default time zone  
  context.ph_no_country_headers = "+86";
end;

function lua_init(context)
  --------------------------------------------------------
  --used to trace script running info
  context.dt_script_start_time = os.date("*t"); 
  
  --
  context.newwork_reg_dt_start_time = os.time();
  context.newwork_reg_ok = false;
  
  context.last_error = os.get_lasterror();
  os.clear_lasterror();
  --define variables
  context.app_name = "OTAD";
  context.version = "1.0";
  context.pln = "11111";--platform number???SETPLN
  context.use_tf_card = true;
  context.tf_card_as_udisk = true;
  context.current_is_at_mode = true;   
  context.continue_recording_when_failed = true;  
  ---------------------------------------------------------
  os.crushrestart(1, 0);--restart this script when crush
  sio.exclrpt(1);
  ---------------------------------------------------------
  context.current_log_info_state = false; --false: close, true: open  
  ---------------------------------------------------------
  context.current_log_info_report_type = 1; --1: SMS, 2:MMS, 3:ftp
  --context.current_log_info_report_phone_number=""; --SMS和MMS号码
  context.current_log_info_report_ip_addr="";      --ftp号码
  ---------------------------------------------------------
  --begin initialize each module  
  test_util_init(context);--used for test variables setting  

  simcard_util_init(context);
  sio_util_init(context); 
  enable_at_echo(context, false);  
  operator_info_init(context);
  log_init(context);
  sys_util_init(context);
  
  conf_util_init(context);
  conf_util_load(context);
  conf_util_load_pn_manager(context); 
  
  simcard_util_wait_for_pin_ready(context);
  sms_util_init(context);
  evt_util_init(context);
  
  nw_util_init(context);
  
  mms_util_init(context);
  
  htp_util_init(context);
   
  sio_sms_cmt_data_handler_init(context);
  
  lua_define_timer_ids(context);
  lua_register_event_handler(context);
  
  otad_util_init(context);
  
  fs_util_init(context);
  
  --test_util_test_modules_after_all_configured(context);
end;

function lua_define_timer_ids(context)
  context.timer_ids = {};
  context.timer_ids.nw_query_timer = 1;--used to query creg and cgreg
  context.timer_ids.otad_timer     = 2;--used to otad
  

end;

function lua_process_after_init(context)
  sys_util_process_after_init(context);
  
  nw_util_process_after_init(context);
  
  
  context.current_log_info_state = true;
  --调用底层驱动的接口开始记录log
  
  --1分钟查询一次
  vmstarttimer(context.timer_ids.otad_timer, 1000*60, 1);
  
  otad_util_start_up_info(context);
end;

function lua_main_proc(context)
  print("begin running in main loop\r\n");  
  while ( true ) do
    local evt, evt_p1, evt_p2, evt_p3, evt_clock = waitevt(9999999);
	if (evt >= 0) then
	  print("evt=", evt, ", evt_p1=", evt_p1, ", evt_p2=", evt_p2, " evt_p3=", evt_p3, ", evt_clock=", evt_clock,"\r\n");
	  if (evt == context.evt.exit) then
	    break;
	  end;	  
	  
	  evt_util_evt_handler_proc(context, evt, evt_p1, evt_p2, evt_p3, evt_clock);	  
	  
	end;
  end;
end;

function lua_main(context)  
  lua_init(context);
  -------------------------------------------
  --test_util_run_unit_test(context);--used for unit test
  -------------------------------------------
  lua_process_after_init(context);
  -------------------------------------------
  --test_util_report_crush_error(context, context.last_error);
  -------------------------------------------
  --test_util_run_unit_test_after_all_configured(context);--used for unit test after all modules are configured
  -------------------------------------------
  if (test_util_exit_before_main_loop(context)) then
    enable_at_echo(context, true);--set ATE1 before exit
    return;
  end;

  -------------------------------------------
  lua_main_proc(context); 
  
  -------------------------------------------
  otad_util_deinit(context);
end;

function lua_main_test(context)
    lua_init(context);
    
    conf_util_load_pn_manager(context); 
    print("lua_main_test **********************************************************\r\n");
    local ret = sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, "13482634266");
    if(true == ret) then
        print("lua_main_test -->> ok\r\n");
    else
        print("lua_main_test -->> error\r\n");
    end;
    print("lua_main_test **********************************************************\r\n");
    ret = sio_sms_cmt_check_sms_phone_num_is_in_otad_pn_conf(context, "1348263426");
    if(true == ret) then
        print("lua_main_test 1-->> ok\r\n");
    else
        print("lua_main_test 1-->> error\r\n");
    end;
    print("lua_main_test **********************************************************\r\n");
    conf_util_save_pn_manager(context);
    
end;

--global application context
app_context = {};
lua_main(app_context);
--lua_main_test(app_context);



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