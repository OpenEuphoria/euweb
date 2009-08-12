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
".1/0435ÞÞÞÞiûÞÞÞÞiëÞÞÞÞióÞÞÞÞœÞÞÞÞg»ÿ«g½ÕµÿµçÛßÆáäãV‚HµŸžåß¶g£ÿ»g"+34&
"¡Ñ±û©ã×ÛÄÝ0Þ[œ0‘¡Â›œæÛœc¯ûŸc±Ñ±û¹ã×ÛÃÝ(â[›µJúþ››ëÛ«c§û¯c©Ñ±û¡ã×ÛÅÝ"+38&
"<ê_¡Ì¬›ŸŸ¡ôß©g»ÿ«g½ÕµÿµçÛßÆá$îãíZÓŸžåß¶g£ÿ»g¥Õµÿ­çÛßÈá4ò_ "+34&
"Ée&æ`a« a(tÀd(v–vÀ~¨œ ˆ¢í· `²åÏG``° p(lÀt(n–vÀf¨œ Š¢ý» b 4åœ`bµ j("+97&
"”Ø„@–®ŽØŽÀ´¸Ÿºý×¼O7 xw¾¸@|Ø”@~®ŽØ†À´¸¡º\rÛ8yf®ûBxyÃ¸y@ŒØ|@Ž®ŽØ–À"+73&
"¡‰£îÈ!aQûŸŸaa±¡q)mÁu)o—wÁg©¡‹£þÌ!c^wü)ac¶¡k)}Ám)—wÁw©¡ˆ£æÐ¥Â±0"+96&
"Î$#jd;ì(„@ì*Z:„2l`dMf¹—ä%öÔû`$%od%ì8„(ì:Z:„Bl`dLf±›ä$ñ¦Ü\t$$td4ì0„"-99&
"KÿEmM—=swayÔ²÷9—~*¿79ŒwAÿS—KÿMmM—Esw^y¼z{Ø›”l76{wNÿ;—CÿEmM—Usw"-118&
"Š£ö¸!bàSà`ab©¡b)uÁ})—wÁg©¡‰£îÌ!añúþÆaa®¡q)mÁe)g—wÁw©¡‹£¾!cJgV‰a"+96&
"e¶£m+Ãw+y™yÃq«Ÿ£Š¥è¶§ÿ²Ñxcb§£z+gÃo+q™yÃ«Ÿ£Œ¥øÊ#dõ¶æ¤cd«£d+wÃ+™"+94&
"wÁg©¡‰£îÜ!a!†Axaa®¡q)mÁe)g—wÁw©¡‹£þ°!ch›s‡ac´¡k)}Áu)w—wÁo©¡ˆ£æÄ"+96&
"®vŠÊji®ª2nÊv2x €Êˆ²¦ª“¬ÿá*k°àljk²ªk2~Ê†2ˆ €Êp²¦ª’¬÷µ*j0¶~jj·ªz"+87&
")mÁe)g—wÁw©¡‹£þÀ!c´úåac´¡k)}Áu)w—wÁo©¡ˆ£æÔ¥¥‰ƒIa`¥¡x)eÁm)o—wÁ©"+96&
"ÛßÈá4æ_ ÖÍÚŸ çß g³ÿ»g½Õµÿ¥çÛßÇá,ú_Ÿ·àMEŸŸìß¯g«ÿ£g¥ÕµÿµçÛßÉá<"+34&
"“ä&í¯ð$&wd.ì@”0”8dKf©wh¥œ]b$#gd;ì(”@”0dMf¹ƒä%äYÔê$%nd%ì8”(”@dLf±"-99&
"á!‚ÁýÍ!!pa1é-‘5‘%aKc¾˜á#l˜E]!#wa+é=‘-‘5aHc¦de¤J"-96&
"]C`_£ w(dÐ|Ðl ‰¢õ¯ aHn}ê`aª a(tÐdÐ| ˆ¢í» `ÿêZ•``¯ p(lÐtÐd Š¢ýÇ b"+97&
"!mportÈ²|:Žâ~â†²™´÷å¶w/LÙrqµ²‰:vâŽâ~²›´Ç2s«ØR›rs¼²s:†âvâŽ²š´ÿ½2r6á"+79&
"taa°¡q)mÑuÑe¡‹£þ¸!c¥½(¤ac·¡k)}ÑmÑu¡ˆ£æÄ¥Ùptya`¤¡x)eÑ}Ñm¡Š£öÐ!b…9{"+96&
"—rs¼²s:†âvâŽ²š´ÿí2r©-SÐrrÁ²‚:~â†âv²œ´"+79&
"Ô~÷9ÛÌ\":79wAÿKmKS§Cw^y|{º˜Ÿj76|wNÿCmK;§Sw`yÌ’÷8\ru ¹78€w8ÿSmK"-118&
"©uÑe¡‰£îØ!aGÃ4Kaa¯¡q)e—u©mÑu¡‹£þ´!cÙ@3œacµ¡k)u—u©}Ñm¡ˆ£æÐ¥cùû"+96&
"È$#id;ì0Z8l(”@dMf¹oä%õ/oò$%md%ì@Z8l8”(dLf±‹ä$àWRb$$rd4ì(Z8l0”8dNfÁ"-99&
"fã%3¿æç#%wc-ë7Y7k?“/cJe¨‚g±à\nÑ#\"hc:ë/Y7k\'“?cLe¸žã$BHŽ`#$lc$ë?Y7"-98&
"¨tÐd ˆ¢í· `³â B``® p(d–t¨lÐt Š¢ýÓ b@°§í`b´ j(t–t¨|Ðl ‡¢å¯¤!"+97&
"&ûŸih®©€1uŸ}±mÙ…©’«þÔ)jÝšâeij²©j1…Ÿ}±}Ùm©‘«ö°)iczÒii·©y1mŸ}±uÙ}©“"+88&
"Ý8þ[k­`Å›ïÛ¥ÛßÚÚÚÚÛ÷ÚÚÚÚÛçÚÚÚÚÛïÚÚÚÚ9784352"+38))

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
