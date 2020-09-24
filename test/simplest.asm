
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
ld r3 [banana]
dim 0x00000010
decl 
ld r4 [tree]
dim 0x00000004
ld r5 0x00000004
ld r6 0x00000003
ld r7 0x00000002
ld r8 0x00000001
dataarray 
bulkassign 
decl 
ld r9 [sprite]
dim 0x00000020
ld r10 0xffedcafd
ld r11 0xfffffffc
ld r12 0xfffffffb
ld r13 0xfffffffa
ld r14 0xfffffffd
ld r15 0xfffffffc
ld r16 0xfffffffb
ld r17 0xfffffffa
ld r18 0xfffffffd
ld r19 0xff222ffc
ld r20 0xfffffffb
ld r21 0xfffffffa
ld r22 0xfffffffd
ld r23 0xfffffffc
ld r24 0xf00ffffb
ld r25 0xfffffffa
ld r26 0xfffffffd
ld r27 0xfffffffc
ld r28 0xfffffffb
ld r29 0xfffffffa
ld r30 0xfffffffd
ld r31 0xfffffffc
ld r32 0xfffffffb
ld r33 0xfffffffa
ld r34 0xffffff01
ld r35 0xffffff00
ld r36 0xffffffff
ld r37 0xfffffffe
ld r38 0xfffffffd
ld r39 0xfffffffc
ld r40 0xfffffffb
ld r41 0xfffffffa
dataarray 
bulkassign 
decl 
@label test
ret 
ld r42 [height]
ld r43 [width]
ld r44 [posY]
ld r45 [posX]
@label DrawRect
@label beginwhile2
ld r46 [spanY]
ld r47 [posY]
ld r48 [height]
add r47, r48, r47
cmp.l r46, r47, r46
jmpnz r46, endwhile3
lea r46 spanY
ld r47 [spanY]
ld r48 0x00000001
add r47, r48, r47
st [r46], r47, r46
@label beginwhile0
ld r47 [spanX]
ld r48 [posX]
ld r49 [width]
add r48, r49, r48
cmp.l r47, r48, r47
jmpnz r47, endwhile1
lea r47 spanX
ld r48 [spanX]
ld r49 0x00000001
add r48, r49, r48
st [r47], r48, r47
lea r48 VRAM
lea r49 spanX
ld r50 0x00000140
lea r51 spanY
mul r50, r51, r50
add r49, r50, r49
add r48, r49, r48
ld r49 [sprite]
ld r50 0x00000004
ld r51 [spanX]
mod r50, r51, r50
ld r51 0x00000004
ld r52 0x00000008
ld r53 [spanY]
mod r52, r53, r52
mul r51, r52, r51
add r50, r51, r50
add r49, r50, r49
st [r48], r49, r48
jmp beginwhile0
@label endwhile1
lea r49 spanX
ld r50 [posX]
st [r49], r50, r49
jmp beginwhile2
@label endwhile3
lea r50 spanY
ld r51 [posY]
st [r50], r51, r50
ld r51 [spanY]
decl 
ld r52 [spanX]
decl 
@label main
ld r53 [cursorY]
ld r54 0x00000002
cmp.g r53, r54, r53
jmpnz r53, endif4
ld r53 0x00000180
push r53
ld r53 0x00000200
ld r54 0x00000003
add r53, r54, r53
ld r54 [cursorY]
sub r53, r54, r53
push r53
ld r53 0x00000000
push r53
ld r53 0x00000000
push r53
call DrawRect
jmp exitif5
@label endif4
lea r53 cursorY
ld r54 0x00000001
st [r53], r54, r53
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
