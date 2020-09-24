
-------------Scope Depth--------------

R: EN_FuncDecl                  (0) 
R: .EN_Label                     (1) main
R: .EN_BeginCodeBlock            (1) 
R: ..EN_Statement                 (2) 
R: ...EN_AssignmentExpression      (3) 
L: ....EN_Identifier                (4) a
R: ....EN_Add                       (4) 
R: .....EN_Constant                  (5) 0x00000001
R: .....EN_Mul                       (5) 
R: ......EN_Identifier                (6) a
R: ......EN_Constant                  (6) 0x00000003
R: .EN_EndCodeBlock              (1) 

---------Register Assignment----------

@label
lea r0 a
ld r1 0x00000001
ld r2 [a]
ld r3 0x00000003
mul r2, r3, r2
add r1, r2, r1
st [r0], r1, r0
nop
pushcontext
popcontext
nop

-------------Symbol Table-------------

Function 'main', hash BC76E6BA
