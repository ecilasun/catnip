
---------------------------
     Compiled by GrimR     
GrimR (c)2020 Engin Cilasun
---------------------------

@label DrawRect
	pop    height
	pop    width
	pop    posY
	pop    posX
	lea    r0, posY
	ld     r0, [r0]
	lea    r1, spanY
	st     [r1], r0
@label while2
 
	lea    r1, posY
	ld     r1, [r1]
	lea    r2, height
	ld     r2, [r2]
	add    r1, r1, r2
	lea    r2, spanY
	ld     r2, [r2]
	cmp.l  r1, r2, r1
	jmp.nz r1, endwhile3
	lea    r1, posX
	ld     r1, [r1]
	lea    r2, spanX
	st     [r2], r1
@label while0
 
	lea    r2, posX
	ld     r2, [r2]
	lea    r3, width
	ld     r3, [r3]
	add    r2, r2, r3
	lea    r3, spanX
	ld     r3, [r3]
	cmp.l  r2, r3, r2
	jmp.nz r2, endwhile1
	ld     r2, 0x00000140
	lea    r3, spanY
	ld     r3, [r3]
	mul    r2, r2, r3
	lea    r3, spanX
	ld     r3, [r3]
	add    r2, r2, r3
	ld     r3, 0xff00ff00
	lea    r4, VRAM+r4
	st     [r3], r3
	lea    r3, spanX
	ld     r3, [r3]
	ld     r4, 0x00000001
	add    r3, r3, r4
	lea    r4, spanX
	st     [r4], r3
	jmp    while0
@label endwhile1
 
	lea    r4, spanY
	ld     r4, [r4]
	ld     r5, 0x00000001
	add    r4, r4, r5
	lea    r5, spanY
	st     [r5], r4
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
 
	lea    r0, DrawRect:spanX
	ld     r0, [r0]
	ld     r1, 0x00000005
	cmp.g  r0, r1, r0
	jmp.nz r0, endif4
	lea    r0, cursorY
	ld     r0, [r0]
	ld     r1, 0x00000005
	cmp.g  r0, r1, r0
	ld     r1, 0x00000003
	ld     r2, 0x00000001
	sel    r0, r0, r2, r1
	lea    r1, cursorX
	st     [r1], r0
	ld     r1, 0x00000200
	push   r1
	ld     r1, 0x00000180
	push   r1
	ld     r1, 0x00000080
	push   r1
	ld     r1, 0x00000060
	push   r1
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
