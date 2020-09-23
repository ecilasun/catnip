EN_Decl                      (0) 
.EN_Identifier                (1) cursorX
EN_Decl                      (0) 
.EN_Identifier                (1) cursorY
EN_Decl                      (0) 
.EN_DeclInitJunction          (1) 
..EN_Identifier                (2) VRAM
..EN_ConditionalExpr           (2) 
...EN_Constant                  (3) 0x80000000
EN_Decl                      (0) 
.EN_DeclArray                 (1) 
..EN_Identifier                (2) banana
..EN_ConditionalExpr           (2) 
...EN_Constant                  (3) 0x00000010
EN_Decl                      (0) 
.EN_DeclInitJunction          (1) 
..EN_Identifier                (2) tree
..EN_Constant                  (2) 4
..EN_ArrayWithDataJunction     (2) 
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000004
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000003
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000002
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000001
EN_Decl                      (0) 
.EN_DeclInitJunction          (1) 
..EN_Identifier                (2) sprite
..EN_ConditionalExpr           (2) 
...EN_Constant                  (3) 0x00000005
..EN_ArrayWithDataJunction     (2) 
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0xffffffff
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0xffffffff
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0xffffffff
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0xffffffff
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0xffffffff
EN_FuncDecl                  (0) 
.EN_InputParam                (1) 
..EN_ConditionalExpr           (2) 
...EN_Identifier                (3) height
.EN_InputParam                (1) 
..EN_ConditionalExpr           (2) 
...EN_Identifier                (3) width
.EN_InputParam                (1) 
..EN_ConditionalExpr           (2) 
...EN_Identifier                (3) posY
.EN_InputParam                (1) 
..EN_ConditionalExpr           (2) 
...EN_Identifier                (3) posX
.EN_Identifier                (1) DrawRect
.EN_CodeBlock                 (1) 
..EN_While                     (2) 
...EN_ConditionalExpr           (3) 
....EN_LessThan                  (4) 
.....EN_Identifier                (5) spanY
.....EN_Add                       (5) 
......EN_Identifier                (6) posY
......EN_Identifier                (6) height
...EN_CodeBlock                 (3) 
....EN_Statement                 (4) 
.....EN_AssignmentExpression      (5) 
......EN_Identifier                (6) spanY
......EN_ConditionalExpr           (6) 
.......EN_Add                       (7) 
........EN_Identifier                (8) spanY
........EN_Constant                  (8) 0x00000001
....EN_While                     (4) 
.....EN_ConditionalExpr           (5) 
......EN_LessThan                  (6) 
.......EN_Identifier                (7) spanX
.......EN_Add                       (7) 
........EN_Identifier                (8) posX
........EN_Identifier                (8) width
.....EN_CodeBlock                 (5) 
......EN_Statement                 (6) 
.......EN_AssignmentExpression      (7) 
........EN_Identifier                (8) spanX
........EN_ConditionalExpr           (8) 
.........EN_Add                       (9) 
..........EN_Identifier                (10) spanX
..........EN_Constant                  (10) 0x00000001
......EN_Statement                 (6) 
.......EN_AssignmentExpression      (7) 
........EN_PostfixArrayExpression    (8) 
.........EN_Identifier                (9) VRAM
.........EN_ConditionalExpr           (9) 
..........EN_Add                       (10) 
...........EN_Identifier                (11) spanX
...........EN_Mul                       (11) 
............EN_Constant                  (12) 0x00000140
............EN_Identifier                (12) spanY
........EN_ConditionalExpr           (8) 
.........EN_Constant                  (9) 0xff00ff00
....EN_Statement                 (4) 
.....EN_AssignmentExpression      (5) 
......EN_Identifier                (6) spanX
......EN_ConditionalExpr           (6) 
.......EN_Identifier                (7) posX
..EN_Statement                 (2) 
...EN_AssignmentExpression      (3) 
....EN_Identifier                (4) spanY
....EN_ConditionalExpr           (4) 
.....EN_Identifier                (5) posY
..EN_Decl                      (2) 
...EN_Identifier                (3) spanY
..EN_Decl                      (2) 
...EN_Identifier                (3) spanX
EN_FuncDecl                  (0) 
.EN_Identifier                (1) main
.EN_CodeBlock                 (1) 
..EN_Call                      (2) 
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000180
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Sub                       (5) 
......EN_Add                       (6) 
.......EN_Constant                  (7) 0x00000200
.......EN_Constant                  (7) 0x00000003
......EN_Identifier                (6) cursorY
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000000
...EN_Expression                (3) 
....EN_ConditionalExpr           (4) 
.....EN_Constant                  (5) 0x00000000
...EN_Identifier                (3) DrawRect
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
