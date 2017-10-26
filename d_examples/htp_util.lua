--------------------------------------------------------------------------------
--脚本说明
--本脚本包含HTP(HTTP TIME PROTOCOL)相关操作函数
--------------------------------------------------------------------------------
function htp_util_init(context)
  print("htp_util_init\r\n");
  context.use_htp = true;
  context.htp_server_info = {};
  local htp_server;
  ---------------------------------------------------------------
  htp_server = {};
  htp_server.host = "time.windows.com";
  htp_server.port = 80;
  htp_server.http_version = 1;--1.1
  htp_server.proxy = nil;
  htp_server.proxy_port = nil;
  table.insert(context.htp_server_info, htp_server);
  ---------------------------------------------------------------
  htp_server = {};
  htp_server.host = "www.baidu.com";
  htp_server.port = 80;
  htp_server.http_version = 1;--1.1
  htp_server.proxy = nil;
  htp_server.proxy_port = nil;
  table.insert(context.htp_server_info, htp_server);
  ---------------------------------------------------------------
  htp_server = {};
  htp_server.host = "www.microsoft.com";
  htp_server.port = 80;
  htp_server.http_version = 1;--1.1
  htp_server.proxy = nil;
  htp_server.proxy_port = nil;
  table.insert(context.htp_server_info, htp_server);
  ---------------------------------------------------------------
end;

function htp_util_process_after_init(context)
  for idx = 1, table.maxn(context.htp_server_info), 1 do
    local htp_server = context.htp_server_info[idx];
    htp_util_add_htp_server(context, htp_server.host, htp_server.port, htp_server.http_version, htp_server.proxy, htp_server.proxy_port);
  end;
end;

function htp_util_add_htp_server(context, host, port, http_version, proxy, proxy_port)
  if (not host or not port) then
    return false;
  end;
  local cmd;
  if (proxy and proxy_port) then
    cmd = string.format("AT+CHTPSERV=\"ADD\",\"%s\",%d,%d,\"%s\",%d\r\n", host, port, http_version, proxy, proxy_port);
  else
    cmd = string.format("AT+CHTPSERV=\"ADD\",\"%s\",%d,%d\r\n", host, port, http_version);
  end;
  rsp, idx = sio_send_and_recv2(context, cmd, "\r\nOK\r\n", "\r\nERROR\r\n",5000);
  if (idx ~= 1) then
    return false;
  end;
end;

function htp_util_update_time(context)
  if (not context.use_htp) then
    return false;
  end;
  
  local cgreg = nw_util_get_cgreg(context, true);
  if (not cgreg or (cgreg ~= 1)) then
    return false;
  end;
  
  local rsp, idx = sio_send_and_recv2(context, "AT+CHTPUPDATE\r\n", "\r\nOK\r\n", "\r\nERROR\r\n",10000);
  if (idx ~= 1) then
    return false;
  end;
  rsp, idx = sio_recv_contain2(context, "\r\n+CHTPUPDATE: 0\r\n", "\r\n+CHTPUPDATE:", 60000*2);
  if (idx ~= 1) then
    return false;
  end;
  return true;
end;

function htp_util_is_updating_now(context)  
  local rsp, idx = sio_send_and_recv3(context, "AT+CHTPUPDATE?\r\n", "\r\n+CHTPUPDATE:", "\r\nOK\r\n", "\r\nERROR\r\n",10000);
  if (not rsp or (idx ~= 1)) then
    return false;
  end;
  local status = str_util_parse_sio_report_parameter(rsp,"\r\n+CHTPUPDATE:",1,",","\r\n",false);
  if (not status) then
    return false;
  end;
  if (status == "Updating") then
    return true;
  end;
  return false;
end;

function htp_util_unit_test_after_all_configured(context)
  context.use_htp = true;
  htp_util_update_time(context);
end;