
---------------------------
     Compiled by GrimR     
GrimR (c)2020 Engin Cilasun
---------------------------

@label DrawRect
	pop    r0, height
	pop    r1, width
	pop    r2, posY
	pop    r3, posX
	ld     r4, [posY]
	st     [spanY], r4
 
@label while2
	ld     r4, [posY]
	ld     r5, [height]
	add    r4, r4, r5
	ld     r5, [spanY]
	cmp.l  r4, r5, r4
	jmp.nz r4, endwhile3
	ld     r4, [posX]
	st     [spanX], r4
 
@label while0
	ld     r4, [posX]
	ld     r5, [width]
	add    r4, r4, r5
	ld     r5, [spanX]
	cmp.l  r4, r5, r4
	jmp.nz r4, endwhile1
	ld     r4, 0x00000140
	ld     r5, [spanY]
	mul    r4, r4, r5
	ld     r5, [spanX]
	add    r4, r4, r5
	ld     r5, 0x000000ff
	st     [VRAM+r4], r5
	ld     r4, [spanX]
	ld     r5, 0x00000001
	add    r4, r4, r5
	st     [spanX], r4
	jmp    while0
 
@label endwhile1
	ld     r4, [spanY]
	ld     r5, 0x00000001
	add    r4, r4, r5
	st     [spanY], r4
	jmp    while2
 
@label endwhile3
@label main
	ld     r0, 0x00000001
	push   r0
	ld     r0, 0x00000002
	push   r0
	ld     r0, 0x00000004
	push   r0
	ld     r0, 0x00000008
	push   r0
	call   DrawRect
 
	ld     r0, [DrawRect:spanX]
	ld     r1, 0x00000005
	cmp.g  r0, r1, r0
	jmp.nz r0, endif4
	ld     r0, 0x00000200
	push   r0
	ld     r0, 0x00000180
	push   r0
	ld     r0, 0x00000080
	push   r0
	ld     r0, 0x00000060
	push   r0
	call   DrawRect
 
@label endif4
ret    


---------------------------
        Symbols            
---------------------------

@label :cursorX
	@dword 0x00000000
@label :cursorY
	@dword 0x00000000
@label :VRAM
	@dword 0x80000000
@label :banana
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
@label :tree
	@dword 0x00000001
	@dword 0x00000002
	@dword 0x00000003
	@dword 0x00000004
@label :sprite
	@dword 0xffffffff
	@dword 0xffffffff
	@dword 0xffffffff
	@dword 0xffffffff
	@dword 0xffffffff
@label DrawRect:height
	@dword 0x00000000
@label DrawRect:width
	@dword 0x00000000
@label DrawRect:posY
	@dword 0x00000000
@label DrawRect:posX
	@dword 0x00000000
@label DrawRect:spanX
	@dword 0x00000000
@label DrawRect:spanY
	@dword 0x00000000
