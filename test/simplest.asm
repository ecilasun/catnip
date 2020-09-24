
@label test
ret 

@label DrawRect
pop height
pop width
pop posY
pop posX
ld r0 [posY]
lea r1 spanY
st [r1], r0

@label beginwhile2
ld r0 [spanY]
ld r1 [posY]
ld r2 [height]
add r1, r1, r2
cmp.l r0, r0, r1
jmpnz r0, endwhile3
ld r0 [posX]
lea r1 spanX
st [r1], r0

@label beginwhile0
ld r0 [spanX]
ld r1 [posX]
ld r2 [width]
add r1, r1, r2
cmp.l r0, r0, r1
jmpnz r0, endwhile1
ld r0 0x00000004
ld r1 [spanX]
mod r0, r0, r1
ld r1 0x00000004
ld r2 0x00000008
ld r3 [spanY]
mod r2, r2, r3
mul r1, r1, r2
add r0, r0, r1
lea r1 sprite
add r0, r1, r0
ld [r0], r0
lea r1 spanX
ld r2 0x00000140
lea r3 spanY
mul r2, r2, r3
add r1, r1, r2
lea r2 VRAM
add r1, r2, r1
st [r1], r0
ld r0 [spanX]
ld r1 0x00000001
add r0, r0, r1
lea r1 spanX
st [r1], r0
jmp beginwhile0

@label endwhile1
ld r0 [spanY]
ld r1 0x00000001
add r0, r0, r1
lea r1 spanY
st [r1], r0
jmp beginwhile2

@label endwhile3

@label main
ld r0 0x00000000
push r0
ld r0 0x00000000
push r0
ld r0 0x00000200
ld r1 0x00000003
add r0, r0, r1
ld r1 [cursorY]
sub r0, r0, r1
push r0
ld r0 0x00000180
push r0
call DrawRect

//-------------Symbol Table-------------

// function 'test', hash: BC2C0BE9, refcount: 0
// function 'DrawRect', hash: 032D1965, refcount: 1
// function 'main', hash: BC76E6BA, refcount: 0
@label cursorX
// array length 1
@dw 0x00000000
@label cursorY
// array length 1
@dw 0x00000000
@label VRAM
// array length 1
@dw 0x80000000
@label banana
// array length 16
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@dw 0x00000000
@label tree
// array length 4
@dw 0x00000001
@dw 0x00000002
@dw 0x00000003
@dw 0x00000004
@label sprite
// array length 32
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xfffffffc
@dw 0xfffffffd
@dw 0xfffffffe
@dw 0xffffffff
@dw 0xffffff00
@dw 0xffffff01
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xfffffffc
@dw 0xfffffffd
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xfffffffc
@dw 0xfffffffd
@dw 0xfffffffa
@dw 0xf00ffffb
@dw 0xfffffffc
@dw 0xfffffffd
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xff222ffc
@dw 0xfffffffd
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xfffffffc
@dw 0xfffffffd
@dw 0xfffffffa
@dw 0xfffffffb
@dw 0xfffffffc
@dw 0xffedcafd
@label spanX
// array length 1
@dw 0x00000000
@label spanY
// array length 1
@dw 0x00000000
