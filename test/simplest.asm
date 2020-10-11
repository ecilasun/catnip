# Instruction count: 159

@ORG 0x00000000

call main

@LABEL infloop
vsync
jmp infloop
# End of program

@LABEL vblank
ret 

@LABEL main
lea r0, vblank
lea r1, _VBLANKSERVICE
st.d [r1], r0
ld.d r0, 0x1
ld.d r1, 0x0
lea r2, _VBSENABLE
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0
lea r0, _mysprites
spritesheet r0

@LABEL beginwhile00000002
ld.d r0, 0x1
jmpifnot endwhile00000003, r0
lea r0, _bcolor
ld.w r0, [r0]
ld.d r1, 0x0
lea r2, _BORDERCOLOR
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0
lea r0, main_posX
ld.w r0, [r0]
lea r1, main_dirX
ld.w r1, [r1]
iadd r0, r1
lea r1, main_posX
st.w [r1], r0
lea r0, main_posY
ld.w r0, [r0]
lea r1, main_dirY
ld.w r1, [r1]
iadd r0, r1
lea r1, main_posY
st.w [r1], r0
lea r0, main_posY
ld.w r0, [r0]
ld.d r1, 0xa9
cmp r0, r1
test r0, greater
lea r1, main_posY
ld.w r1, [r1]
ld.d r2, 0x1
cmp r1, r2
test r1, less
or r0, r1
jmpifnot endif00000000, r0
lea r0, main_dirY
ld.w r0, [r0]
ineg r0
lea r1, main_dirY
st.w [r1], r0
lea r0, _bcolor
ld.w r0, [r0]
inc r0
lea r1, _bcolor
st.w [r1], r0

@LABEL endif00000000
lea r0, main_posX
ld.w r0, [r0]
ld.d r1, 0xf0
cmp r0, r1
test r0, greater
lea r1, main_posX
ld.w r1, [r1]
ld.d r2, 0x1
cmp r1, r2
test r1, less
or r0, r1
jmpifnot endif00000001, r0
lea r0, main_dirX
ld.w r0, [r0]
ineg r0
lea r1, main_dirX
st.w [r1], r0
lea r0, _bcolor
ld.w r0, [r0]
inc r0
lea r1, _bcolor
st.w [r1], r0

@LABEL endif00000001
lea r0, main_posY
ld.w r0, [r0]
ld.d r1, 0x4a4
ld.d r2, 0x0
iadd r1, r2
lea r2, _spritelist
iadd r1, r2
st.w [r1], r0
lea r0, main_posX
ld.w r0, [r0]
ld.d r1, 0x4a4
ld.d r2, 0x2
iadd r1, r2
lea r2, _spritelist
iadd r1, r2
st.w [r1], r0
lea r0, main_posY
ld.w r0, [r0]
ld.d r1, 0x10
iadd r0, r1
ld.d r1, 0x4aa
ld.d r2, 0x0
iadd r1, r2
lea r2, _spritelist
iadd r1, r2
st.w [r1], r0
lea r0, main_posX
ld.w r0, [r0]
ld.d r1, 0x4aa
ld.d r2, 0x2
iadd r1, r2
lea r2, _spritelist
iadd r1, r2
st.w [r1], r0
lea r0, _spritelist
ld.d r1, 0xc8
sprite r0, r1
lea r0, main_frame
ld.w r0, [r0]
inc r0
lea r1, main_frame
st.w [r1], r0
vsync 
lea r0, main_frame
ld.w r0, [r0]
fsel r0
jmp beginwhile00000002

@LABEL endwhile00000003

#-------------Symbol Table-------------

