-------------------------------------------------
---      *** BigInteger for Lua ***           ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local _M = {}
local logging = require("logging")
local logger = logging.create("BigInt", 30)

---------------------------------------
--- Lua 5.0/5.1/WoW Header ------------
---------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local max     = math.max
local min     = math.min
local floor   = math.floor
local ceil    = math.ceil
local mod     = math.fmod
local getn    = function(t) return #t end
local setn    = function() end
local tinsert = table.insert


---------------------------------------
--- Helper Functions ------------------
---------------------------------------

local function Digit(x,i)					--returns i-th digit or zero
	--[[local d = x[i]						--if out of bounds
	if (d==nil) then
		return 0
	end
	return d]]--
    return x[i] or 0
end

---------------------------------------

local function Clean(clean_x)						--remove leading zeros
    ----logger(30, "clean in")
	local clean_i = #clean_x
	while (clean_i>1 and clean_x[clean_i]==0) do
		clean_x[clean_i] = nil
		clean_i = clean_i-1
    end
    return clean_x
    --setn(clean_x,clean_i)
    ----logger(30, "clean out")
    --collectgarbage()
end

---------------------------------------
--- String Conversion -----------------
---------------------------------------

local function Hex(i)						--convert number to ascii
	if (i>-1 and i<10) then
		return strchar(48+i)
	end
	if (i>9 and i<16) then
		return strchar(55+i)
	end
	return strchar(48)
end

---------------------------------------

local function Dec(dec_i)						--convert ascii to number
	if (dec_i==nil) then
		return 0
	end
	if (dec_i>47 and dec_i<58) then
		return dec_i-48
	end
	if (dec_i>64 and dec_i<71) then
		return dec_i-55
	end
	if (dec_i>96 and dec_i<103) then
		return dec_i-87
	end
	return 0
end

---------------------------------------

local function BigInt_NumToHex(n2h_x)					--convert number to hexstring
	local n2h_s,n2h_i,n2h_j,n2h_c = ""
	for n2h_i = 1,#n2h_x do
		n2h_c = n2h_x[n2h_i]
		for n2h_j = 1,6 do
			n2h_s = Hex(mod(n2h_c,16))..n2h_s
			n2h_c = floor(n2h_c/16)
		end
	end
	n2h_i = 1
	while (n2h_i<strlen(n2h_s) and strbyte(n2h_s,n2h_i)==48) do
		n2h_i = n2h_i+1
	end
	return strsub(n2h_s,n2h_i)
end
_M.num_to_hex = BigInt_NumToHex

---------------------------------------

local function BigInt_HexToNum(h2n_h)					--convert hexstring to number
	local h2n_x, h2n_i, h2n_j = {}
	for h2n_i = 1,ceil(strlen(h2n_h)/6) do
		h2n_x[h2n_i] = 0
		for h2n_j = 1,6 do
			h2n_x[h2n_i] = 16* h2n_x[h2n_i]+Dec(strbyte(h2n_h,max(strlen(h2n_h)-6* h2n_i +h2n_j,0)))
		end
	end
	Clean(h2n_x)
	return h2n_x
end
_M.hex_to_num = BigInt_HexToNum

---------------------------------------

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

---------------------------------------

local function BigInt_BytesToNum(bytes)					--convert bytestring to number
    local hex_bytes = tohex(bytes)
    return BigInt_HexToNum(hex_bytes)
end
_M.bytes_to_num = BigInt_BytesToNum


---------------------------------------
--- Math Functions --------------------
---------------------------------------

local function BigInt_Add(add_x, add_y)					--add numbers
--logger(30, "Bigint add in")
	local add_z,add_l,add_i,add_r = {},max(getn(add_x),getn(add_y))
	add_z[1] = 0
	for add_i = 1,add_l do
		add_r = Digit(add_x,add_i)+Digit(add_y,add_i)+add_z[add_i]
		if (add_r>16777215) then
			add_z[add_i] = add_r-16777216
			add_z[add_i+1] = 1
		else
			add_z[add_i] = add_r
			add_z[add_i+1] = 0
		end
	end
	Clean(add_z)
--logger(30, "Bigint add out")
	return add_z
end

---------------------------------------

