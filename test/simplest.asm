# Neko v3 asm output
# R15 == SP, R14 == FP
        lea r15 stack
        branch main
@LABEL program_finished
        jmp program_finished

sprite:
        0x0010
        0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0x0000 0x0000 0x0000 0x0000 0x0000 0x00ff 0xffff 0xff00 0xf69a 0x9a9a 0x9a9a 0x9a9a 0x9a9a 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5151
draw_sprite:
        PUSH E
        PUSH F
        PUSH FP
        MOV FP SP
        MOV N B
        MOV F N
        PUSH N
        POP L
draw_sprite_for_start:
        MOVI N 0x0010
        MOV M B
        ADD M N
        PUSH M
        POP N
        MOV M F
        CMP M N
        JB label
        MOVI M 0x0
        JMPI label1
label:
        MOVI M 0x1
label1:
        PUSH M
        POP L
        TST L L
        JEQ draw_sprite_for_break
        MOV N A
        MOV E N
        PUSH N
        POP L
draw_sprite_for_start1:
        MOVI N 0x0010
        MOV M A
        ADD M N
        PUSH M
        POP N
        MOV M E
        CMP M N
        JB label2
        MOVI M 0x0
        JMPI label3
label2:
        MOVI M 0x1
label3:
        PUSH M
        POP L
        TST L L
        JEQ draw_sprite_for_break1
        MOV M E
        MOV N F
        PIXEL M N
draw_sprite_for_continue1:
        MOVI N 0x0001
        MOV M E
        ADD M N
        PUSH M
        POP N
        MOV E N
        PUSH N
        POP L
        JMPI draw_sprite_for_start1
draw_sprite_for_break1:
draw_sprite_for_continue:
        MOVI N 0x0001
        MOV M F
        ADD M N
        PUSH M
        POP N
        MOV F N
        PUSH N
        POP L
        JMPI draw_sprite_for_start
draw_sprite_for_break:
draw_sprite_end:
        MOV SP FP
        POP FP
        POP F
        POP E
        RET
main:
        PUSH FP
        MOV FP SP
main_while_continue:
        MOVI L 0x0001
        TST L L
        JEQ main_while_break
        PUSH A
        PUSH B
        MOVI A 0x0040
        MOVI B 0x0010
        CALL draw_sprite
        POP B
        POP A
        JMPI main_while_continue
main_while_break:
main_end:
        MOV SP FP
        POP FP
        RET

@LABEL stack
