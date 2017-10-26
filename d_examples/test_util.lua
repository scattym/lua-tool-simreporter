--------------------------------------------------------------------------------
--脚本说明
--本脚本包含各个模块相关功能测试函数
--------------------------------------------------------------------------------
function test_util_init(context)  
  print("test_util_init\r\n");
  context.debug = true;--when formal release, this variable should be false   
  if (context.debug) then    
	-------------------------------------------------------------
	--unit test settting
    context.test_mode = false;--true = perform unit test
	context.exit_script_after_unit_test = true;--exit before main loop
	-------------------------------------------------------------
	--access mode setting
	context.full_access_mode = true;
	
	--disable the function of adding +86(country code) to phone number
	--context.disable_add_country_code_ph_no = true;
	
	--context.disable_sys_reboot_isr = true;
	--tfcard test setting
    --context.use_tf_card = false;
    --context.tf_card_as_udisk = false;--show u-disk when connecting the module to PC through USB cable
	
	-------------------------------------------------------------
	
	--context.crush_report_ph_num = "15021309668";
	
	--context.use_csdvc_handset = true;--use handset as default audio output,else use speaker
	-------------------------------------------------------------
	--common setting, usually needs not to be changed
	context.force_gw_cnma = true;
    os.crushrestart(0, 1);--not restart this script when crush
    printdir(1);--enable print
	--sio.exclrpt(0);
    -------------------------------------------------------------
  end;
end;

function test_util_exit_before_main_loop(context)
  local should_exit = (context.test_mode and context.exit_script_after_unit_test);
  if (should_exit) then
    os.crushrestart(0, 1);
  end;
  return should_exit;
end;

function test_util_report_crush_error(context, error_info)
  if (context.crush_report_ph_num and error_info and (string.len(error_info) > 0)) then
    local report_string = "";
    local imei = sys_util_get_imei(context);
    if (imei) then
      report_string = "IMEI: "..imei.."\r\n";
    end;
	report_string = report_string.."APP: "..context.app_name..", VERSION: "..context.version.."\r\n";
	report_string = report_string..error_info;
    send_sms_with_ascii_string(context, context.crush_report_ph_num, report_string,"\r\n",3);
  end;
end;

function test_util_send_debug_sms_ascii(context, dest_no, content, delimiter, max_retry)
  if (not context.debug) then
    return true;
  end;
  return send_sms_with_ascii_string(context, dest_no, content, delimiter, max_retry);
end;

function test_util_run_unit_test(context)
  if (not context.test_mode) then
    return false;
  end;
  test_util_test_modules(context);  
  return true;
end;

function test_util_run_unit_test_after_all_configured(context)
  if (not context.test_mode) then
    return false;
  end;
  test_util_test_modules_after_all_configured(context);  
  return true;
end;

function test_util_test_modules(context)
  --acc_util_unit_test(context);
  --cam_util_unit_test(context);
  --fs_util_unit_test(context);
  sys_util_unit_test(context);
  --gpio_util_unit_test(context);
end;

function test_util_test_modules_after_all_configured(context)--perform unit test after all modules are configured successfully
    print("test_util_test_modules_after_all_configured(in)\r\n");
	--[[
	otad_util_reboot_info(context);
	otad_util_temperature_info(context);
	otad_util_network_reg_info(context, "network_info");
	otad_util_cell_info(context);
	otad_util_cnsmod_info(context, "cnsmod_info");
	otad_util_call_info(context);
	otad_util_ps_opt_info(context);
	otad_util_ip_info(context);
	otad_util_sim_opt_info(context);
	otad_util_memory_info(context);
	otad_util_rf_info(context);
	otad_util_voltage_info(context);
	otad_util_network_srch_info(context);
	otad_util_start_up_info(context);
	
	
	vmsleep(2000);
	
	local smsContent;

    local temp = otad_util_get_file(context, 1, 1);
	if(temp) then
	  smsContent = temp;
	end;	
	temp = otad_util_get_file(context, 2, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;		
	temp = otad_util_get_file(context, 4, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 8, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 16, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 32, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 64, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 128, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 256, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 512, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 1024, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 2048, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	
	temp = otad_util_get_file(context, 4096, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	temp = otad_util_get_file(context, 8192, 1);
	if(temp) then
	  smsContent = smsContent..temp;
	end;
	
	if(smsContent) then
	end;
    
	otad_util_save_log_context(context.otad_log_filename, smsContent);
	
	--]]
	sio_sms_cmt_logstart_handler(context, "", "", "", true, "");
	print("test_util_test_modules_after_all_configured(out)\r\n");
end;