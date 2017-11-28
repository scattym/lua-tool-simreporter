--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 28/11/17
-- Time: 10:31 PM
-- To change this template use File | Settings | File Templates.
--

    --mqtt_thread.mqtt_thread()
    --[[
    while ( true ) do
        local cell_table = device.get_device_info_table()
        local nmea_data = nmea.getinfo(511);
        local data = '{"version":"1","packet_number":4,"nmea":"$GPGSV,4,1,16,28,65,202,34,07,40,077,27,17,43,348,27,13,36,230,27*7B|$GPGSV,4,2,16,15,07,219,16,05,02,282,16,08,09,140,16,11,28,104,15*76|$GPGSV,4,3,16,19,23,341,15,30,68,118,14,01,16,084,,09,07,015,*72|$GPGSV,4,4,16,04,,,,32,,,,31,,,,29,,,*72|$GPGGA,031924.0,3348.948974,S,15112.009167,E,1,06,1.2,84.5,M,0,M,,*52|$GPVTG,NaN,T,,M,0.0,N,0.0,K,A*42|$GPRMC,031924.0,A,3348.948974,S,15112.009167,E,0.0,0.0,141017,,,A*70|$GPGSA,A,3,07,11,13,17,19,28,,,,,,,3.1,1.2,2.9*39|","device_info":"|Manufacturer: SIMCOM INCORPORATED|Model: SIMCOM_SIM5320A|Revision: SIM5320A_V1.5|IMEI: 012813008945935|+GCAP: +CGSM,+DS,+ES||OK|","packet_count":0}'
        if (nmea_data) then
            local encrypted = aes.encrypt("password", data, aes.AES128, aes.CBCMODE)
            local decrypted = aes.decrypt("password", encrypted, aes.AES128, aes.CBCMODE)
            if data ~= decrypted then
                logger(30, "Decryption failed")
                logger(30, data)
                logger(30, decrypted)
            end
            collectgarbage()

        end;

        thread.sleep(2000)]]

        --[[for j=1,127 do
            for i=1,63 do
                logger(30, "setting for device: ", j, " and register: ", i)
                i2c.write_i2c_dev(j, i, 101, 1)
                thread.sleep(100)
                local a, b, c, d = i2c.read_i2c_dev(j, i, 4)
                logger(30, "Read: ", a, " ", b, " ", c, " ", d)
                thread.sleep(100)
            end
        end]]--

        --[[spi.set_clk(0, 1, 1);
        logger(30, "set_cs")
        spi.set_cs(1, 1);
        logger(30, "set_freq")
        spi.set_freq(1000, 500000, 1000);
        logger(30, "set_num_bits")
        spi.set_num_bits(8, 0, 0);
        logger(30, "config_device")
        spi.config_device();
        spi.write(141, 42, 1)
        while true do
            for i=1,100 do
                spi.write(65, i, 1)
                a, b, c, d = spi.read(i, 1)
                logger(30, "a:", tostring(a), ",b:", tostring(b), ",c:", tostring(c), ",d:", tostring(d))
                thread.sleep(100)
            end
            spi.write(10, 101, 1)

            thread.sleep(1000)
        end]]--
    --end



        --[[local hosts = {6, 7, 16, 17 }
        --local hosts = {6, 7}
        for _,i in ipairs(hosts) do
        --for i=1,127 do
            for j=1,32 do
                local data = i2c.read_i2c_dev(i, j, 4)
                local hex = ""
                if data ~= false then
                    hex = string.format("%x", data)
                end
                logger(30, "", i, ":", data, ":", hex)
                thread.sleep(200)
            end
        end]]--

    --[[key, enc_key = keygen.create_and_encrypt_key(128)
    logger(30, "Key is: ", key);
    logger(30, "Encrypted key is: ", enc_key);
    logger(30, "Key is: ", rsa.num_to_hex(key));
    logger(30, "Encrypted key is: ", rsa.num_to_hex(enc_key))
    logger(30, "Clock is: ", tostring(os.clock()))
    local key_data = {}
    key_data["key"] = key
    key_data["enc_key"] = enc_key]]--

