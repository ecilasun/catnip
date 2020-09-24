
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
R: ..EN_Statement                 (2) 
R: ...EN_AssignmentExpression      (3) 
R: ....EN_Identifier                (4) posY
L: ....EN_Identifier                (4) spanY
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
R: ......EN_Identifier                (6) posX
L: ......EN_Identifier                (6) spanX
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
R: ........EN_Constant                  (8) 0x0000000c
L: ........EN_PostfixArrayExpression    (8) 
L: .........EN_Identifier                (9) VRAM
L: .........EN_Add                       (9) 
L: ..........EN_Identifier                (10) spanX
L: ..........EN_Mul                       (10) 
L: ...........EN_Constant                  (11) 0x00000140
L: ...........EN_Identifier                (11) spanY
R: ......EN_Statement                 (6) 
R: .......EN_AssignmentExpression      (7) 
R: ........EN_Add                       (8) 
R: .........EN_Identifier                (9) spanX
R: .........EN_Constant                  (9) 0x00000001
L: ........EN_Identifier                (8) spanX
R: .....EN_Jump                      (5) beginwhile0
R: .....EN_Label                     (5) endwhile1
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
R: ......EN_Add                       (6) 
R: .......EN_Identifier                (7) spanY
R: .......EN_Constant                  (7) 0x00000001
L: ......EN_Identifier                (6) spanY
R: ...EN_Jump                      (3) beginwhile2
R: ...EN_Label                     (3) endwhile3
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
R: ......EN_Constant                  (6) 0x00000000
R: .....EN_StackPush                 (5) 
R: ......EN_Constant                  (6) 0x00000000
R: .....EN_StackPush                 (5) 
R: ......EN_Sub                       (6) 
R: .......EN_Add                       (7) 
R: ........EN_Constant                  (8) 0x00000200
R: ........EN_Constant                  (8) 0x00000003
R: .......EN_Identifier                (7) cursorY
R: .....EN_StackPush                 (5) 
R: ......EN_Constant                  (6) 0x00000180
R: ...EN_Jump                      (3) exitif5
R: ...EN_Label                     (3) endif4
R: ...EN_BeginCodeBlock            (3) 
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
R: ......EN_Constant                  (6) 0x00000001
L: ......EN_Identifier                (6) cursorY
R: ...EN_Label                     (3) exitif5

--Assign Registers and generate code--

