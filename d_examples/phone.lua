--语音电话

--[[
FUNCTION sio_phone_evt_voice_call_begin_handler
DESCRIPTION
  This function is used to handle the VOICE CALL:BEGIN report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]

function sio_phone_evt_voice_call_begin_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  --VOICE CALL:BEGIN
  print("sio_phone_evt_voice_call_begin_handler() -->> VOICE CALL:BEGIN\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VC:BEGIN");
  end;
  
  local sio_header = "\r\nVOICE CALL:BEGIN\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;

--[[
FUNCTION sio_phone_evt_no_carrier_handler
DESCRIPTION
  This function is used to handle the NO CARRIER report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]

function sio_phone_evt_no_carrier_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  --NO CARRIER
  print("sio_phone_evt_no_carrier_handler() -->> NO CARRIER\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VC:NO CARRIER");
  end;
  
  local sio_header = "\r\nNO CARRIER\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;

--[[
FUNCTION sio_phone_evt_ring_handler
DESCRIPTION
  This function is used to handle the RING report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]

function sio_phone_evt_ring_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  --RING
  print("sio_phone_evt_ring_handler() -->>RING\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VC:RING");
  end;
  
  local sio_header = "\r\nRING\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
  
end;

--[[
FUNCTION sio_phone_evt_voice_call_end_handler
DESCRIPTION
  This function is used to handle the VOICE CALL: END: report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]

function sio_phone_evt_voice_call_end_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  --VOICE CALL: END:
  print("sio_phone_evt_voice_call_end_handler() -->> VOICE CALL: END:\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VC:END");
  end;
  
  local sio_header = "\r\nVOICE CALL: END:";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;

--[[
FUNCTION sio_phone_evt_voice_call_missed_handler
DESCRIPTION
  This function is used to handle the VOICE CALL: END: report in sio
PARAMETERS
  None
RETURN VALUE
  None
]]

function sio_phone_evt_voice_call_missed_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VC:MISSED_CALL");
  end;
  
  print("sio_phone_evt_voice_call_missed_handler() -->> MISSED_CALL:\r\n");
  local sio_header = "\r\nMISSED_CALL:";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;


--视频电话
function sio_vp_evt_vpsetup_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_vp_evt_vpsetup_handler\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VPSETUP");
  end;
  
  local sio_header = "\r\nVPSETUP\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;
function sio_vp_evt_vpringback_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_vp_evt_vpringback_handler() -->> vp ringback\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VPRINGBACK");
  end;
  
  local sio_header = "\r\nVPRINGBACK\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;
end;
function sio_vp_evt_vpconnected_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_vp_evt_vpconnected_handler\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VPCONNECTED");
  end;
  
  local sio_header = "\r\nVPCONNECTED\r\n";
  if (string.len(context.sio_rcvd_string) > string.len(sio_header)) then
    context.sio_rcvd_string = string.sub(context.sio_rcvd_string, string.len(sio_header)+1, -1);
  else
    context.sio_rcvd_string = "";
  end;

end;
function sio_vp_evt_vpend_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_vp_evt_vpend_handler\r\n");
 
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VPEND");
  end;
  
  local sio_header = "\r\nVPEND";
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
function sio_vp_evt_missed_video_call_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
  print("sio_vp_evt_missed_video_call_handler\r\n");
  
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "MISSED_VIDEO_CALL");
  end;
  
  local sio_header = "\r\nMISSED_VIDEO_CALL:";
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
function sio_vp_evt_vpincom_handler(context, evt, evt_p1, evt_p2, evt_p3, evt_clock)
    
  if(context.sio_rcvd_string) then
    otad_util_call_info(context, "VPINCOM");
  end;
  
  local sio_header = "\r\nVPINCOM:";
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