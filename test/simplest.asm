
------------Code----------------------
R: EN_FuncDecl                  (0) nop ,,,
R: .EN_Label                     (1) @label ,,,main
R: .EN_BeginCodeBlock            (1) pushcontext ,,,
R: ..EN_Statement                 (2) nop ,,,
R: ...EN_AssignmentExpression      (3) st ,,,
L: ....EN_PostfixArrayExpression    (4) add ,,,
L: .....EN_Identifier                (5) lea ,,,a
L: .....EN_Add                       (5) add ,,,
L: ......EN_PostfixArrayExpression    (6) add ,,,
L: .......EN_Identifier                (7) lea ,,,c
L: .......EN_Sub                       (7) sub ,,,
L: ........EN_Constant                  (8) ld ,,,0x00000004
L: ........EN_Identifier                (8) lea ,,,d
L: ......EN_Constant                  (6) ld ,,,0x00000017
R: ....EN_PostfixArrayExpression    (4) add ,,,
R: .....EN_Identifier                (5) lea ,,,b
R: .....EN_Constant                  (5) ld ,,,0x00000001
R: .EN_EndCodeBlock              (1) popcontext ,,,

------------Symbol table--------------
Function 'main', hash BC76E6BA
