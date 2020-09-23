
------------Code----------------------
EN_Decl                      (0) decl 
.EN_Identifier                (1) lea cursorX
EN_Decl                      (0) decl 
.EN_Identifier                (1) lea cursorY
EN_Decl                      (0) decl 
.EN_DeclInitJunction          (1) st 
..EN_Identifier                (2) lea VRAM
..EN_Constant                  (2) mov 0x80000000
EN_Decl                      (0) decl 
.EN_DeclArray                 (1) nop 
..EN_Identifier                (2) lea banana
..EN_Constant                  (2) dim 0x00000010
EN_Decl                      (0) decl 
.EN_DeclInitJunction          (1) bulkassign 
..EN_Identifier                (2) lea tree
..EN_Constant                  (2) dim 0x00000004
..EN_ArrayWithDataJunction     (2) dataarray 
...EN_Constant                  (3) mov 0x00000004
...EN_Constant                  (3) mov 0x00000003
...EN_Constant                  (3) mov 0x00000002
...EN_Constant                  (3) mov 0x00000001
EN_Decl                      (0) decl 
.EN_DeclInitJunction          (1) bulkassign 
..EN_Identifier                (2) lea sprite
..EN_Constant                  (2) dim 0x00000020
..EN_ArrayWithDataJunction     (2) dataarray 
...EN_Constant                  (3) mov 0xffedcafd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xff222ffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xf00ffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
...EN_Constant                  (3) mov 0xffffff01
...EN_Constant                  (3) mov 0xffffff00
...EN_Constant                  (3) mov 0xffffffff
...EN_Constant                  (3) mov 0xfffffffe
...EN_Constant                  (3) mov 0xfffffffd
...EN_Constant                  (3) mov 0xfffffffc
...EN_Constant                  (3) mov 0xfffffffb
...EN_Constant                  (3) mov 0xfffffffa
EN_FuncDecl                  (0) nop 
.EN_Label                     (1) @label test
.EN_BeginCodeBlock            (1) pushcontext 
..EN_Return                    (2) ret 
.EN_EndCodeBlock              (1) popcontext 
EN_FuncDecl                  (0) nop 
.EN_StackPop                  (1) nop 
..EN_Identifier                (2) lea height
.EN_StackPop                  (1) nop 
..EN_Identifier                (2) lea width
.EN_StackPop                  (1) nop 
..EN_Identifier                (2) lea posY
.EN_StackPop                  (1) nop 
..EN_Identifier                (2) lea posX
.EN_Label                     (1) @label DrawRect
.EN_BeginCodeBlock            (1) pushcontext 
..EN_While                     (2) while 
...EN_Label                     (3) @label beginwhile2
...EN_LessThan                  (3) cmp.l 
....EN_Identifier                (4) lea spanY
....EN_Add                       (4) add 
.....EN_Identifier                (5) lea posY
.....EN_Identifier                (5) lea height
...EN_JumpNZ                    (3) jmpnz endwhile3
...EN_BeginCodeBlock            (3) pushcontext 
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) st 
......EN_Identifier                (6) lea spanY
......EN_Add                       (6) add 
.......EN_Identifier                (7) lea spanY
.......EN_Constant                  (7) mov 0x00000001
....EN_While                     (4) while 
.....EN_Label                     (5) @label beginwhile0
.....EN_LessThan                  (5) cmp.l 
......EN_Identifier                (6) lea spanX
......EN_Add                       (6) add 
.......EN_Identifier                (7) lea posX
.......EN_Identifier                (7) lea width
.....EN_JumpNZ                    (5) jmpnz endwhile1
.....EN_BeginCodeBlock            (5) pushcontext 
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) st 
........EN_Identifier                (8) lea spanX
........EN_Add                       (8) add 
.........EN_Identifier                (9) lea spanX
.........EN_Constant                  (9) mov 0x00000001
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) st 
........EN_PostfixArrayExpression    (8) add 
.........EN_Identifier                (9) lea VRAM
.........EN_Add                       (9) add 
..........EN_Identifier                (10) lea spanX
..........EN_Mul                       (10) mul 
...........EN_Constant                  (11) mov 0x00000140
...........EN_Identifier                (11) lea spanY
........EN_PostfixArrayExpression    (8) add 
.........EN_Identifier                (9) lea sprite
.........EN_Add                       (9) add 
..........EN_Mod                       (10) mod 
...........EN_Constant                  (11) mov 0x00000004
...........EN_Identifier                (11) lea spanX
..........EN_Mul                       (10) mul 
...........EN_Constant                  (11) mov 0x00000004
...........EN_Mod                       (11) mod 
............EN_Constant                  (12) mov 0x00000008
............EN_Identifier                (12) lea spanY
.....EN_EndCodeBlock              (5) popcontext 
.....EN_Jump                      (5) jmp beginwhile0
.....EN_Label                     (5) @label endwhile1
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) st 
......EN_Identifier                (6) lea spanX
......EN_Identifier                (6) lea posX
...EN_EndCodeBlock              (3) popcontext 
...EN_Jump                      (3) jmp beginwhile2
...EN_Label                     (3) @label endwhile3
..EN_Statement                 (2) nop 
...EN_AssignmentExpression      (3) st 
....EN_Identifier                (4) lea spanY
....EN_Identifier                (4) lea posY
..EN_Decl                      (2) decl 
...EN_Identifier                (3) lea spanY
..EN_Decl                      (2) decl 
...EN_Identifier                (3) lea spanX
.EN_EndCodeBlock              (1) popcontext 
EN_FuncDecl                  (0) nop 
.EN_Label                     (1) @label main
.EN_BeginCodeBlock            (1) pushcontext 
..EN_If                        (2) if 
...EN_GreaterThan               (3) cmp.g 
....EN_Identifier                (4) lea cursorY
....EN_Constant                  (4) mov 0x00000002
...EN_JumpNZ                    (3) jmpnz endif4
...EN_BeginCodeBlock            (3) pushcontext 
....EN_Call                      (4) call (paramcount: 4)
.....EN_StackPush                 (5) push 
......EN_Constant                  (6) mov 0x00000180
.....EN_StackPush                 (5) push 
......EN_Sub                       (6) sub 
.......EN_Add                       (7) add 
........EN_Constant                  (8) mov 0x00000200
........EN_Constant                  (8) mov 0x00000003
.......EN_Identifier                (7) lea cursorY
.....EN_StackPush                 (5) push 
......EN_Constant                  (6) mov 0x00000000
.....EN_StackPush                 (5) push 
......EN_Constant                  (6) mov 0x00000000
.....EN_Identifier                (5) lea DrawRect
...EN_EndCodeBlock              (3) popcontext 
...EN_Jump                      (3) jmp exitif5
...EN_Label                     (3) @label endif4
...EN_BeginCodeBlock            (3) pushcontext 
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) st 
......EN_Identifier                (6) lea cursorY
......EN_Constant                  (6) mov 0x00000001
...EN_EndCodeBlock              (3) popcontext 
...EN_Label                     (3) @label exitif5
.EN_EndCodeBlock              (1) popcontext 

