EN_Decl                      (0) nop 
.EN_Identifier                (1) ident cursorX
EN_Decl                      (0) nop 
.EN_Identifier                (1) ident cursorY
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) nop 
..EN_Identifier                (2) ident VRAM
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Constant                  (4) const 0x80000000
EN_Decl                      (0) nop 
.EN_DeclArray                 (1) nop 
..EN_Identifier                (2) ident banana
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Constant                  (4) const 0x00000010
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) nop 
..EN_Identifier                (2) ident tree
..EN_Constant                  (2) nop 4
..EN_ArrayWithDataJunction     (2) nop 
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000004
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000003
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000002
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000001
EN_Decl                      (0) nop 
.EN_DeclInitJunction          (1) nop 
..EN_Identifier                (2) ident sprite
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Constant                  (4) const 0x00000005
..EN_ArrayWithDataJunction     (2) nop 
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0xffffffff
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0xffffffff
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0xffffffff
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0xffffffff
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0xffffffff
EN_FuncDecl                  (0) nop 
.EN_InputParam                (1) nop 
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Identifier                (4) ident height
.EN_InputParam                (1) nop 
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Identifier                (4) ident width
.EN_InputParam                (1) nop 
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Identifier                (4) ident posY
.EN_InputParam                (1) nop 
..EN_ConditionalExpr           (2) nop 
...EN_PrimaryExpression         (3) nop 
....EN_Identifier                (4) ident posX
.EN_Identifier                (1) ident DrawRect
.EN_CodeBlock                 (1) nop 
..EN_While                     (2) nop 
...EN_ConditionalExpr           (3) nop 
....EN_LessThan                  (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Identifier                (6) ident spanY
.....EN_Add                       (5) add 
......EN_PrimaryExpression         (6) nop 
.......EN_Identifier                (7) ident posY
......EN_PrimaryExpression         (6) nop 
.......EN_Identifier                (7) ident height
...EN_CodeBlock                 (3) nop 
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) assign 
......EN_PrimaryExpression         (6) nop 
.......EN_Identifier                (7) ident spanY
......EN_ConditionalExpr           (6) nop 
.......EN_Add                       (7) add 
........EN_PrimaryExpression         (8) nop 
.........EN_Identifier                (9) ident spanY
........EN_PrimaryExpression         (8) nop 
.........EN_Constant                  (9) const 0x00000001
....EN_While                     (4) nop 
.....EN_ConditionalExpr           (5) nop 
......EN_LessThan                  (6) nop 
.......EN_PrimaryExpression         (7) nop 
........EN_Identifier                (8) ident spanX
.......EN_Add                       (7) add 
........EN_PrimaryExpression         (8) nop 
.........EN_Identifier                (9) ident posX
........EN_PrimaryExpression         (8) nop 
.........EN_Identifier                (9) ident width
.....EN_CodeBlock                 (5) nop 
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) assign 
........EN_PrimaryExpression         (8) nop 
.........EN_Identifier                (9) ident spanX
........EN_ConditionalExpr           (8) nop 
.........EN_Add                       (9) add 
..........EN_PrimaryExpression         (10) nop 
...........EN_Identifier                (11) ident spanX
..........EN_PrimaryExpression         (10) nop 
...........EN_Constant                  (11) const 0x00000001
......EN_Statement                 (6) nop 
.......EN_AssignmentExpression      (7) assign 
........EN_PostfixArrayExpression    (8) nop 
.........EN_PrimaryExpression         (9) nop 
..........EN_Identifier                (10) ident VRAM
.........EN_ConditionalExpr           (9) nop 
..........EN_Add                       (10) add 
...........EN_PrimaryExpression         (11) nop 
............EN_Identifier                (12) ident spanX
...........EN_Mul                       (11) mul 
............EN_PrimaryExpression         (12) nop 
.............EN_Constant                  (13) const 0x00000140
............EN_PrimaryExpression         (12) nop 
.............EN_Identifier                (13) ident spanY
........EN_ConditionalExpr           (8) nop 
.........EN_PrimaryExpression         (9) nop 
..........EN_Constant                  (10) const 0xff00ff00
....EN_Statement                 (4) nop 
.....EN_AssignmentExpression      (5) assign 
......EN_PrimaryExpression         (6) nop 
.......EN_Identifier                (7) ident spanX
......EN_ConditionalExpr           (6) nop 
.......EN_PrimaryExpression         (7) nop 
........EN_Identifier                (8) ident posX
..EN_Statement                 (2) nop 
...EN_AssignmentExpression      (3) assign 
....EN_PrimaryExpression         (4) nop 
.....EN_Identifier                (5) ident spanY
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Identifier                (6) ident posY
..EN_Decl                      (2) nop 
...EN_Identifier                (3) ident spanY
..EN_Decl                      (2) nop 
...EN_Identifier                (3) ident spanX
EN_FuncDecl                  (0) nop 
.EN_Identifier                (1) ident main
.EN_CodeBlock                 (1) nop 
..EN_Call                      (2) nop 
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000180
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_Sub                       (5) sub 
......EN_Add                       (6) add 
.......EN_PrimaryExpression         (7) nop 
........EN_Constant                  (8) const 0x00000200
.......EN_PrimaryExpression         (7) nop 
........EN_Constant                  (8) const 0x00000003
......EN_PrimaryExpression         (6) nop 
.......EN_Identifier                (7) ident cursorY
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000000
...EN_Expression                (3) nop 
....EN_ConditionalExpr           (4) nop 
.....EN_PrimaryExpression         (5) nop 
......EN_Constant                  (6) const 0x00000000
...EN_Identifier                (3) ident DrawRect
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
