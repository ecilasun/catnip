
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
	st     r1, [r1]
@label while2
 
	lea    r2, posY
	ld     r2, [r2]
	lea    r3, height
	ld     r3, [r3]
	add    r2, r2, r3
	lea    r3, spanY
	ld     r3, [r3]
	cmp.l  r2, r3, r2
	jmp.nz r2, endwhile3
	lea    r2, posX
	ld     r2, [r2]
	lea    r3, spanX
	st     r3, [r3]
@label while0
 
	lea    r4, posX
	ld     r4, [r4]
	lea    r5, width
	ld     r5, [r5]
	add    r4, r4, r5
	lea    r5, spanX
	ld     r5, [r5]
	cmp.l  r4, r5, r4
	jmp.nz r4, endwhile1
	ld     r4, 0x00000140
	lea    r5, spanY
	ld     r5, [r5]
	mul    r4, r4, r5
	lea    r5, spanX
	ld     r5, [r5]
	add    r4, r4, r5
	ld     r5, 0x000000ff
	lea    r5, VRAM+r5
	st     r5, [r5]
	lea    r6, spanX
	ld     r6, [r6]
	ld     r7, 0x00000001
	add    r6, r6, r7
	lea    r7, spanX
	st     r7, [r7]
	jmp    while0
@label endwhile1
 
	lea    r8, spanY
	ld     r8, [r8]
	ld     r9, 0x00000001
	add    r8, r8, r9
	lea    r9, spanY
	st     r9, [r9]
	jmp    while2
@label endwhile3
 
@label main
	st     r0, 0x00000001
	push   r0
	st     r0, 0x00000002
	push   r0
	st     r0, 0x00000004
	push   r0
	st     r0, 0x00000008
	push   r0
	call   DrawRect
 
	lea    r0, DrawRect:spanX
	ld     r0, [r0]
	ld     r1, 0x00000005
	cmp.g  r0, r1, r0
	jmp.nz r0, endif4
	st     r0, 0x00000200
	push   r0
	st     r0, 0x00000180
	push   r0
	st     r0, 0x00000080
	push   r0
	st     r0, 0x00000060
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
