
-------------Scope Depth--------------

R: EN_FuncDecl                  (0) 
R: .EN_Label                     (1) test
R: .EN_BeginCodeBlock            (1) 
R: ..EN_Return                    (2) 
R: EN_FuncDecl                  (0) 
R: .EN_StackPop                  (1) 
R: ..EN_Identifier                (2) height
R: .EN_StackPop                  (1) 
R: ..EN_Identifier                (2) width
R: .EN_StackPop                  (1) 
R: ..EN_Identifier                (2) posY
R: .EN_StackPop                  (1) 
R: ..EN_Identifier                (2) posX
R: .EN_Label                     (1) DrawRect
R: .EN_BeginCodeBlock            (1) 
R: ..EN_While                     (2) 
R: ...EN_Label                     (3) beginwhile2
R: ...EN_LessThan                  (3) 
R: ....EN_Identifier                (4) spanY
R: ....EN_Add                       (4) 
R: .....EN_Identifier                (5) posY
R: .....EN_Identifier                (5) height
R: ...EN_JumpNZ                    (3) endwhile3
R: ...EN_BeginCodeBlock            (3) 
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
L: ......EN_Identifier                (6) spanY
R: ......EN_Add                       (6) 
R: .......EN_Identifier                (7) spanY
R: .......EN_Constant                  (7) 0x00000001
R: ....EN_While                     (4) 
R: .....EN_Label                     (5) beginwhile0
R: .....EN_LessThan                  (5) 
R: ......EN_Identifier                (6) spanX
R: ......EN_Add                       (6) 
R: .......EN_Identifier                (7) posX
R: .......EN_Identifier                (7) width
R: .....EN_JumpNZ                    (5) endwhile1
R: .....EN_BeginCodeBlock            (5) 
R: ......EN_Statement                 (6) 
R: .......EN_AssignmentExpression      (7) 
L: ........EN_Identifier                (8) spanX
R: ........EN_Add                       (8) 
R: .........EN_Identifier                (9) spanX
R: .........EN_Constant                  (9) 0x00000001
R: ......EN_Statement                 (6) 
R: .......EN_AssignmentExpression      (7) 
L: ........EN_PostfixArrayExpression    (8) 
L: .........EN_Identifier                (9) VRAM
L: .........EN_Add                       (9) 
L: ..........EN_Identifier                (10) spanX
L: ..........EN_Mul                       (10) 
L: ...........EN_Constant                  (11) 0x00000140
L: ...........EN_Identifier                (11) spanY
R: ........EN_Constant                  (8) 0x0000000c
R: .....EN_Jump                      (5) beginwhile0
R: .....EN_Label                     (5) endwhile1
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
L: ......EN_Identifier                (6) spanX
R: ......EN_Identifier                (6) posX
R: ...EN_Jump                      (3) beginwhile2
R: ...EN_Label                     (3) endwhile3
R: ..EN_Statement                 (2) 
R: ...EN_AssignmentExpression      (3) 
L: ....EN_Identifier                (4) spanY
R: ....EN_Identifier                (4) posY
R: EN_FuncDecl                  (0) 
R: .EN_Label                     (1) main
R: .EN_BeginCodeBlock            (1) 
R: ..EN_If                        (2) 
R: ...EN_GreaterThan               (3) 
R: ....EN_Identifier                (4) cursorY
R: ....EN_Constant                  (4) 0x00000002
R: ...EN_JumpNZ                    (3) endif4
R: ...EN_BeginCodeBlock            (3) 
R: ....EN_Call                      (4) DrawRect
R: .....EN_StackPush                 (5) 
R: ......EN_Constant                  (6) 0x00000180
R: .....EN_StackPush                 (5) 
R: ......EN_Sub                       (6) 
R: .......EN_Add                       (7) 
R: ........EN_Constant                  (8) 0x00000200
R: ........EN_Constant                  (8) 0x00000003
R: .......EN_Identifier                (7) cursorY
R: .....EN_StackPush                 (5) 
R: ......EN_Constant                  (6) 0x00000000
R: .....EN_StackPush                 (5) 
R: ......EN_Constant                  (6) 0x00000000
R: ...EN_Jump                      (3) exitif5
R: ...EN_Label                     (3) endif4
R: ...EN_BeginCodeBlock            (3) 
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
L: ......EN_Identifier                (6) cursorY
R: ......EN_Constant                  (6) 0x00000001
R: ...EN_Label                     (3) exitif5