local function BigInt_Sub(sub_x,sub_y)					--subtract numbers
    --logger(30, "Bigint sub in")
	local sub_z,sub_l,sub_i,sub_r = {},max(getn(sub_x),getn(sub_y))
	sub_z[1] = 0
	for sub_i = 1,sub_l do
		sub_r = Digit(sub_x,sub_i)-Digit(sub_y,sub_i)-sub_z[sub_i]
		if (sub_r<0) then
			sub_z[sub_i] = sub_r+16777216
			sub_z[sub_i+1] = 1
		else
			sub_z[sub_i] = sub_r
			sub_z[sub_i+1] = 0
		end
	end
	if (sub_z[sub_l+1]==1) then
		return nil
	end
	--Clean(sub_z)
    --logger(30, "Bigint sub out")
	return Clean(sub_z)
end

local function BigInt_Sub2(sub_x,sub_y)					--subtract numbers
    --logger(30, "Bigint sub in")
	local sub_z,sub_l,sub_i,sub_r = {},max(#sub_x,#sub_y)
	sub_z[1] = 0
	for sub_i = 1,sub_l do
		sub_r = (sub_x[sub_i] or 0)-(sub_y[sub_i] or 0)-sub_z[sub_i]
		if (sub_r<0) then
			sub_z[sub_i] = sub_r+16777216
			sub_z[sub_i+1] = 1
		else
			sub_z[sub_i] = sub_r
			sub_z[sub_i+1] = 0
		end
	end
	if (sub_z[sub_l+1]==1) then
		return nil
	end
	--Clean(sub_z)
    --logger(30, "Bigint sub out")
	return Clean(sub_z)
end

---------------------------------------

local function BigInt_Mul(mult_x,mult_y)					--multiply numbers
--logger(30, "Bigint mult in")
	local mult_z,mult_t,mult_i,mult_j,mult_r = {},{}
	for mult_i = getn(mult_y),1,-1 do
		mult_t[1] = 0
		for mult_j = 1,getn(mult_x) do
			mult_r = mult_x[mult_j]*mult_y[mult_i]+mult_t[mult_j]
			mult_t[mult_j+1] = floor(mult_r/16777216)
			mult_t[mult_j] = mult_r-mult_t[mult_j+1]*16777216
		end
		tinsert(mult_z,1,0)
		mult_z = BigInt_Add(mult_z,mult_t)
	end
	Clean(mult_z)
--logger(30, "Bigint mult out")
	return mult_z
end

---------------------------------------

local function Div2(div2_x)						--divide number by 2, (modifies
    --logger(30, " div2 in")
	local div2_u,div2_v,div2_i = 0						--passed number and returns
	for div2_i = getn(div2_x),1,-1 do					--remainder)
		div2_v = div2_x[div2_i]
		if (div2_u==1) then
			div2_x[div2_i] = floor(div2_v/2)+8388608
		else
			div2_x[div2_i] = floor(div2_v/2)
		end
		div2_u = mod(div2_v,2)
	end
	Clean(div2_x)
    --logger(30, "div2 out")
	return div2_u
end

---------------------------------------

local function SimpleDiv(sdiv_x,sdiv_y)					--divide numbers, result
    --logger(30, "simple div in")
	local sdiv_z,sdiv_u,sdiv_v,sdiv_i,sdiv_j = {},0					--must fit into 1 digit!
	sdiv_j = 16777216
	for sdiv_i = 1,getn(sdiv_y) do					--This function is costly and
		sdiv_z[sdiv_i+1] = sdiv_y[sdiv_i]					--may benefit most from an
	end							--optimized algorithm!
	sdiv_z[1] = 0
	for sdiv_i = 23,0,-1 do
		sdiv_j = sdiv_j/2
		Div2(sdiv_z)
		sdiv_v = BigInt_Sub(sdiv_x,sdiv_z)
		if (sdiv_v~=nil) then
 			sdiv_u = sdiv_u+sdiv_j
			sdiv_x = sdiv_v
		end
    end
    --logger(30, "simple div out")
	return sdiv_u,sdiv_x
end

---------------------------------------

local function BigInt_Div(div_x, div_y)					--divide numbers
        --logger(30, "Bigint div in")

	local div_z,div_u,div_i,div_v = {},{},getn(div_x)
	for div_v = 1,min(getn(div_x),getn(div_y))-1 do
		tinsert(div_u,1, div_x[div_i])
		div_i = div_i - 1
	end
	while (div_i>0) do
		tinsert(div_u,1, div_x[div_i])
		div_i = div_i - 1
		div_v,div_u = SimpleDiv(div_u, div_y)
		tinsert(div_z,1,div_v)
	end
	Clean(div_z)
--logger(30, "Bigint div out")
	return div_z,div_u
end

---------------------------------------

local function BigInt_ModPower(b,e,m)					--calculate b^e mod m
	local t,s,r = {},{1}
	for r = 1,getn(e) do
		t[r] = e[r]
	end
	repeat
        collectgarbage()
        --logger(30, "Iteration of modpower")
		r = Div2(t)
		--print(getn(t))
		if (r==1) then
			r,s = BigInt_Div(BigInt_Mul(s,b),m)
        end
        --logger(30, "End iteration1")
		r,b = BigInt_Div(BigInt_Mul(b,b),m)
        --logger(30, "End iteration2")
	until (getn(t)==1 and t[1]==0)
    --logger(30, "Returning s")
	return s
end


local function BigInt_ModPower2(b,e,m)					--calculate b^e mod m
	local t,s,r = {},{1}
	for r = 1,#e do
		t[r] = e[r]
	end
	repeat
        collectgarbage()
        logger(30, "Iteration of modpower")


        local div2_x = t
            ----logger(30, " div2 in")
            local div2_u,div2_v,div2_i = 0						--passed number and returns
            for div2_i = #div2_x,1,-1 do					--remainder)
                div2_v = div2_x[div2_i]
                if (div2_u==1) then
                    div2_x[div2_i] = floor(div2_v/2)+8388608
                else
                    div2_x[div2_i] = floor(div2_v/2)
                end
                div2_u = mod(div2_v,2)
            end

                ----logger(30, "clean in")
                local clean_i = #div2_x
                while (clean_i>1 and div2_x[clean_i]==0) do
                    div2_x[clean_i] = nil
                    clean_i = clean_i-1
                end
                ----logger(30, "clean out")

            --Clean(div2_x)

            ----logger(30, "div2 out")
            --return div2_u
        t = div2_x
        r = div2_u

		--r = Div2(t)
		--print(#t)
		if (r==1) then
            local mult_x = s
            local mult_y = b
                ------logger(30, "Bigint mult in")
                local mult_z,mult_t,mult_i,mult_j,mult_r = {},{}
                for mult_i = #mult_y,1,-1 do
                    mult_t[1] = 0
                    for mult_j = 1,#mult_x do
                        mult_r = mult_x[mult_j]*mult_y[mult_i]+mult_t[mult_j]
                        mult_t[mult_j+1] = floor(mult_r/16777216)
                        mult_t[mult_j] = mult_r-mult_t[mult_j+1]*16777216
                    end
                    table.insert(mult_z,1,0)
                    local add_x = mult_z
                    local add_y = mult_t
                        ----logger(30, "Bigint add in")
                        local add_z,add_l,add_i,add_r = {},max(#add_x,#add_y)
                        add_z[1] = 0
                        for add_i = 1,add_l do
                            add_r = (add_x[add_i] or 0)+ (add_y[add_i] or 0) + add_z[add_i]
                            if (add_r>16777215) then
                                add_z[add_i] = add_r-16777216
                                add_z[add_i+1] = 1
                            else
                                add_z[add_i] = add_r
                                add_z[add_i+1] = 0
                            end
                        end

                            ----logger(30, "clean in")
                            local clean_i = #add_z
                            while (clean_i>1 and add_z[clean_i]==0) do
                                add_z[clean_i] = nil
                                clean_i = clean_i-1
                            end
                            ----logger(30, "clean out")

                        --Clean(add_z)
                        ----logger(30, "Bigint add out")
                    mult_z = add_z
                    --mult_z = BigInt_Add(mult_z,mult_t)
                end


                local clean_i = #mult_z
                while (clean_i>1 and mult_z[clean_i]==0) do
                    mult_z[clean_i] = nil
                    clean_i = clean_i-1
                end
            --Clean(mult_z)

            local div_x = mult_z
            local div_y = m
                ------logger(30, "Bigint mult out")

                ------logger(30, "Bigint div in")

                local div_z,div_u,div_i,div_v = {},{},#div_x
                for div_v = 1,min(#div_x,#div_y)-1 do
                    table.insert(div_u,1, div_x[div_i])
                    div_i = div_i - 1
                end
                while (div_i>0) do
                    table.insert(div_u,1, div_x[div_i])
                    div_i = div_i - 1

                    local sdiv_x = div_u
                    local sdiv_y = div_y
                        ------logger(30, "simple div in")
                        local sdiv_z,sdiv_u,sdiv_v,sdiv_i,sdiv_j = {},0					--must fit into 1 digit!
                        sdiv_j = 16777216
                        for sdiv_i = 1,#sdiv_y do					--This function is costly and
                            sdiv_z[sdiv_i+1] = sdiv_y[sdiv_i]					--may benefit most from an
                        end							--optimized algorithm!
                        sdiv_z[1] = 0
                        for sdiv_i = 23,0,-1 do
                            sdiv_j = sdiv_j/2


                           local div2_x2 = sdiv_z
                                ------logger(30, " div2 in")
                                local div2_u2,div2_v2,div2_i2 = 0						--passed number and returns
                                for div2_i2 = #div2_x2,1,-1 do					--remainder)
                                    div2_v2 = div2_x2[div2_i2]
                                    if (div2_u2==1) then
                                        div2_x2[div2_i2] = floor(div2_v2/2)+8388608
                                    else
                                        div2_x2[div2_i2] = floor(div2_v2/2)
                                    end
                                    div2_u2 = mod(div2_v2,2)
                                end

                                    ----logger(30, "clean in")
                                    local clean_i = #div2_x2
                                    while (clean_i>1 and div2_x2[clean_i]==0) do
                                        div2_x2[clean_i] = nil
                                        clean_i = clean_i-1
                                    end
                                    ----logger(30, "clean out")

                                --Clean(div2_x2)
                                ------logger(30, "div2 out")
                                --return div2_u
                            sdiv_z = div2_x2
                            --r = div2_u


                            --Div2(sdiv_z)




                            local sub_x = sdiv_x
                            local sub_y = sdiv_z
                                ----logger(30, "Bigint sub in")
                                local sub_z,sub_l,sub_i,sub_r = {},max(#sub_x,#sub_y)
                                sub_z[1] = 0
                                for sub_i = 1,sub_l do
                                    sub_r = (sub_x[sub_i] or 0)-(sub_y[sub_i] or 0)-sub_z[sub_i]
                                    if (sub_r<0) then
                                        sub_z[sub_i] = sub_r+16777216
                                        sub_z[sub_i+1] = 1
                                    else
                                        sub_z[sub_i] = sub_r
                                        sub_z[sub_i+1] = 0
                                    end

                                end
                                if (sub_z[sub_l+1]==1) then
                                    sub_z = nil
                                else
                                        local clean_i = #sub_z
                                        while (clean_i>1 and sub_z[clean_i]==0) do
                                            sub_z[clean_i] = nil
                                            clean_i = clean_i-1
                                        end
                                    --Clean(sub_z)
                                end

                                ----logger(30, "Bigint sub out")
                            sdiv_v = sub_z

                            --sdiv_v = BigInt_Sub2(sdiv_x,sdiv_z)
                            if (sdiv_v~=nil) then
                                sdiv_u = sdiv_u+sdiv_j
                                sdiv_x = sdiv_v
                            end
                        end
                        ------logger(30, "simple div out")
                    div_v = sdiv_u
                    div_u = sdiv_x


                    --div_v,div_u = SimpleDiv(div_u, div_y)
                    table.insert(div_z,1,div_v)
                end

                    ----logger(30, "clean in")
                    local clean_i = #div_z
                    while (clean_i>1 and div_z[clean_i]==0) do
                        div_z[clean_i] = nil
                        clean_i = clean_i-1
                    end
                    ----logger(30, "clean out")
                --Clean(div_z)
                ------logger(30, "Bigint div out")
            r = div_z
            s = div_u

			--r,s = BigInt_Div(BigInt_Mul(s,b),m)
        end
        --logger(30, "End iteration1")


            local mult_x = b
            local mult_y = b
                ------logger(30, "Bigint mult in")
                local mult_z,mult_t,mult_i,mult_j,mult_r = {},{}
                for mult_i = #mult_y,1,-1 do
                    mult_t[1] = 0
                    for mult_j = 1,#mult_x do
                        mult_r = mult_x[mult_j]*mult_y[mult_i]+mult_t[mult_j]
                        mult_t[mult_j+1] = floor(mult_r/16777216)
                        mult_t[mult_j] = mult_r-mult_t[mult_j+1]*16777216

                    end
                    table.insert(mult_z,1,0)
                    local add_x = mult_z
                    local add_y = mult_t
                        ------logger(30, "Bigint add in")
                        local add_z,add_l,add_i,add_r = {},max(#add_x,#add_y)
                        add_z[1] = 0
                        for add_i = 1,add_l do
                            add_r = (add_x[add_i] or 0)+ (add_y[add_i] or 0)+add_z[add_i]
                            if (add_r>16777215) then
                                add_z[add_i] = add_r-16777216
                                add_z[add_i+1] = 1
                            else
                                add_z[add_i] = add_r
                                add_z[add_i+1] = 0
                            end
                        end


                            ----logger(30, "clean in")
                            local clean_i = #add_z
                            while (clean_i>1 and add_z[clean_i]==0) do
                                add_z[clean_i] = nil
                                clean_i = clean_i-1
                            end
                            ----logger(30, "clean out")

                        --Clean(add_z)
                        ------logger(30, "Bigint add out")
                    mult_z = add_z
                    --mult_z = BigInt_Add(mult_z,mult_t)
                end



                ----logger(30, "clean in")
                local clean_i = #mult_z
                while (clean_i>1 and mult_z[clean_i]==0) do
                    mult_z[clean_i] = nil
                    clean_i = clean_i-1
                end
                ----logger(30, "clean out")
            --Clean(mult_z)

            local div_x = mult_z
            local div_y = m
                ------logger(30, "Bigint mult out")

                ------logger(30, "Bigint div in")

                local div_z,div_u,div_i,div_v = {},{},#div_x
                for div_v = 1,min(#div_x,#div_y)-1 do
                    table.insert(div_u,1, div_x[div_i])
                    div_i = div_i - 1

                end
                while (div_i>0) do
                    table.insert(div_u,1, div_x[div_i])
                    div_i = div_i - 1

                    local sdiv_x = div_u
                    local sdiv_y = div_y
                        --logger(30, "simple div in")
                        local sdiv_z,sdiv_u,sdiv_v,sdiv_i,sdiv_j = {},0					--must fit into 1 digit!
                        sdiv_j = 16777216
                        for sdiv_i = 1,#sdiv_y do					--This function is costly and
                            sdiv_z[sdiv_i+1] = sdiv_y[sdiv_i]					--may benefit most from an
                        end							--optimized algorithm!
                        sdiv_z[1] = 0
                        for sdiv_i = 23,0,-1 do
                            sdiv_j = sdiv_j/2

                           local div2_x3 = sdiv_z
                                --logger(30, " div2 in")
                                local div2_u3,div2_v3,div2_i3 = 0						--passed number and returns
                                for div2_i3 = #div2_x3,1,-1 do					--remainder)
                                    div2_v3 = div2_x3[div2_i3]
                                    if (div2_u3==1) then
                                        div2_x3[div2_i3] = floor(div2_v3/2)+8388608
                                    else
                                        div2_x3[div2_i3] = floor(div2_v3/2)
                                    end
                                    div2_u3 = mod(div2_v3,2)

                                end


                                    ----logger(30, "clean in")
                                    local clean_i = #div2_x3
                                    while (clean_i>1 and div2_x3[clean_i]==0) do
                                        div2_x3[clean_i] = nil
                                        clean_i = clean_i-1

                                    end
                                    ----logger(30, "clean out")

                                --Clean(div2_x3)
                                ------logger(30, "div2 out")
                                --return div2_u
                            sdiv_z = div2_x3
--logger(30, "End div2")
                            --r = div2_u
                            --Div2(sdiv_z)

                            local sub_x2 = sdiv_x
                            local sub_y2 = sdiv_z
--logger(30, "1")
                                ----logger(30, "Bigint sub in")
                                local sub_z2,sub_l2,sub_i2,sub_r2 = {},max(#sub_x2,#sub_y2)
--logger(30, "2")
                                sub_z2[1] = 0
--logger(30, "3")
                                for sub_i2 = 1,sub_l2 do
--logger(30, "4")
                                    sub_r2 = (sub_x2[sub_i2] or 0)-(sub_y2[sub_i2] or 0)-sub_z2[sub_i2]
--logger(30, "5")
                                    if (sub_r2<0) then
--logger(30, "6")
                                        sub_z2[sub_i2] = sub_r2+16777216
--logger(30, "7")
                                        sub_z2[sub_i2+1] = 1
--logger(30, "8")
                                    else
--logger(30, "9")
                                        sub_z2[sub_i2] = sub_r2
--logger(30, "10")
                                        sub_z2[sub_i2+1] = 0
                                    end

                                end
--logger(30, "11")
                                if (sub_z2[sub_l2+1]==1) then
--logger(30, "12")
                                    sub_z2 = nil
--logger(30, "13")
                                else
                                        local clean_i = #sub_z2
--logger(30, "14")
                                        while (clean_i>1 and sub_z2[clean_i]==0) do
--logger(30, "15")
                                            sub_z2[clean_i] = nil
--logger(30, "16")
                                            clean_i = clean_i-1
--logger(30, "17")
                                        end
                                    --Clean(sub_z2)
                                end
                                --Clean(sub_z2)
                                ----logger(30, "Bigint sub out")
                                --return Clean(sub_z)
                                ----logger(30, "Bigint sub out")
                            sdiv_v = sub_z2
--logger(30, "End subtract2")
                            --sdiv_v = BigInt_Sub2(sdiv_x,sdiv_z)
                            if (sdiv_v~=nil) then
                                sdiv_u = sdiv_u+sdiv_j
                                sdiv_x = sdiv_v
                            end
                        end
                        ------logger(30, "simple div out")
                    div_v = sdiv_u
                    div_u = sdiv_x


                    --div_v,div_u = SimpleDiv(div_u, div_y)
                    table.insert(div_z,1,div_v)
                end
--logger(30, "End div and multiply2")

                    ----logger(30, "clean in")
                    local clean_i = #div_z
                    while (clean_i>1 and div_z[clean_i]==0) do
                        div_z[clean_i] = nil
                        clean_i = clean_i-1

                    end
                    ----logger(30, "clean out")
                --Clean(div_z)
                ------logger(30, "Bigint div out")
            r = div_z
            b = div_u


		--r,b = BigInt_Div(BigInt_Mul(b,b),m)

        --logger(30, "End iteration2")
	until (#t==1 and t[1]==0)
    logger(30, "Returning s")
	return s
end


_M.mod_power = BigInt_ModPower2
---------------------------------------
--- ModPower Step Functions -----------
---------------------------------------

local function BigInt_MP_StepInit(b,e,m)				--initialize nonblocking ModPower,
	local x,i = {b,{},m,{1},1}				--pass resulting table to StepExec!
	for i = 1,getn(e) do
		x[2][i] = e[i]
	end
	return x
end

---------------------------------------

local function BigInt_MP_StepExec(x)					--execute next calculation step,
	local r							--finished if result~=nil.
	if (x[5]==1) then
		x[5] = 2
		r = Div2(x[2])
		if (r==1) then
			r,x[4] = BigInt_Div(BigInt_Mul(x[4],x[1]),x[3])
		end
		return nil
	end
	if (x[5]==2) then
		x[5] = 1
		r,x[1] = BigInt_Div(BigInt_Mul(x[1],x[1]),x[3])
		if (getn(x[2])==1 and x[2][1]==0) then
			x[5] = 0
			return x[4]
		end
		return nil
	end
	return nil
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

return _M