R: EN_Label                      (test) @label test
R: EN_Return                     () ret 
R: EN_BeginCodeBlock             ()  
R: EN_FuncDecl                   ()  
R: EN_Identifier                 (height) ld r0 [height]
R: EN_StackPop                   ()  
R: EN_Identifier                 (width) ld r1 [width]
R: EN_StackPop                   ()  
R: EN_Identifier                 (posY) ld r2 [posY]
R: EN_StackPop                   ()  
R: EN_Identifier                 (posX) ld r3 [posX]
R: EN_StackPop                   ()  
R: EN_Label                      (DrawRect) @label DrawRect
R: EN_Identifier                 (posY) ld r4 [posY]
L: EN_Identifier                 (spanY) lea r5 spanY
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_Label                      (beginwhile2) @label beginwhile2
R: EN_Identifier                 (spanY) ld r4 [spanY]
R: EN_Identifier                 (posY) ld r5 [posY]
R: EN_Identifier                 (height) ld r6 [height]
R: EN_Add                        () add r5, r5, r6
R: EN_LessThan                   () cmp.l r4, r4, r5
R: EN_JumpNZ                     (endwhile3) jmpnz r4, endwhile3
R: EN_Identifier                 (posX) ld r4 [posX]
L: EN_Identifier                 (spanX) lea r5 spanX
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_Label                      (beginwhile0) @label beginwhile0
R: EN_Identifier                 (spanX) ld r4 [spanX]
R: EN_Identifier                 (posX) ld r5 [posX]
R: EN_Identifier                 (width) ld r6 [width]
R: EN_Add                        () add r5, r5, r6
R: EN_LessThan                   () cmp.l r4, r4, r5
R: EN_JumpNZ                     (endwhile1) jmpnz r4, endwhile1
R: EN_Constant                   (0x0000000c) ld r4 0x0000000c
L: EN_Identifier                 (VRAM) lea r5 VRAM
L: EN_Identifier                 (spanX) lea r6 spanX
L: EN_Constant                   (0x00000140) ld r7 0x00000140
L: EN_Identifier                 (spanY) lea r8 spanY
L: EN_Mul                        () mul r7, r7, r8
L: EN_Add                        () add r6, r6, r7
L: EN_PostfixArrayExpression     () add r5, r5, r6
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_Identifier                 (spanX) ld r4 [spanX]
R: EN_Constant                   (0x00000001) ld r5 0x00000001
R: EN_Add                        () add r4, r4, r5
L: EN_Identifier                 (spanX) lea r5 spanX
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_BeginCodeBlock             ()  
R: EN_Jump                       (beginwhile0) jmp beginwhile0
R: EN_Label                      (endwhile1) @label endwhile1
R: EN_While                      ()  
R: EN_Identifier                 (spanY) ld r4 [spanY]
R: EN_Constant                   (0x00000001) ld r5 0x00000001
R: EN_Add                        () add r4, r4, r5
L: EN_Identifier                 (spanY) lea r5 spanY
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_BeginCodeBlock             ()  
R: EN_Jump                       (beginwhile2) jmp beginwhile2
R: EN_Label                      (endwhile3) @label endwhile3
R: EN_While                      ()  
R: EN_BeginCodeBlock             ()  
R: EN_FuncDecl                   ()  
R: EN_Label                      (main) @label main
R: EN_Identifier                 (cursorY) ld r4 [cursorY]
R: EN_Constant                   (0x00000002) ld r5 0x00000002
R: EN_GreaterThan                () cmp.g r4, r4, r5
R: EN_JumpNZ                     (endif4) jmpnz r4, endif4
R: EN_Constant                   (0x00000000) ld r4 0x00000000
R: EN_StackPush                  () push r4
R: EN_Constant                   (0x00000000) ld r4 0x00000000
R: EN_StackPush                  () push r4
R: EN_Constant                   (0x00000200) ld r4 0x00000200
R: EN_Constant                   (0x00000003) ld r5 0x00000003
R: EN_Add                        () add r4, r4, r5
R: EN_Identifier                 (cursorY) ld r5 [cursorY]
R: EN_Sub                        () sub r4, r4, r5
R: EN_StackPush                  () push r4
R: EN_Constant                   (0x00000180) ld r4 0x00000180
R: EN_StackPush                  () push r4
R: EN_Call                       (DrawRect) call DrawRect
R: EN_BeginCodeBlock             ()  
R: EN_Jump                       (exitif5) jmp exitif5
R: EN_Label                      (endif4) @label endif4
R: EN_Constant                   (0x00000001) ld r4 0x00000001
L: EN_Identifier                 (cursorY) lea r5 cursorY
R: EN_AssignmentExpression       () st [r5], r4
R: EN_Statement                  ()  
R: EN_BeginCodeBlock             ()  
R: EN_Label                      (exitif5) @label exitif5
R: EN_If                         ()  
R: EN_BeginCodeBlock             ()  
R: EN_FuncDecl                   ()  

------------Compiled Code-------------

@label test
ret 
ld r0 [height]
ld r1 [width]
ld r2 [posY]
ld r3 [posX]
@label DrawRect
ld r4 [posY]
lea r5 spanY
st [r5], r4
@label beginwhile2
ld r4 [spanY]
ld r5 [posY]
ld r6 [height]
add r5, r5, r6
cmp.l r4, r4, r5
jmpnz r4, endwhile3
ld r4 [posX]
lea r5 spanX
st [r5], r4
@label beginwhile0
ld r4 [spanX]
ld r5 [posX]
ld r6 [width]
add r5, r5, r6
cmp.l r4, r4, r5
jmpnz r4, endwhile1
ld r4 0x0000000c
lea r5 VRAM
lea r6 spanX
ld r7 0x00000140
lea r8 spanY
mul r7, r7, r8
add r6, r6, r7
add r5, r5, r6
st [r5], r4
ld r4 [spanX]
ld r5 0x00000001
add r4, r4, r5
lea r5 spanX
st [r5], r4
jmp beginwhile0
@label endwhile1
ld r4 [spanY]
ld r5 0x00000001
add r4, r4, r5
lea r5 spanY
st [r5], r4
jmp beginwhile2
@label endwhile3
@label main
ld r4 [cursorY]
ld r5 0x00000002
cmp.g r4, r4, r5
jmpnz r4, endif4
ld r4 0x00000000
push r4
ld r4 0x00000000
push r4
ld r4 0x00000200
ld r5 0x00000003
add r4, r4, r5
ld r5 [cursorY]
sub r4, r4, r5
push r4
ld r4 0x00000180
push r4
call DrawRect
jmp exitif5
@label endif4
ld r4 0x00000001
lea r5 cursorY
st [r5], r4
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
@dw 0x00000001
@dw 0x00000002
@dw 0x00000003
@dw 0x00000004
@label sprite
@length 32
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
@length 1
@dw 0x00000000
@label spanY
@length 1
@dw 0x00000000