---------Register Assignment----------


-----------Generated Code-------------

@label exitif5
ld r0 0x00000001
lea r4294967295 cursorY
st [r4294967295], r4294967294
@label endif4
jmp exitif5
ld r4294967295 0x00000000
push r4294967295
ld r4294967295 0x00000000
push r4294967295
ld r0 [cursorY]
ld r0 0x00000003
ld r4294967295 0x00000200
add r4294967295, r0, r4294967295
sub r4294967295, r0, r4294967295
push r4294967295
ld r4294967295 0x00000180
push r4294967295
call DrawRect
jmpnz r4294967295, endif4
ld r0 0x00000002
ld r4294967295 [cursorY]
cmp.g r4294967295, r0, r4294967295
@label main
ld r1 [posY]
lea r0 spanY
st [r0], r4294967295
@label endwhile3
jmp beginwhile2
ld r2 [posX]
lea r1 spanX
st [r1], r0
@label endwhile1
jmp beginwhile0
ld r3 0x0000000c
lea r5 spanY
ld r4 0x00000140
mul r4, r5, r4
lea r3 spanX
add r3, r4, r3
lea r2 VRAM
add r2, r3, r2
st [r2], r1
ld r5 0x00000001
ld r4 [spanX]
add r4, r5, r4
lea r3 spanX
st [r3], r2
jmpnz r3, endwhile1
ld r5 [width]
ld r4 [posX]
add r4, r5, r4
ld r3 [spanX]
cmp.l r3, r4, r3
@label beginwhile0
ld r6 0x00000001
ld r5 [spanY]
add r5, r6, r5
lea r4 spanY
st [r4], r3
jmpnz r4, endwhile3
ld r6 [height]
ld r5 [posY]
add r5, r6, r5
ld r4 [spanY]
cmp.l r4, r5, r4
@label beginwhile2
@label DrawRect
ld r3 [posX]
ld r2 [posY]
ld r1 [width]
ld r0 [height]
ret 
@label test

-------------Symbol Table-------------

// function 'test', hash: BC2C0BE9, refcount: 0
// function 'DrawRect', hash: 032D1965, refcount: 1
// function 'main', hash: BC76E6BA, refcount: 0
@label cursorX
@length 1
@dw 0x00000000
@label cursorY
@length 1
@dw 0x00000000
@label VRAM
@length 1
@dw 0x80000000
@label banana
@length 16
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
@length 4
@dw 0x00000004
@dw 0x00000003
@dw 0x00000002
@dw 0x00000001
@label sprite
@length 32
@dw 0xffedcafd
@dw 0xfffffffc
@dw 0xfffffffb
@dw 0xfffffffa
@dw 0xfffffffd
@dw 0xfffffffc
@dw 0xfffffffb
@dw 0xfffffffa
@dw 0xfffffffd
@dw 0xff222ffc
@dw 0xfffffffb
@dw 0xfffffffa
@dw 0xfffffffd
@dw 0xfffffffc
@dw 0xf00ffffb
@dw 0xfffffffa
@dw 0xfffffffd
@dw 0xfffffffc
@dw 0xfffffffb
@dw 0xfffffffa
@dw 0xfffffffd
@dw 0xfffffffc
@dw 0xfffffffb
@dw 0xfffffffa
@dw 0xffffff01
@dw 0xffffff00
@dw 0xffffffff
@dw 0xfffffffe
@dw 0xfffffffd
@dw 0xfffffffc
@dw 0xfffffffb
@dw 0xfffffffa
@label spanX
@length 1
@dw 0x00000000
@label spanY
@length 1
@dw 0x00000000
