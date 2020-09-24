
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
R: ........EN_PostfixArrayExpression    (8) 
R: .........EN_Identifier                (9) sprite
R: .........EN_Add                       (9) 
R: ..........EN_Mod                       (10) 
R: ...........EN_Constant                  (11) 0x00000004
R: ...........EN_Identifier                (11) spanX
R: ..........EN_Mul                       (10) 
R: ...........EN_Constant                  (11) 0x00000004
R: ...........EN_Mod                       (11) 
R: ............EN_Constant                  (12) 0x00000008
R: ............EN_Identifier                (12) spanY
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

@label test
ret 
ld r0 [height]
ld r1 [width]
ld r2 [posY]
ld r3 [posX]
@label DrawRect
@label beginwhile2
ld r4 [spanY]
ld r5 [posY]
ld r6 [height]
add r5, r6, r5
cmp.l r4, r5, r4
jmpnz r4, endwhile3
lea r4 spanY
ld r5 [spanY]
ld r6 0x00000001
add r5, r6, r5
st [r4], r5, r4
@label beginwhile0
ld r4 [spanX]
ld r5 [posX]
ld r6 [width]
add r5, r6, r5
cmp.l r4, r5, r4
jmpnz r4, endwhile1
lea r4 spanX
ld r5 [spanX]
ld r6 0x00000001
add r5, r6, r5
st [r4], r5, r4
lea r4 VRAM
lea r5 spanX
ld r6 0x00000140
lea r7 spanY
mul r6, r7, r6
add r5, r6, r5
add r4, r5, r4
ld r5 [sprite]
ld r6 0x00000004
ld r7 [spanX]
mod r6, r7, r6
ld r7 0x00000004
ld r8 0x00000008
ld r9 [spanY]
mod r8, r9, r8
mul r7, r8, r7
add r6, r7, r6
add r5, r6, r5
st [r4], r5, r4
jmp beginwhile0
@label endwhile1
lea r4 spanX
ld r5 [posX]
st [r4], r5, r4
jmp beginwhile2
@label endwhile3
lea r4 spanY
ld r5 [posY]
st [r4], r5, r4
@label main
ld r4 [cursorY]
ld r5 0x00000002
cmp.g r4, r5, r4
jmpnz r4, endif4
ld r4 0x00000180
push r4
ld r4 0x00000200
ld r5 0x00000003
add r4, r5, r4
ld r5 [cursorY]
sub r4, r5, r4
push r4
ld r4 0x00000000
push r4
ld r4 0x00000000
push r4
call DrawRect
jmp exitif5
@label endif4
lea r4 cursorY
ld r5 0x00000001
st [r4], r5, r4
@label exitif5

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