# function 'vblank', hash: D127AEAD, refcount: 2
# function 'main', hash: BC76E6BA, refcount: 1
# variable 'VRAM', dim:1 typename:byteptr refcount:0
# variable 'BORDERCOLOR', dim:1 typename:byteptr refcount:1
@LABEL _BORDERCOLOR
@DW 0x8000 0xC000
# variable 'VBSENABLE', dim:1 typename:byteptr refcount:1
@LABEL _VBSENABLE
@DW 0x8000 0xC001
# variable 'VBLANKSERVICE', dim:1 typename:dwordptr refcount:1
@LABEL _VBLANKSERVICE
@DW 0x8000 0xC004
# variable 'bcolor', dim:1 typename:word refcount:5
@LABEL _bcolor
@DW 0x0000 
# variable 'spritelist', dim:600 typename:word refcount:5
@LABEL _spritelist
@DW 0x0000 0x0000 0x0006 0x0000 0x0010 0x0006 0x0000 0x0020 
@DW 0x0006 0x0000 0x0030 0x0006 0x0000 0x0040 0x0006 0x0000 
@DW 0x0050 0x0006 0x0000 0x0060 0x0006 0x0000 0x0070 0x0006 
@DW 0x0000 0x0080 0x0006 0x0000 0x0090 0x0006 0x0000 0x00A0 
@DW 0x0006 0x0000 0x00B0 0x0006 0x0000 0x00C0 0x0006 0x0000 
@DW 0x00D0 0x0006 0x0000 0x00E0 0x0006 0x0000 0x00F0 0x0006 
@DW 0x0010 0x0000 0x0006 0x0010 0x0010 0x0006 0x0010 0x0020 
@DW 0x0006 0x0010 0x0030 0x0006 0x0010 0x0040 0x0006 0x0010 
@DW 0x0050 0x0006 0x0010 0x0060 0x0006 0x0010 0x0070 0x0006 
@DW 0x0010 0x0080 0x0006 0x0010 0x0090 0x0006 0x0010 0x00A0 
@DW 0x0006 0x0010 0x00B0 0x0006 0x0010 0x00C0 0x0006 0x0010 
@DW 0x00D0 0x0006 0x0010 0x00E0 0x0006 0x0010 0x00F0 0x0006 
@DW 0x0020 0x0000 0x0006 0x0020 0x0010 0x0006 0x0020 0x0020 
@DW 0x0006 0x0020 0x0030 0x0006 0x0020 0x0040 0x0006 0x0020 
@DW 0x0050 0x0006 0x0020 0x0060 0x0006 0x0020 0x0070 0x0006 
@DW 0x0020 0x0080 0x0006 0x0020 0x0090 0x0006 0x0020 0x00A0 
@DW 0x0006 0x0020 0x00B0 0x0006 0x0020 0x00C0 0x0006 0x0020 
@DW 0x00D0 0x0006 0x0020 0x00E0 0x0006 0x0020 0x00F0 0x0006 
@DW 0x0030 0x0000 0x0006 0x0030 0x0010 0x0006 0x0030 0x0020 
@DW 0x0006 0x0030 0x0030 0x0006 0x0030 0x0040 0x0006 0x0030 
@DW 0x0050 0x0006 0x0030 0x0060 0x0006 0x0030 0x0070 0x0006 
@DW 0x0030 0x0080 0x0006 0x0030 0x0090 0x0006 0x0030 0x00A0 
@DW 0x0006 0x0030 0x00B0 0x0006 0x0030 0x00C0 0x0006 0x0030 
@DW 0x00D0 0x0006 0x0030 0x00E0 0x0006 0x0030 0x00F0 0x0006 
@DW 0x0040 0x0000 0x0006 0x0040 0x0010 0x0006 0x0040 0x0020 
@DW 0x0006 0x0040 0x0030 0x0006 0x0040 0x0040 0x0006 0x0040 
@DW 0x0050 0x0006 0x0040 0x0060 0x0006 0x0040 0x0070 0x0006 
@DW 0x0040 0x0080 0x0006 0x0040 0x0090 0x0006 0x0040 0x00A0 
@DW 0x0006 0x0040 0x00B0 0x0006 0x0040 0x00C0 0x0006 0x0040 
@DW 0x00D0 0x0006 0x0040 0x00E0 0x0006 0x0040 0x00F0 0x0006 
@DW 0x0050 0x0000 0x0006 0x0050 0x0010 0x0006 0x0050 0x0020 
@DW 0x0006 0x0050 0x0030 0x0006 0x0050 0x0040 0x0006 0x0050 
@DW 0x0050 0x0006 0x0050 0x0060 0x0006 0x0050 0x0070 0x0006 
@DW 0x0050 0x0080 0x0006 0x0050 0x0090 0x0006 0x0050 0x00A0 
@DW 0x0006 0x0050 0x00B0 0x0006 0x0050 0x00C0 0x0006 0x0050 
@DW 0x00D0 0x0006 0x0050 0x00E0 0x0006 0x0050 0x00F0 0x0006 
@DW 0x0060 0x0000 0x0006 0x0060 0x0010 0x0006 0x0060 0x0020 
@DW 0x0006 0x0060 0x0030 0x0006 0x0060 0x0040 0x0006 0x0060 
@DW 0x0050 0x0006 0x0060 0x0060 0x0006 0x0060 0x0070 0x0006 
@DW 0x0060 0x0080 0x0006 0x0060 0x0090 0x0006 0x0060 0x00A0 
@DW 0x0006 0x0060 0x00B0 0x0006 0x0060 0x00C0 0x0006 0x0060 
@DW 0x00D0 0x0006 0x0060 0x00E0 0x0006 0x0060 0x00F0 0x0006 
@DW 0x0070 0x0000 0x0006 0x0070 0x0010 0x0006 0x0070 0x0020 
@DW 0x0006 0x0070 0x0030 0x0006 0x0070 0x0040 0x0006 0x0070 
@DW 0x0050 0x0006 0x0070 0x0060 0x0006 0x0070 0x0070 0x0006 
@DW 0x0070 0x0080 0x0006 0x0070 0x0090 0x0006 0x0070 0x00A0 
@DW 0x0006 0x0070 0x00B0 0x0006 0x0070 0x00C0 0x0006 0x0070 
@DW 0x00D0 0x0006 0x0070 0x00E0 0x0006 0x0070 0x00F0 0x0006 
@DW 0x0080 0x0000 0x0006 0x0080 0x0010 0x0006 0x0080 0x0020 
@DW 0x0006 0x0080 0x0030 0x0006 0x0080 0x0040 0x0006 0x0080 
@DW 0x0050 0x0006 0x0080 0x0060 0x0006 0x0080 0x0070 0x0006 
@DW 0x0080 0x0080 0x0006 0x0080 0x0090 0x0006 0x0080 0x00A0 
@DW 0x0006 0x0080 0x00B0 0x0006 0x0080 0x00C0 0x0006 0x0080 
@DW 0x00D0 0x0006 0x0080 0x00E0 0x0006 0x0080 0x00F0 0x0006 
@DW 0x0090 0x0000 0x0006 0x0090 0x0010 0x0006 0x0090 0x0020 
@DW 0x0006 0x0090 0x0030 0x0006 0x0090 0x0040 0x0006 0x0090 
@DW 0x0050 0x0006 0x0090 0x0060 0x0006 0x0090 0x0070 0x0006 
@DW 0x0090 0x0080 0x0006 0x0090 0x0090 0x0006 0x0090 0x00A0 
@DW 0x0006 0x0090 0x00B0 0x0006 0x0090 0x00C0 0x0006 0x0090 
@DW 0x00D0 0x0006 0x0090 0x00E0 0x0006 0x0090 0x00F0 0x0006 
@DW 0x00A0 0x0000 0x0006 0x00A0 0x0010 0x0006 0x00A0 0x0020 
@DW 0x0006 0x00A0 0x0030 0x0006 0x00A0 0x0040 0x0006 0x00A0 
@DW 0x0050 0x0006 0x00A0 0x0060 0x0006 0x00A0 0x0070 0x0006 
@DW 0x00A0 0x0080 0x0006 0x00A0 0x0090 0x0006 0x00A0 0x00A0 
@DW 0x0006 0x00A0 0x00B0 0x0006 0x00A0 0x00C0 0x0006 0x00A0 
@DW 0x00D0 0x0006 0x00A0 0x00E0 0x0006 0x00A0 0x00F0 0x0006 
@DW 0x00B0 0x0000 0x0006 0x00B0 0x0010 0x0006 0x00B0 0x0020 
@DW 0x0006 0x00B0 0x0030 0x0006 0x00B0 0x0040 0x0006 0x00B0 
@DW 0x0050 0x0006 0x00B0 0x0060 0x0006 0x00B0 0x0070 0x0006 
@DW 0x00B0 0x0080 0x0006 0x00B0 0x0090 0x0006 0x00B0 0x00A0 
@DW 0x0006 0x00B0 0x00B0 0x0006 0x00B0 0x00C0 0x0006 0x00B0 
@DW 0x00D0 0x0006 0x00B0 0x00E0 0x0006 0x00B0 0x00F0 0x0006 
@DW 0x0000 0x0000 0x0000 0x0010 0x0000 0x0001 0x0000 0x0010 
@DW 0x0002 0x0010 0x0010 0x0003 0x001A 0x0015 0x0004 0x002A 
@DW 0x0015 0x0005 0x000F 0x0025 0x0007 0x001F 0x0025 0x0008 
# variable 'mysprites', dim:2304 typename:byte refcount:1
@LABEL _mysprites
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0000 0x0000 0x0000 0x0000 0x0000 0x00FF 
@DW 0xFFFF 0xFF00 0xF69A 0x9A9A 0x9A9A 0x9A9A 0x9A9A 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5151 
@DW 0xFFFF 0x0100 0x5151 0x7272 0x5151 0x5151 0x4751 0x5151 
@DW 0xFF01 0x6F66 0x4949 0x4949 0x499A 0x4949 0x4949 0x4949 
@DW 0xFF01 0x6F6F 0x666F 0x6F6F 0x499A 0x496F 0x6F6F 0x6F6F 
@DW 0xFF01 0x6F6F 0x6F49 0x4949 0x4949 0x4949 0x4949 0x6F6F 
@DW 0xFF01 0x666F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 
@DW 0xFF01 0x6F66 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6666 0x6666 
@DW 0xFF01 0x6F6F 0x6F66 0x6666 0x6F6F 0x6F6F 0x6F6F 0x6F6F 
@DW 0xFF01 0x1414 0x1414 0x1414 0x1414 0x1414 0x1414 0x1414 
@DW 0xFFFF 0x0101 0x0101 0x0101 0x0101 0x0101 0x0101 0x0101 
@DW 0xFFFF 0xFF00 0x5248 0x4848 0x4848 0x4848 0x4848 0x4848 
@DW 0xFFFF 0xFF00 0x5248 0x5252 0x5252 0x5252 0x5252 0x5252 
@DW 0xFFFF 0xFF00 0x5200 0x0000 0x0000 0x0000 0x0000 0x0000 
@DW 0xFFFF 0xFF00 0x5200 0xA4A4 0xA4A4 0xA4A4 0xA4A4 0xA4A4 
@DW 0xFFFF 0xFF00 0x5200 0xA4A4 0xA4A4 0xA4A4 0xA4A4 0xA4A4 
@DW 0xFFFF 0xFF00 0x5200 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFF00 0x0000 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFF00 0x0000 0x00FF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00AC 0x9B9B 0x9B00 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00AC 0xACAC 0x9B00 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00AC 0xACAC 0xAC00 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00AC 0xACAC 0xAC00 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00F6 0xF6F6 0xF600 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x009B 0x9B9B 0x9B00 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0x00AC 0x9B9B 0x4700 0xFFFF 0xFFFF 
@DW 0x0000 0x0000 0x0000 0x009B 0x9B9B 0x9B00 0x0101 0xFFFF 
@DW 0x6F6F 0x666F 0x6F6F 0x48AC 0x9BAC 0x9B48 0x6F66 0x01FF 
@DW 0x6F6F 0x6F66 0x666F 0x489B 0x9BAC 0x9B48 0x6F6F 0x01FF 
@DW 0x6F6F 0x6F6F 0x6F6F 0x489B 0x9BAC 0x9B48 0x6F6F 0x01FF 
@DW 0x6F6F 0x6F6F 0x6F6F 0x4848 0x4848 0x4848 0x6F66 0x01FF 
@DW 0x6F6F 0x6F6F 0x6666 0x6F6F 0x6F6F 0x6F6F 0x6F66 0x01FF 
@DW 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x6F6F 0x01FF 
@DW 0x1414 0x1414 0x1414 0x1414 0x1414 0x1414 0x1414 0x00FF 
@DW 0x0101 0x0101 0x0101 0x0101 0x0101 0x0101 0x0101 0xA4FF 
@DW 0x4848 0x4848 0x529B 0x9B9B 0x9B9B 0x9B52 0x00A4 0xA4FF 
@DW 0x5252 0x5248 0x5252 0x5248 0x4852 0x5252 0x00A4 0xA4FF 
@DW 0x0000 0x0000 0x529B 0x9B9B 0x9B9B 0x9B52 0x00A4 0xA4FF 
@DW 0xA4A4 0xA400 0x5252 0x5248 0x4852 0x5252 0x00A4 0xA4FF 
@DW 0xA4A4 0xA400 0x529B 0x9B9B 0x9B9B 0x9B52 0x00A4 0xA4FF 
@DW 0xFFFF 0xFF00 0x5200 0x0000 0x0000 0x0052 0x00A4 0xA4FF 
@DW 0xFFFF 0xFF00 0x0000 0xA4A4 0xA4A4 0x0000 0x00A4 0xA4FF 
@DW 0xFF08 0x08FF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0x0872 0x7208 0x08FF 0xFFFF 0xFFFF 0x0808 0x08FF 0xFFFF 
@DW 0x0872 0x7C7C 0x7208 0xFFFF 0xFF08 0x7C7C 0x7208 0xFFFF 
@DW 0x0861 0x7272 0x7261 0x08FF 0x0872 0x7C7C 0x7272 0x08FF 
@DW 0xFF08 0x7272 0x7272 0x6108 0x6172 0x7272 0x7261 0x08FF 
@DW 0xFF08 0x6172 0x7272 0x7272 0x7272 0x7272 0x6108 0xFFFF 
@DW 0xFFFF 0x0861 0x7272 0x7272 0x7272 0x7261 0x08FF 0xFFFF 
@DW 0xFFFF 0xFF08 0x0861 0x7261 0x6108 0x0808 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFF08 0x6161 0x08FF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0x0101 0x0108 0x6161 0x0801 0x0101 0xFFFF 0xFFFF 
@DW 0xFF01 0x5D67 0x6767 0x6161 0x6767 0x675D 0x01FF 0xFFFF 
@DW 0xFF01 0xB714 0x1414 0x6161 0x1414 0x1467 0x01FF 0xFFFF 
@DW 0xFF01 0xB714 0x5252 0x6161 0x5252 0x1467 0x01FF 0xFFFF 
@DW 0xFF01 0xB714 0x5252 0x5252 0x5252 0x1467 0x01FF 0xFFFF 
@DW 0xFF01 0x67B7 0xB7B7 0xB7B7 0xB7B7 0xB767 0x01FF 0xFFFF 
@DW 0xFF01 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x01FF 0xFFFF 
@DW 0xFF01 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x01FF 0xFFFF 
@DW 0xFF01 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x01FF 0xFFFF 
@DW 0xFFFF 0x0101 0x0101 0x0101 0x0101 0x0101 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFF01 0x1414 0x1414 0x1414 0x01FF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFF01 0x1414 0x1414 0x1414 0x01FF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0101 0x0101 0x0101 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x6F6F 0x6F6F 0x546F 0x6F6F 0x6F6F 0x6F54 0x6F6F 0x6F6F 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x6F5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 
@DW 0x6F6F 0x6F6F 0x546F 0x6F6F 0x6F6F 0x6F54 0x6F6F 0x6F6F 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D5D 0x5D6F 0x5D5D 0x5D5D 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFF0B 0x1353 0x0B13 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFF01 0x134E 0x4E06 0x6E0E 0x04EE 0xFFFF 
@DW 0xFFFF 0xFFFF 0x094E 0x0E4E 0x4E67 0x7FFE 0x0BAE 0xFFFF 
@DW 0xFFFF 0xFF13 0x0497 0x4E4E 0x0109 0x1353 0x0009 0xEEFF 
@DW 0xFFFF 0x1304 0x4E8F 0x0101 0x0000 0x0000 0x0000 0x00F6 
@DW 0xFFFF 0x00F7 0x0009 0x0056 0x0016 0x000C 0xACEE 0xACF6 
@DW 0xFF13 0xAE26 0xAE00 0x16F7 0x00EF 0x00AE 0x6E24 0xF7FF 
@DW 0xFF01 0xEF09 0xFE00 0x01FE 0xA4FE 0x64F7 0xAE6E 0x64F6 
@DW 0xFF01 0x0B27 0xFE00 0xA4FE 0x13AF 0xAFAF 0xAFEF 0x146E 
@DW 0xFF64 0x000B 0xF703 0xFE13 0x0003 0x0B0B 0x0B0B 0x54F7 
@DW 0xFFFF 0x6300 0x2716 0xF70B 0x1400 0x0000 0x0009 0xF6FF 
@DW 0xFFFF 0xFFA3 0x090C 0x1616 0x260B 0x0053 0x63F6 0xFFFF 
@DW 0xFFFF 0xFFAE 0x038E 0x1651 0x136C 0xA1EC 0xFEFF 0xFFFF 
@DW 0xFFFF 0xFF00 0x560B 0x0FA0 0xECFC 0xFCA3 0xE4F6 0xFFFF 
@DW 0xFFFF 0xFF01 0x6E6C 0x6E11 0xFEFE 0xF3FE 0x91EC 0xFFFF 
@DW 0xFFFF 0xFF0B 0xFEFE 0xF60B 0xF6F6 0xF4FE 0x89EC 0xFFFF 
@DW 0xFFFF 0xFF03 0xFEFE 0x03E9 0xA188 0xABE9 0x93F6 0xFFFF 
@DW 0xFFFF 0xFF24 0xB6F7 0x1363 0x5149 0x5093 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0114 0x1414 0x110B 0x1364 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0013 0x090B 0x6E00 0x6C00 0xACFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0909 0x4911 0x0911 0x0909 0xEEFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
# variable 'frame', dim:1 typename:word refcount:3
@LABEL main_frame
@DW 0x0000 
# variable 'posX', dim:1 typename:word refcount:6
@LABEL main_posX
@DW 0x0080 
# variable 'dirX', dim:1 typename:word refcount:3
@LABEL main_dirX
@DW 0x0001 
# variable 'posY', dim:1 typename:word refcount:6
@LABEL main_posY
@DW 0x0040 
# variable 'dirY', dim:1 typename:word refcount:3
@LABEL main_dirY
@DW 0x0001 
