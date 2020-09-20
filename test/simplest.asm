
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
cmp.l  r0, r0, r1
jmp.nz endwhile3
ld     r1, [posX]
st     [spanX], r1
 
@label while0
ld     r1, [posX]
ld     r2, [width]
add    r1, r1, r2
ld     r2, [spanX]
ld     r2, r2
cmp.l  r1, r1, r2
jmp.nz endwhile1
ld     r2, 0x00000140
ld     r3, [spanY]
mul    r2, r2, r3
ld     r3, [spanX]
ld     r3, r3
add    r2, r2, r3
ld     r2, r2
st     [address], r2
ld     r2, 0x000000ff
st     [VRAM+address], r2
ld     r2, [spanX]
ld     r3, 0x00000001
add    r2, r2, r3
ld     r2, r2
st     [spanX], r2
jmp    while0
 
@label endwhile1
ld     r2, [spanY]
ld     r3, 0x00000001
add    r2, r2, r3
ld     r2, r2
st     [spanY], r2
jmp    while2
 
@label endwhile3
ret    
@label main
ld     r2, 0x80000000
st     [VRAM], r2
ld     r2, 0x00000200
push   r2
ld     r2, 0x00000180
push   r2
ld     r2, 0x00000080
push   r2
ld     r2, 0x00000060
push   r2
call   DrawRect
ld     r2, 0x00000002
ld     r3, [VRAM+0x00000009]
mul    r2, r2, r3
ld     r2, r2
ld     r3, 0x00000001
add    r2, r2, r3
ld     r3, 0x00000001
push   r3
ld     r3, 0x00000002
push   r3
ld     r3, 0x00000003
push   r3
ld     r2, r2
push   r2
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
