# Neko v3 asm output
# R15 == SP, R14 == FP
        lea r15 stack
        branch main
@LABEL program_finished
        jmp program_finished

@ORG 0x0010
@LABEL sprite
        @DW 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0xffff 0x0000 0x0000 0x0000 0x0000 0x0000 0x00ff 0xffff 0xff00 0xf69a 0x9a9a 0x9a9a 0x9a9a 0x9a9a 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5100 0xffff 0xff00 0x9a09 0x0909 0x0909 0x0909 0x0909 0x5151

# -------------------------- draw_sprite -------------------------- 
@LABEL draw_sprite
        push r5
        push r6
        push r14
        cp.w r14 r15
        cp.w r13 r1
        cp.w r6 r13
        cp.w r11 r13
@LABEL draw_sprite_for_start
        ld.w r13 0x0010
        cp.w r12 r1
        iadd r12 r13
        cp.w r13 r12
        cp.w r12 r6
        cmp r12 r13
        test less
        jmpif label
        ld.w r12 0x0
        jmp label1
@LABEL label
        ld.w r12 0x1
@LABEL label1
        cp.w r11 r12
        cmp r11 r11
        test zero
        jmpif draw_sprite_for_break
        cp.w r13 r0
        cp.w r5 r13
        cp.w r11 r13
@LABEL draw_sprite_for_start1
        ld.w r13 0x0010
        cp.w r12 r0
        iadd r12 r13
        cp.w r13 r12
        cp.w r12 r5
        cmp r12 r13
        test less
        jmpif label2
        ld.w r12 0x0
        jmp label3
@LABEL label2
        ld.w r12 0x1
@LABEL label3
        cp.w r11 r12
        cmp r11 r11
        test zero
        jmpif draw_sprite_for_break1
        cp.w r12 r5
        cp.w r12 r6
        ld.w r13 0xffff
        xor r12 r13
        ld.w r13 0x1
        iadd r12 r13
        cp.w r13 r12
        PIXEL r12 r13
@LABEL draw_sprite_for_continue1
        ld.w r13 0x0001
        cp.w r12 r5
        iadd r12 r13
        cp.w r13 r12
        cp.w r5 r13
        cp.w r11 r13
        jmp draw_sprite_for_start1
@LABEL draw_sprite_for_break1
@LABEL draw_sprite_for_continue
        ld.w r13 0x0001
        cp.w r12 r6
        iadd r12 r13
        cp.w r13 r12
        cp.w r6 r13
        cp.w r11 r13
        jmp draw_sprite_for_start
@LABEL draw_sprite_for_break
@LABEL draw_sprite_end
        cp.w r15 r14
        pop r14
        pop r6
        pop r5
        ret

# -------------------------- main -------------------------- 
@LABEL main
        push r14
        cp.w r14 r15
@LABEL main_while_continue
        ld.w r11 0x0001
        cmp r11 r11
        test zero
        jmpif main_while_break
        push r0
        push r1
        ld.w r0 0x0040
        ld.w r1 0x0010
        branch draw_sprite
        pop r1
        pop r0
        jmp main_while_continue
@LABEL main_while_break
@LABEL main_end
        cp.w r15 r14
        pop r14
        ret

@LABEL stack
