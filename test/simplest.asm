EN_Decl                      (0) nop 
.EN_Identifier                (1) ident cursorX
EN_Decl                      (0) nop 
.EN_Identifier                (1) ident cursorY
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) assign 
..EN_Identifier                (2) ident VRAM
..EN_Constant                  (2) const 0x80000000
EN_Decl                      (0) nop 
.EN_DeclArray                 (1) nop 
..EN_Identifier                (2) ident banana
..EN_Constant                  (2) const 0x00000010
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) bulkassign 
..EN_Identifier                (2) ident tree
..EN_Constant                  (2) const 4
..EN_ArrayWithDataJunction     (2) dataarray 
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000004
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000003
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000002
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000001
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) bulkassign 
..EN_Identifier                (2) ident sprite
..EN_Constant                  (2) const 0x00000005
..EN_ArrayWithDataJunction     (2) dataarray 
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0xffffffff
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0xffffffff
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0xffffffff
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0xffffffff
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0xffffffff
EN_FuncDecl                  (0) nop 
.EN_InputParam                (1) nop 
..EN_Identifier                (2) ident height
.EN_InputParam                (1) nop 
..EN_Identifier                (2) ident width
.EN_InputParam                (1) nop 
..EN_Identifier                (2) ident posY
.EN_InputParam                (1) nop 
..EN_Identifier                (2) ident posX
.EN_Identifier                (1) ident DrawRect
.EN_CodeBlock                 (1) pushcontext 
..EN_While                     (2) while 
...EN_LessThan                  (3) nop 
....EN_Identifier                (4) ident spanY
....EN_Add                       (4) add 
.....EN_Identifier                (5) ident posY
.....EN_Identifier                (5) ident height
...EN_CodeBlock                 (3) pushcontext 
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) assign 
......EN_Identifier                (6) ident spanY
......EN_Add                       (6) add 
.......EN_Identifier                (7) ident spanY
.......EN_Constant                  (7) const 0x00000001
....EN_While                     (4) while 
.....EN_LessThan                  (5) nop 
......EN_Identifier                (6) ident spanX
......EN_Add                       (6) add 
.......EN_Identifier                (7) ident posX
.......EN_Identifier                (7) ident width
.....EN_CodeBlock                 (5) pushcontext 
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) assign 
........EN_Identifier                (8) ident spanX
........EN_Add                       (8) add 
.........EN_Identifier                (9) ident spanX
.........EN_Constant                  (9) const 0x00000001
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) assign 
........EN_PostfixArrayExpression    (8) nop 
.........EN_Identifier                (9) ident VRAM
.........EN_Add                       (9) add 
..........EN_Identifier                (10) ident spanX
..........EN_Mul                       (10) mul 
...........EN_Constant                  (11) const 0x00000140
...........EN_Identifier                (11) ident spanY
........EN_Constant                  (8) const 0xff00ff00
.....EN_EndCodeBlock              (5) popcontext 
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) assign 
......EN_Identifier                (6) ident spanX
......EN_Identifier                (6) ident posX
...EN_EndCodeBlock              (3) popcontext 
..EN_Statement                 (2) nop 
...EN_AssignmentExpression      (3) assign 
....EN_Identifier                (4) ident spanY
....EN_Identifier                (4) ident posY
..EN_Decl                      (2) nop 
...EN_Identifier                (3) ident spanY
..EN_Decl                      (2) nop 
...EN_Identifier                (3) ident spanX
.EN_EndCodeBlock              (1) popcontext 
EN_FuncDecl                  (0) nop 
.EN_Identifier                (1) ident main
.EN_CodeBlock                 (1) pushcontext 
..EN_Call                      (2) nop 
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000180
...EN_Expression                (3) nop 
....EN_Sub                       (4) sub 
.....EN_Add                       (5) add 
......EN_Constant                  (6) const 0x00000200
......EN_Constant                  (6) const 0x00000003
.....EN_Identifier                (5) ident cursorY
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000000
...EN_Expression                (3) nop 
....EN_Constant                  (4) const 0x00000000
...EN_Identifier                (3) ident DrawRect
.EN_EndCodeBlock              (1) popcontext 
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
