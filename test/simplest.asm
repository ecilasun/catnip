# Neko v3 asm output
# R15 == SP, R14 == FP
        lea SP stack
        branch main
@LABEL program_finished:
        jmp program_finished
@LABEL simple_function:
        push E
        push FP
        MOV FP SP
        MOV N A
        MOV M A
        imul M N
        MOV E M
        ld.w N 0x0008
        MOV M E
        cmp M N
        test less equal
        jmpif label
        MOVI M 0x0
        jmp label1
@LABEL label:
        MOVI M 0x1
@LABEL label1:
        MOV L M
        cmp L L
        test zero
        jmpif simple_function_if_false
        ld.w L 0x0000
        jmp simple_function_end
        jmp simple_function_if_end
@LABEL simple_function_if_false:
@LABEL simple_function_if_end:
        ld.w L 0x0001
        jmp simple_function_end
@LABEL simple_function_end:
        MOV SP FP
        pop FP
        pop E
        RET
@LABEL main:
        push E
        push F
        push G
        push FP
        MOV FP SP
        ld.w E 0x000e
        push A
        MOV A E
        branch simple_function
        pop A
        MOV F L
        push A
        ld.w N 0x0002
        MOV M E
        imul M N
        MOV A M
        branch simple_function
        pop A
        MOV G L
        MOV N G
        MOV M F
        iadd M N
        MOV N M
        MOV F N
        MOV L N
@LABEL main_end:
        MOV SP FP
        pop FP
        pop G
        pop F
        pop E
        RET
@LABEL stack:
