
-------------Scope Depth--------------

R: EN_FuncDecl                  (0) 
R: .EN_Label                     (1) main
R: .EN_BeginCodeBlock            (1) 
R: ..EN_If                        (2) 
R: ...EN_LessEqual                 (3) 
R: ....EN_Identifier                (4) cursorY
R: ....EN_Mul                       (4) 
R: .....EN_Constant                  (5) 0x00000002
R: .....EN_Constant                  (5) 0x00000002
R: ...EN_JumpNZ                    (3) endif0
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
R: ...EN_Jump                      (3) exitif1
R: ...EN_Label                     (3) endif0
R: ...EN_BeginCodeBlock            (3) 
R: ....EN_Statement                 (4) 
R: .....EN_AssignmentExpression      (5) 
L: ......EN_Identifier                (6) cursorY
R: ......EN_Sub                       (6) 
R: .......EN_Constant                  (7) 0x00000002
R: .......EN_Constant                  (7) 0x00000001
R: ...EN_Label                     (3) exitif1

---------Register Assignment----------

@label main
ld r0 [cursorY]
ld r1 0x00000002
ld r2 0x00000002
mul r1, r2, r1
cmp.le r0, r1, r0
jmpnz r0, endif0
ld r0 0x00000180
push r0
ld r0 0x00000200
ld r1 0x00000003
add r0, r1, r0
ld r1 [cursorY]
sub r0, r1, r0
push r0
ld r0 0x00000000
push r0
ld r0 0x00000000
push r0
call DrawRect
jmp exitif1
@label endif0
lea r0 cursorY
ld r1 0x00000002
ld r2 0x00000001
sub r1, r2, r1
st [r0], r1, r0
@label exitif1

-------------Symbol Table-------------

Function 'main', hash BC76E6BA
