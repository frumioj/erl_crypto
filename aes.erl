-module(aes).
-export([rot_word/1, sub_word/1, rcon/1, next_round/2, sub_bytes/1, shift_rows/1]).

-define(SBOX, <<16#63, 16#7c, 16#77, 16#7b, 16#f2, 16#6b, 16#6f, 16#c5, 16#30, 16#01, 16#67, 16#2b, 16#fe, 16#d7, 16#ab, 16#76,
		16#ca, 16#82, 16#c9, 16#7d, 16#fa, 16#59, 16#47, 16#f0, 16#ad, 16#d4, 16#a2, 16#af, 16#9c, 16#a4, 16#72, 16#c0,
		16#b7, 16#fd, 16#93, 16#26, 16#36, 16#3f, 16#f7, 16#cc, 16#34, 16#a5, 16#e5, 16#f1, 16#71, 16#d8, 16#31, 16#15,
		16#04, 16#c7, 16#23, 16#c3, 16#18, 16#96, 16#05, 16#9a, 16#07, 16#12, 16#80, 16#e2, 16#eb, 16#27, 16#b2, 16#75,
		16#09, 16#83, 16#2c, 16#1a, 16#1b, 16#6e, 16#5a, 16#a0, 16#52, 16#3b, 16#d6, 16#b3, 16#29, 16#e3, 16#2f, 16#84,
		16#53, 16#d1, 16#00, 16#ed, 16#20, 16#fc, 16#b1, 16#5b, 16#6a, 16#cb, 16#be, 16#39, 16#4a, 16#4c, 16#58, 16#cf,
		16#d0, 16#ef, 16#aa, 16#fb, 16#43, 16#4d, 16#33, 16#85, 16#45, 16#f9, 16#02, 16#7f, 16#50, 16#3c, 16#9f, 16#a8,
		16#51, 16#a3, 16#40, 16#8f, 16#92, 16#9d, 16#38, 16#f5, 16#bc, 16#b6, 16#da, 16#21, 16#10, 16#ff, 16#f3, 16#d2,
		16#cd, 16#0c, 16#13, 16#ec, 16#5f, 16#97, 16#44, 16#17, 16#c4, 16#a7, 16#7e, 16#3d, 16#64, 16#5d, 16#19, 16#73,
		16#60, 16#81, 16#4f, 16#dc, 16#22, 16#2a, 16#90, 16#88, 16#46, 16#ee, 16#b8, 16#14, 16#de, 16#5e, 16#0b, 16#db,
		16#e0, 16#32, 16#3a, 16#0a, 16#49, 16#06, 16#24, 16#5c, 16#c2, 16#d3, 16#ac, 16#62, 16#91, 16#95, 16#e4, 16#79,
		16#e7, 16#c8, 16#37, 16#6d, 16#8d, 16#d5, 16#4e, 16#a9, 16#6c, 16#56, 16#f4, 16#ea, 16#65, 16#7a, 16#ae, 16#08,
		16#ba, 16#78, 16#25, 16#2e, 16#1c, 16#a6, 16#b4, 16#c6, 16#e8, 16#dd, 16#74, 16#1f, 16#4b, 16#bd, 16#8b, 16#8a,
		16#70, 16#3e, 16#b5, 16#66, 16#48, 16#03, 16#f6, 16#0e, 16#61, 16#35, 16#57, 16#b9, 16#86, 16#c1, 16#1d, 16#9e,
		16#e1, 16#f8, 16#98, 16#11, 16#69, 16#d9, 16#8e, 16#94, 16#9b, 16#1e, 16#87, 16#e9, 16#ce, 16#55, 16#28, 16#df,
		16#8c, 16#a1, 16#89, 16#0d, 16#bf, 16#e6, 16#42, 16#68, 16#41, 16#99, 16#2d, 16#0f, 16#b0, 16#54, 16#bb, 16#16>>).

-define(RCON, <<16#8d, 16#01, 16#02, 16#04, 16#08, 16#10, 16#20, 16#40, 16#80, 16#1b, 16#36, 16#6c, 16#d8, 16#ab, 16#4d, 16#9a,
		16#2f, 16#5e, 16#bc, 16#63, 16#c6, 16#97, 16#35, 16#6a, 16#d4, 16#b3, 16#7d, 16#fa, 16#ef, 16#c5, 16#91, 16#39,
		16#72, 16#e4, 16#d3, 16#bd, 16#61, 16#c2, 16#9f, 16#25, 16#4a, 16#94, 16#33, 16#66, 16#cc, 16#83, 16#1d, 16#3a,
		16#74, 16#e8, 16#cb, 16#8d, 16#01, 16#02, 16#04, 16#08, 16#10, 16#20, 16#40, 16#80, 16#1b, 16#36, 16#6c, 16#d8,
		16#ab, 16#4d, 16#9a, 16#2f, 16#5e, 16#bc, 16#63, 16#c6, 16#97, 16#35, 16#6a, 16#d4, 16#b3, 16#7d, 16#fa, 16#ef,
		16#c5, 16#91, 16#39, 16#72, 16#e4, 16#d3, 16#bd, 16#61, 16#c2, 16#9f, 16#25, 16#4a, 16#94, 16#33, 16#66, 16#cc,
		16#83, 16#1d, 16#3a, 16#74, 16#e8, 16#cb, 16#8d, 16#01, 16#02, 16#04, 16#08, 16#10, 16#20, 16#40, 16#80, 16#1b,
		16#36, 16#6c, 16#d8, 16#ab, 16#4d, 16#9a, 16#2f, 16#5e, 16#bc, 16#63, 16#c6, 16#97, 16#35, 16#6a, 16#d4, 16#b3,
		16#7d, 16#fa, 16#ef, 16#c5, 16#91, 16#39, 16#72, 16#e4, 16#d3, 16#bd, 16#61, 16#c2, 16#9f, 16#25, 16#4a, 16#94,
		16#33, 16#66, 16#cc, 16#83, 16#1d, 16#3a, 16#74, 16#e8, 16#cb, 16#8d, 16#01, 16#02, 16#04, 16#08, 16#10, 16#20,
		16#40, 16#80, 16#1b, 16#36, 16#6c, 16#d8, 16#ab, 16#4d, 16#9a, 16#2f, 16#5e, 16#bc, 16#63, 16#c6, 16#97, 16#35,
		16#6a, 16#d4, 16#b3, 16#7d, 16#fa, 16#ef, 16#c5, 16#91, 16#39, 16#72, 16#e4, 16#d3, 16#bd, 16#61, 16#c2, 16#9f,
		16#25, 16#4a, 16#94, 16#33, 16#66, 16#cc, 16#83, 16#1d, 16#3a, 16#74, 16#e8, 16#cb, 16#8d, 16#01, 16#02, 16#04,
		16#08, 16#10, 16#20, 16#40, 16#80, 16#1b, 16#36, 16#6c, 16#d8, 16#ab, 16#4d, 16#9a, 16#2f, 16#5e, 16#bc, 16#63,
		16#c6, 16#97, 16#35, 16#6a, 16#d4, 16#b3, 16#7d, 16#fa, 16#ef, 16#c5, 16#91, 16#39, 16#72, 16#e4, 16#d3, 16#bd,
		16#61, 16#c2, 16#9f, 16#25, 16#4a, 16#94, 16#33, 16#66, 16#cc, 16#83, 16#1d, 16#3a, 16#74, 16#e8, 16#cb, 16#8d>>).

rot_word(<<One:8, Two:8, Three:8, Four:8>>) -> 
    <<Two, Three, Four, One>>.

sub_word(<<One:8, Two:8, Three:8, Four:8>>) ->
    <<OneRow:4, OneCol:4, TwoRow:4, TwoCol:4, ThreeRow:4, ThreeCol:4, FourRow:4, FourCol:4>> = <<One,Two,Three,Four>>,
    OutOne = binary:at(?SBOX, (OneRow*16)+OneCol),
    OutTwo = binary:at(?SBOX, (TwoRow*16)+TwoCol),
    OutThree = binary:at(?SBOX, (ThreeRow*16)+ThreeCol),
    OutFour = binary:at(?SBOX, (FourRow*16)+FourCol),
    <<OutOne,OutTwo,OutThree,OutFour>>.

rcon(N) ->
    R = binary:at(?RCON, N),
    <<R, 16#0, 16#0, 16#0>>.

% takes the current round key and returns the next one
next_round(<<One:8, Two:8, Three:8, Four:8, Five:8, Six:8, Seven:8, Eight:8, Nine:8, Ten:8, Elevn:8, Twelv:8, Thrteen:8, Forteen:8, Ffteen:8, Sxteen:8>>, N) ->
    First = (binary:decode_unsigned(sub_word( rot_word( <<Thrteen, Forteen, Ffteen, Sxteen>> ))) bxor binary:decode_unsigned(<<One,Two,Three,Four>>)) bxor binary:decode_unsigned(rcon(N)),
    Second = binary:decode_unsigned(<<Five,Six,Seven,Eight>>) bxor First,
    Third = binary:decode_unsigned(<<Nine,Ten,Elevn,Twelv>>) bxor Second,
    Forth = binary:decode_unsigned(<<Thrteen, Forteen, Ffteen, Sxteen>>) bxor Third,
    BinOne = binary:encode_unsigned(First),
    BinTwo = binary:encode_unsigned(Second),
    BinThree = binary:encode_unsigned(Third),
    BinFour = binary:encode_unsigned(Forth),
    <<On:8, Tw:8, Thre:8, Fou:8, Fiv:8, Sx:8, Svn:8, Et:8, Nne:8, Tn:8, Elvn:8, Twlv:8, Thrten:8, Forten:8, Fften:8, Sxten:8>> = <<BinOne/binary,BinTwo/binary,BinThree/binary,BinFour/binary>>,
    <<On, Tw, Thre, Fou, Fiv, Sx, Svn, Et, Nne, Tn, Elvn, Twlv, Thrten, Forten, Fften, Sxten>>.

sub_bytes(<<One:8, Two:8, Three:8, Four:8, Five:8, Six:8, Seven:8, Eight:8, Nine:8, Ten:8, Elevn:8, Twelv:8, Thrteen:8, Forteen:8, Ffteen:8, Sxteen:8>>) ->
    OutOne = binary:at(?SBOX, One),
    OutTwo = binary:at(?SBOX, Two),
    OutThree = binary:at(?SBOX, Three),
    OutFour = binary:at(?SBOX, Four),
    OutFive = binary:at(?SBOX, Five),
    OutSix = binary:at(?SBOX, Six),
    OutSevn = binary:at(?SBOX, Seven),
    OutEight = binary:at(?SBOX, Eight),
    OutNine = binary:at(?SBOX, Nine),
    OutTen = binary:at(?SBOX, Ten),
    OutElvn = binary:at(?SBOX, Elevn),
    OutTwlv = binary:at(?SBOX, Twelv),
    OutThrteen = binary:at(?SBOX, Thrteen),
    OutFrteen = binary:at(?SBOX, Forteen),
    OutFfteen = binary:at(?SBOX, Ffteen),
    OutSxteen = binary:at(?SBOX, Sxteen),
    <<OutOne,OutTwo,OutThree,OutFour, OutFive, OutSix, OutSevn, OutEight, OutNine, OutTen, OutElvn, OutTwlv, OutThrteen, OutFrteen, OutFfteen, OutSxteen>>.    

shift_rows(<<One:8, Two:8, Three:8, Four:8, Five:8, Six:8, Seven:8, Eight:8, Nine:8, Ten:8, Elevn:8, Twelv:8, Thrteen:8, Forteen:8, Ffteen:8, Sxteen:8>>) ->
    <<OutTwo, OutSix, OutTen, OutForteen>> = rot_word(<<Two,Six,Ten,Forteen>>),
    <<OutThree, OutSevn, OutElvn, OutFfteen>> = rot_word(rot_word(<<Three, Seven, Elevn, Ffteen>>)),
    <<OutFour, OutEight, OutTwelv, OutSxteen>> = rot_word(rot_word(rot_word(<<Four, Eight, Twelv, Sxteen>>))),
    <<One, OutTwo, OutThree, OutFour, Five, OutSix, OutSevn, OutEight, Nine, OutTen, OutElvn, OutTwelv, Thrteen, OutForteen, OutFfteen, OutSxteen>>.
