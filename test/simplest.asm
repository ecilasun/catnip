
---------------------------
     Compiled by GrimR     
GrimR (c)2020 Engin Cilasun
---------------------------

@label DrawRect
pop    height
pop    width
pop    posY
pop    posX
ld     r0, [posY]
st     [spanY], r0
 
@label while2
ld     r0, [posY]
ld     r1, [height]
add    r0, r0, r1
ld     r1, [spanY]
ld     r1, r1
cmp.l  r0, r1
jmp.nz endwhile3
ld     r0, [posX]
st     [spanX], r0
 
@label while0
ld     r0, [posX]
ld     r1, [width]
add    r0, r0, r1
ld     r1, [spanX]
ld     r1, r1
cmp.l  r0, r1
jmp.nz endwhile1
ld     r0, 0x00000140
ld     r1, [spanY]
mul    r0, r0, r1
ld     r1, [spanX]
ld     r1, r1
add    r0, r0, r1
ld     r0, r0
st     [address], r0
ld     r0, 0x000000ff
st     [VRAM+[address]], r0
ld     r0, [spanX]
ld     r1, 0x00000001
add    r0, r0, r1
ld     r0, r0
st     [spanX], r0
jmp    while0
 
@label endwhile1
ld     r0, [spanY]
ld     r1, 0x00000001
add    r0, r0, r1
ld     r0, r0
st     [spanY], r0
jmp    while2
 
@label endwhile3
ret    
@label main
ld     r0, 0x80000000
st     [VRAM], r0
ld     r0, 0x00000200
push   r0
ld     r0, 0x00000180
push   r0
ld     r0, 0x00000080
push   r0
ld     r0, 0x00000060
push   r0
call   DrawRect
ld     r0, 0x00000001
push   r0
ld     r0, 0x00000002
push   r0
ld     r0, 0x00000003
push   r0
ld     r0, 0x00000004
push   r0
call   DrawRect
ret    

---------------------------
        Symbols            
---------------------------

@LABEL :cursorX
@DW 0x0000 0x0000
@LABEL :cursorY
@DW 0x0000 0x0000
@LABEL :VRAM
@DW 0x0000 0x0000
@LABEL :banana
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@LABEL :tree
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@DW 0x0000 0x0000
@LABEL DrawRect:height
@DW 0x0000 0x0000
@LABEL DrawRect:width
@DW 0x0000 0x0000
@LABEL DrawRect:posY
@DW 0x0000 0x0000
@LABEL DrawRect:posX
@DW 0x0000 0x0000
@LABEL DrawRect:spanX
@DW 0x0000 0x0000
@LABEL DrawRect:spanY
@DW 0x0000 0x0000
@LABEL DrawRect:address
@DW 0x0000 0x0000
