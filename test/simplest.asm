
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
jmp.nz r0, endwhile3
ld     r0, [posX]
st     [spanX], r0
 
@label while0
ld     r0, [posX]
ld     r1, [width]
add    r0, r0, r1
ld     r1, [spanX]
ld     r1, r1
cmp.l  r0, r0, r1
jmp.nz r0, endwhile1
ld     r0, 0x00000140
ld     r1, [spanY]
mul    r0, r0, r1
ld     r1, [spanX]
ld     r1, r1
add    r0, r0, r1
ld     r1, 0x000000ff
st     [VRAM+r0], r1
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
@dword 0x00000000
@LABEL :cursorY
@dword 0x00000000
@LABEL :VRAM
@dword 0x80000000
@LABEL :banana
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@dword 0x00000000
@LABEL :tree
@dword 0x00000001
@dword 0x00000002
@dword 0x00000003
@dword 0x00000004
@LABEL :sprite
@dword 0xffffffff
@dword 0xffffffff
@dword 0xffffffff
@dword 0xffffffff
@dword 0xffffffff
@LABEL DrawRect:height
@dword 0x00000000
@LABEL DrawRect:width
@dword 0x00000000
@LABEL DrawRect:posY
@dword 0x00000000
@LABEL DrawRect:posX
@dword 0x00000000
@LABEL DrawRect:spanX
@dword 0x00000000
@LABEL DrawRect:spanY
@dword 0x00000000