------------Code Reverse--------------
lea cursorX
decl 
lea cursorY
decl 
lea VRAM
mov 0x80000000
st 
decl 
lea banana
dim 0x00000010
nop 
decl 
lea tree
dim 0x00000004
mov 0x00000004
mov 0x00000003
mov 0x00000002
mov 0x00000001
dataarray 
bulkassign 
decl 
lea sprite
dim 0x00000020
mov 0xffedcafd
mov 0xfffffffc
mov 0xfffffffb
mov 0xfffffffa
mov 0xfffffffd
mov 0xfffffffc
mov 0xfffffffb
mov 0xfffffffa
mov 0xfffffffd
mov 0xff222ffc
mov 0xfffffffb
mov 0xfffffffa
mov 0xfffffffd
mov 0xfffffffc
mov 0xf00ffffb
mov 0xfffffffa
mov 0xfffffffd
mov 0xfffffffc
mov 0xfffffffb
mov 0xfffffffa
mov 0xfffffffd
mov 0xfffffffc
mov 0xfffffffb
mov 0xfffffffa
mov 0xffffff01
mov 0xffffff00
mov 0xffffffff
mov 0xfffffffe
mov 0xfffffffd
mov 0xfffffffc
mov 0xfffffffb
mov 0xfffffffa
dataarray 
bulkassign 
decl 
@label test
ret 
pushcontext 
popcontext 
nop 
lea height
nop 
lea width
nop 
lea posY
nop 
lea posX
nop 
@label DrawRect
@label beginwhile2
lea spanY
lea posY
lea height
add 
cmp.l 
jmpnz endwhile3
lea spanY
lea spanY
mov 0x00000001
add 
st 
nop 
@label beginwhile0
lea spanX
lea posX
lea width
add 
cmp.l 
jmpnz endwhile1
lea spanX
lea spanX
mov 0x00000001
add 
st 
nop 
lea VRAM
lea spanX
mov 0x00000140
lea spanY
mul 
add 
add 
lea sprite
mov 0x00000004
lea spanX
mod 
mov 0x00000004
mov 0x00000008
lea spanY
mod 
mul 
add 
add 
st 
nop 
pushcontext 
popcontext 
jmp beginwhile0
@label endwhile1
while 
lea spanX
lea posX
st 
nop 
pushcontext 
popcontext 
jmp beginwhile2
@label endwhile3
while 
lea spanY
lea posY
st 
nop 
lea spanY
decl 
lea spanX
decl 
pushcontext 
popcontext 
nop 
@label main
lea cursorY
mov 0x00000002
cmp.g 
jmpnz endif4
mov 0x00000180
push 
mov 0x00000200
mov 0x00000003
add 
lea cursorY
sub 
push 
mov 0x00000000
push 
mov 0x00000000
push 
lea DrawRect
call (paramcount: 4)
pushcontext 
popcontext 
jmp exitif5
@label endif4
lea cursorY
mov 0x00000001
st 
nop 
pushcontext 
popcontext 
@label exitif5
if 
pushcontext 
popcontext 
nop 

------------Symbol table--------------
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
