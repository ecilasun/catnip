
-------------Scope Depth--------------

R: EN_Decl                      (0) 
R: .EN_Identifier                (1) cursorX
R: EN_Decl                      (0) 
R: .EN_Identifier                (1) cursorY
R: EN_Decl                      (0) 
R: .EN_DeclInitJunction          (1) 
R: ..EN_Identifier                (2) VRAM
R: ..EN_Constant                  (2) 0x80000000
R: EN_Decl                      (0) 
R: .EN_DeclArray                 (1) 
R: ..EN_Identifier                (2) banana
R: ..EN_Constant                  (2) 0x00000010
R: EN_Decl                      (0) 
R: .EN_DeclInitJunction          (1) 
R: ..EN_Identifier                (2) tree
R: ..EN_Constant                  (2) 0x00000004
R: ..EN_ArrayWithDataJunction     (2) 
R: ...EN_Constant                  (3) 0x00000004
R: ...EN_Constant                  (3) 0x00000003
R: ...EN_Constant                  (3) 0x00000002
R: ...EN_Constant                  (3) 0x00000001
R: EN_Decl                      (0) 
R: .EN_DeclInitJunction          (1) 
R: ..EN_Identifier                (2) sprite
R: ..EN_Constant                  (2) 0x00000020
R: ..EN_ArrayWithDataJunction     (2) 
R: ...EN_Constant                  (3) 0xffedcafd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xff222ffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xf00ffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
R: ...EN_Constant                  (3) 0xffffff01
R: ...EN_Constant                  (3) 0xffffff00
R: ...EN_Constant                  (3) 0xffffffff
R: ...EN_Constant                  (3) 0xfffffffe
R: ...EN_Constant                  (3) 0xfffffffd
R: ...EN_Constant                  (3) 0xfffffffc
R: ...EN_Constant                  (3) 0xfffffffb
R: ...EN_Constant                  (3) 0xfffffffa
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
R: ..EN_Decl                      (2) 
R: ...EN_Identifier                (3) spanY
R: ..EN_Decl                      (2) 
R: ...EN_Identifier                (3) spanX
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

ld r0 [cursorX]
decl 
ld r1 [cursorY]
decl 
ld r2 [VRAM]
ld r3 0x80000000
st [r2], r3, r2
decl 
ld r2 [banana]
dim 0x00000010
decl 
ld r3 [tree]
dim 0x00000004
ld r4 0x00000004
ld r5 0x00000003
ld r6 0x00000002
ld r7 0x00000001
dataarray 
bulkassign 
decl 
ld r8 [sprite]
dim 0x00000020
ld r9 0xffedcafd
ld r10 0xfffffffc
ld r11 0xfffffffb
ld r12 0xfffffffa
ld r13 0xfffffffd
ld r14 0xfffffffc
ld r15 0xfffffffb
ld r16 0xfffffffa
ld r17 0xfffffffd
ld r18 0xff222ffc
ld r19 0xfffffffb
ld r20 0xfffffffa
ld r21 0xfffffffd
ld r22 0xfffffffc
ld r23 0xf00ffffb
ld r24 0xfffffffa
ld r25 0xfffffffd
ld r26 0xfffffffc
ld r27 0xfffffffb
ld r28 0xfffffffa
ld r29 0xfffffffd
ld r30 0xfffffffc
ld r31 0xfffffffb
ld r32 0xfffffffa
ld r33 0xffffff01
ld r34 0xffffff00
ld r35 0xffffffff
ld r36 0xfffffffe
ld r37 0xfffffffd
ld r38 0xfffffffc
ld r39 0xfffffffb
ld r40 0xfffffffa
dataarray 
bulkassign 
decl 
@label test
ret 
ld r41 [height]
ld r42 [width]
ld r43 [posY]
ld r44 [posX]
@label DrawRect
@label beginwhile2
ld r45 [spanY]
ld r46 [posY]
ld r47 [height]
add r46, r47, r46
cmp.l r45, r46, r45
jmpnz r45, endwhile3
lea r45 spanY
ld r46 [spanY]
ld r47 0x00000001
add r46, r47, r46
st [r45], r46, r45
@label beginwhile0
ld r45 [spanX]
ld r46 [posX]
ld r47 [width]
add r46, r47, r46
cmp.l r45, r46, r45
jmpnz r45, endwhile1
lea r45 spanX
ld r46 [spanX]
ld r47 0x00000001
add r46, r47, r46
st [r45], r46, r45
lea r45 VRAM
lea r46 spanX
ld r47 0x00000140
lea r48 spanY
mul r47, r48, r47
add r46, r47, r46
add r45, r46, r45
ld r46 [sprite]
ld r47 0x00000004
ld r48 [spanX]
mod r47, r48, r47
ld r48 0x00000004
ld r49 0x00000008
ld r50 [spanY]
mod r49, r50, r49
mul r48, r49, r48
add r47, r48, r47
add r46, r47, r46
st [r45], r46, r45
jmp beginwhile0
@label endwhile1
lea r45 spanX
ld r46 [posX]
st [r45], r46, r45
jmp beginwhile2
@label endwhile3
lea r45 spanY
ld r46 [posY]
st [r45], r46, r45
ld r45 [spanY]
decl 
ld r46 [spanX]
decl 
@label main
ld r47 [cursorY]
ld r48 0x00000002
cmp.g r47, r48, r47
jmpnz r47, endif4
ld r47 0x00000180
push r47
ld r47 0x00000200
ld r48 0x00000003
add r47, r48, r47
ld r48 [cursorY]
sub r47, r48, r47
push r47
ld r47 0x00000000
push r47
ld r47 0x00000000
push r47
call DrawRect
jmp exitif5
@label endif4
lea r47 cursorY
ld r48 0x00000001
st [r47], r48, r47
@label exitif5

-------------Symbol Table-------------

Function 'test', hash BC2C0BE9
Function 'DrawRect', hash 032D1965
Function 'main', hash BC76E6BA
Variable 'cursorX', hash 2AB08A05
Variable 'cursorY', hash 2AB08A04
Variable 'VRAM', hash 6FF3DA43
Variable 'banana', hash EA716BD2
Variable 'tree', hash C602CD31
Variable 'sprite', hash 43466C92
Variable 'spanX', hash FD3E6BD3
Variable 'spanY', hash FD3E6BD2
