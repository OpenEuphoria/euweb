-- md5.e - The MD5 Message-Digest Algorithm - version 1.11
-- Copyright (C) 2000  Davi Tassinari de Figueiredo
--
-- If you wish to contact me, send an e-mail to davitf@usa.net .
--
-- You can get the latest version of this program from my Euphoria page:
-- http://davitf.n3.net/
--
--
-- License terms and disclaimer:
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software or remove the original
--    authors' names.
-- 2. Altered source versions must be plainly marked as such, and must not
--    be misrepresented as being the original software.
-- 3. All source distributions, with or without modifications, must be
--    distributed under this license. If this software's source code is
--    distributed as part of a larger product, this item does not apply to
--    the rest of the product.
-- 4. If you use this software in a product, an acknowledgment in the
--    product documentation is required. If the source code for the product
--    is not freely distributed, you must include information on how to
--    freely obtain the original software's source code.
--
-- This software is provided 'as-is', without any express or implied
-- warranty.  In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- If you want to distribute this software in a way not allowed by this
-- license, or distribute the source under different license terms, contact
-- the authors for permission.


include std/machine.e
include std/convert.e

-- 'General-purpose' routines

global constant a_address = allocate(16), b_address = a_address + 4,
	 c_address = b_address + 4, d_address = c_address + 4,
	 data_address = allocate(64)

global constant md5asm = allocate (1679)


-- This is an Assembly routine created by md5asm.ex, compiled with Pete
-- Eberlein's ASM to Euphoria converter and transformed into a string to
-- save space.

poke (md5asm, and_bits(#FF,
".1/0435����i�����i�����i����ޜ����g���g�յ���������V�H����߶g���g"+34&
"�ѱ�������0�[�0����ۜc���c�ѱ�������(�[��J�����۫c���c�ѱ�������"+38&
"<�_�̬�����ߩg���g�յ�������$���Zӟ��߶g���g�յ�������4�_�"+34&
"�e&�`a��a(t�d(v�v�~������ `���G``��p(l�t(n�v�f������� b�4�`b��j("+97&
"�؄@���؎������׼�O7 xw���@|ؔ@~��؆�����\r�8yf��Bxyøy@��|@���ؖ�"+73&
"������!aQ���aa��q)m�u)o�w�g�������!c^w�)ac��k)}�m)�w�w������Х±0"+96&
"�$#jd;�(�@�*Z:�2l`dMf���%���`$%od%�8�(�:Z:�Bl`dLf���$��\t$$td4�0�"-99&
"K�EmM�=swayԲ�9�~*�79�wA�S�K�MmM�Esw^y�z{؛�l76{wN�;�C�EmM�Usw"-118&
"����!b�S�`ab��b)u�})�w�g�������!a����aa��q)m�e)g�w�w������!cJgV�a"+96&
"e��m+�w+y�y�q�����趧���xcb��z+g�o+q�yÁ�������#d���cd��d+w�+��"+94&
"w�g�������!a!�Axaa��q)m�e)g�w�w�������!ch�s�ac��k)}�u)w�w�o�������"+96&
"��v��ji���2n�v2x��ʈ�������*k��ljk��k2~ʆ2����p�������*j0�~�jj��z"+87&
")m�e)g�w�w�������!c����ac��k)}�u)w�w�o������ԥ���Ia`��x)e�m)o�w��"+96&
"����4�_�ց�ڟ��ߠg���g�յ�������,�_���ME���߯g���g�յ�������<"+34&
"��&��$&wd.�@�0�8dKf�wh��]b$#gd;�(�@�0dMf���%�Y��$%nd%�8�(�@dLf��"-99&
"�!����!!pa1�-�5�%aKc���#l�E]!#wa+�=�-�5aHc�de�J"-96&
"]C`_��w(d�|�l����� aHn}�`a��a(t�d�|���� `��Z�``��p(l�t�d����� b"+97&
"!mportȲ|:��~↲����w/L�rq���:v��~����2s��R�rs��s:��v⎲����2r6�"+79&
"�taa��q)m�u�e�����!c��(�ac��k)}�m�u����ĥ�ptya`��x)e�}�m�����!b�9{"+96&
"�rs��s:��v⎲����2r�-S�rr���:~��v���"+79&
"�~�9��\":79�wA�KmKS�Cw^y|{���j76|wN�CmK;�Sw`y̒�8\ru��78�w8�SmK"-118&
"�u�e�����!aG�4Kaa��q)e�u�m�u�����!c�@3�ac��k)u�u�}�m����Хc��"+96&
"�$#id;�0Z8l(�@dMf�o�%�/o�$%md%�@Z8l8�(dLf���$�WRb$$rd4�(Z8l0�8dNf�"-99&
"f�%3���#%wc-�7Y7k?�/cJe��g��\n�#\"hc:�/Y7k\'�?cLe���$BH�`#$lc$�?Y7"-98&
"�t�d���� `��B``��p(d�t�l�t����� b@���`b��j(t�t�|�l���寤!"+97&
"&��ih���1u�}�mم�����)jݚ�eij��j1��}�}�m�����)icz�ii��y1m�}�u�}��"+88&
"�8�[�k�`ś��ۥ������������������������9784352�"+38))

poke4(md5asm + 8, a_address)
poke4(md5asm + 14, b_address)
poke4(md5asm + 20, c_address)
poke4(md5asm + 26, d_address)
poke4(md5asm + 31, data_address)
poke4(md5asm + 1649, a_address)
poke4(md5asm + 1655, b_address)
poke4(md5asm + 1661, c_address)
poke4(md5asm + 1667, d_address)



procedure init_md5()
    poke4(a_address, #67452301)
    poke4(b_address, #EFCDAB89)
    poke4(c_address, #98BADCFE)
    poke4(d_address, #10325476)
end procedure


function pad_message(sequence message)
    -- Add bytes to the end of the message so it can be divided
    -- in an exact number of 64-byte blocks.

    atom bytes_to_add
    bytes_to_add=64-remainder(length(message)+9,64)
    if bytes_to_add=64 then bytes_to_add=0 end if

    message=message&128&repeat(0,bytes_to_add)&
      int_to_bytes(length(message)*8)&{0,0,0,0}

    return message
end function


public function md5(sequence message)
    -- Given a string, returns a 16-byte hash of it.

    init_md5()

    message=pad_message(message)    -- Add bytes to the message

    -- Process each 64-byte block
    for pos_in_message=1 to length(message) by 64 do

	-- Write data into memory
	poke(data_address, message[pos_in_message..pos_in_message+63])
	-- Call calculation routine
	call(md5asm)

    end for

    -- Get hash from memory
    return peek( {a_address, 16} )    -- Return the hash

end function

public function md5hex(sequence message)
  sequence smd5 = md5(message), hmd5 = ""
  
  for x = 1 to length(smd5) do
    hmd5 &= sprintf("%x",smd5[x])
  end for

  return hmd5
end function
